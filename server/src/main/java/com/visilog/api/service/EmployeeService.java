package com.visilog.api.service;

import com.visilog.api.dto.BulkImportResult;
import com.visilog.api.dto.EmployeeDto;
import com.visilog.api.dto.EmployeeRequest;
import com.visilog.api.entity.Employee;
import com.visilog.api.entity.OrgBilling;
import com.visilog.api.entity.Plan;
import com.visilog.api.entity.Role;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.EmployeeRepository;
import com.visilog.api.repository.OrgBillingRepository;
import com.visilog.api.repository.PlanRepository;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Company Setup > staff roster. This is what AuthService.signup checks
// against â€” adding someone here with role=RECEPTIONIST/MANAGER/EMPLOYEE
// is what lets them get that role automatically when they sign up with
// a matching email, instead of the old free role-picker.
//
// Note: editing an Employee's role here does NOT retroactively change
// any AppUser who already signed up â€” role is fixed at signup time by
// design (see AuthService). This only affects people who sign up after
// the change.
@Service
public class EmployeeService {

    private final EmployeeRepository employeeRepository;
    private final OrgBillingRepository orgBillingRepository;
    private final PlanRepository planRepository;
    private final PlanFeatureService planFeatureService;

    public EmployeeService(
            EmployeeRepository employeeRepository, OrgBillingRepository orgBillingRepository,
            PlanRepository planRepository, PlanFeatureService planFeatureService) {
        this.employeeRepository = employeeRepository;
        this.orgBillingRepository = orgBillingRepository;
        this.planRepository = planRepository;
        this.planFeatureService = planFeatureService;
    }

    public List<EmployeeDto> list(UUID organizationId) {
        return employeeRepository.findByOrganizationId(organizationId).stream()
                .map(EmployeeDto::from)
                .toList();
    }

    @Transactional
    public EmployeeDto create(UUID organizationId, EmployeeRequest req) {
        if (employeeRepository.existsByOrganizationIdAndEmployeeCodeIgnoreCase(organizationId, req.employeeCode())) {
            throw ApiException.conflict("An employee with that code already exists.");
        }
        checkSeatCap(organizationId);
        Employee e = new Employee();
        e.setOrganizationId(organizationId);
        applyRequest(e, req);
        return EmployeeDto.from(employeeRepository.save(e));
    }

    // Real cost to staying on a lower tier: once the roster hits the
    // plan's seat_limit, adding another staff member is blocked until
    // the org upgrades (see BillingService.changePlan) or removes
    // someone. Counts actual Employee rows rather than trusting
    // OrgBilling.seatsUsed, which nothing else keeps in sync.
    private void checkSeatCap(UUID organizationId) {
        OrgBilling billing = orgBillingRepository.findByOrganizationId(organizationId).orElse(null);
        if (billing == null) {
            return;
        }
        Plan plan = planRepository.findById(billing.getPlanId()).orElse(null);
        if (plan == null) {
            return;
        }
        long current = employeeRepository.countByOrganizationId(organizationId);
        if (current >= plan.getSeatLimit()) {
            throw ApiException.conflict(
                    "You've reached the " + plan.getSeatLimit() + "-seat limit on the " + plan.getName()
                            + " plan. Upgrade in Billing to add more staff.");
        }
    }

    @Transactional
    public EmployeeDto update(UUID organizationId, UUID employeeId, EmployeeRequest req) {
        Employee e = employeeRepository.findByOrganizationIdAndId(organizationId, employeeId)
                .orElseThrow(() -> ApiException.notFound("Employee not found."));
        applyRequest(e, req);
        return EmployeeDto.from(employeeRepository.save(e));
    }

    // CSV bulk import from Company Setup â€” succeeds row by row rather
    // than all-or-nothing, so a duplicate code or a missing email on
    // one row doesn't block the rest of a large roster upload. Not
    // @Transactional itself, deliberately: each employeeRepository.save()
    // (inside create()) commits on its own, so a later row failing
    // can't undo the ones that already succeeded.
    public BulkImportResult<EmployeeDto> bulkCreate(UUID organizationId, List<EmployeeRequest> rows) {
        planFeatureService.requirePlan(organizationId, "pro", "CSV import");
        List<EmployeeDto> created = new ArrayList<>();
        List<BulkImportResult.RowError> errors = new ArrayList<>();
        for (int i = 0; i < rows.size(); i++) {
            int rowNumber = i + 1;
            try {
                validateRow(rows.get(i));
                created.add(create(organizationId, rows.get(i)));
            } catch (ApiException ex) {
                errors.add(new BulkImportResult.RowError(rowNumber, ex.getMessage()));
            }
        }
        return new BulkImportResult<>(created, errors);
    }

    private void validateRow(EmployeeRequest req) {
        if (req.employeeCode() == null || req.employeeCode().isBlank()) {
            throw ApiException.badRequest("Employee code is required.");
        }
        if (req.name() == null || req.name().isBlank()) {
            throw ApiException.badRequest("Name is required.");
        }
        if (req.email() == null || !req.email().contains("@")) {
            throw ApiException.badRequest("A valid email is required.");
        }
        if (req.role() == null || req.role().isBlank()) {
            throw ApiException.badRequest("Role is required.");
        }
    }

    @Transactional
    public void delete(UUID organizationId, UUID employeeId) {
        Employee e = employeeRepository.findByOrganizationIdAndId(organizationId, employeeId)
                .orElseThrow(() -> ApiException.notFound("Employee not found."));
        employeeRepository.delete(e);
    }

    private void applyRequest(Employee e, EmployeeRequest req) {
        e.setEmployeeCode(req.employeeCode().trim());
        e.setName(req.name().trim());
        e.setDepartment(req.department());
        e.setPhone(req.phone());
        e.setEmail(req.email().trim().toLowerCase(Locale.ROOT));
        e.setRole(parseRole(req.role()));
    }

    private Role parseRole(String raw) {
        try {
            return Role.valueOf(raw.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException ex) {
            throw ApiException.badRequest("role must be one of: employee, receptionist, manager, visitor.");
        }
    }
}