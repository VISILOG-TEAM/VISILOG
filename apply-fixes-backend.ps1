# VisiLog backend - CSV import accepts real-world staff files
# Run from the repository root.
$ErrorActionPreference = 'Stop'

$content = @'
package com.visilog.api.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

// Only name and email are mandatory. employeeCode is generated when
// blank and role defaults to EMPLOYEE (both in EmployeeService) -- a
// staff list exported from an HR or payroll system carries neither of
// VisiLog's own columns, and demanding them here rejected entire files
// at the door, before any of the friendlier handling downstream could
// run.
public record EmployeeRequest(
        String employeeCode,
        @NotBlank(message = "is required") String name,
        String department,
        String phone,
        @NotBlank(message = "is required") @Email(message = "must be a valid email") String email,
        String role // "employee" | "receptionist" | "manager"; defaults to employee
) {
}

'@
$path = Join-Path (Get-Location) 'server\src\main\java\com\visilog\api\dto\EmployeeRequest.java'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/main/java/com/visilog/api/dto/EmployeeRequest.java'

$content = @'
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
// against -- adding someone here with role=RECEPTIONIST/MANAGER/EMPLOYEE
// is what lets them get that role automatically when they sign up with
// a matching email, instead of the old free role-picker.
//
// Note: editing an Employee's role here does NOT retroactively change
// any AppUser who already signed up -- role is fixed at signup time by
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
        // A blank staff ID means the row came from a CSV that didn't
        // carry one; generate it rather than refusing the row.
        String code = req.employeeCode() == null || req.employeeCode().isBlank()
                ? generateEmployeeCode(organizationId)
                : req.employeeCode().trim();
        if (employeeRepository.existsByOrganizationIdAndEmployeeCodeIgnoreCase(organizationId, code)) {
            throw ApiException.conflict("An employee with that code already exists.");
        }
        // The seat cap is deliberately the LAST check: it's the only
        // reason a well-formed row should ever be turned away, and the
        // message needs to be the one the admin sees.
        checkSeatCap(organizationId);
        Employee e = new Employee();
        e.setOrganizationId(organizationId);
        applyRequest(e, req);
        e.setEmployeeCode(code);
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

    // CSV bulk import from Company Setup -- succeeds row by row rather
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

    // Only rejects a row the app genuinely cannot use. A name identifies
    // the person and an email is what AuthService.signup matches against
    // to hand out their role -- without those two the row is worthless.
    //
    // Everything else is filled in rather than refused. A staff ID gets
    // generated (see applyRequest) and a missing role defaults to
    // EMPLOYEE, because a spreadsheet exported from a payroll or HR
    // system won't have VisiLog's own columns in it, and rejecting
    // 1,668 perfectly good rows over a column the file was never going
    // to have is not a validation rule -- it's a broken importer.
    private void validateRow(EmployeeRequest req) {
        if (req.name() == null || req.name().isBlank()) {
            throw ApiException.badRequest("Name is required.");
        }
        if (req.email() == null || !req.email().contains("@")) {
            throw ApiException.badRequest("A valid email is required.");
        }
    }

    // "<ORGCODE>-0001"-style, counting up from however many staff the
    // org already has, and retried on the (rare) clash with a code that
    // came from an imported file.
    private String generateEmployeeCode(UUID organizationId) {
        long existing = employeeRepository.countByOrganizationId(organizationId);
        for (int attempt = 0; attempt < 10000; attempt++) {
            String candidate = String.format("EMP-%04d", existing + 1 + attempt);
            if (!employeeRepository.existsByOrganizationIdAndEmployeeCodeIgnoreCase(
                    organizationId, candidate)) {
                return candidate;
            }
        }
        throw ApiException.badRequest("Could not generate a staff ID for this row.");
    }

    @Transactional
    public void delete(UUID organizationId, UUID employeeId) {
        Employee e = employeeRepository.findByOrganizationIdAndId(organizationId, employeeId)
                .orElseThrow(() -> ApiException.notFound("Employee not found."));
        employeeRepository.delete(e);
    }

    // See ClockRecordService.checkDeviceBinding -- clears the link so
    // the next clock-in from any device re-binds fresh.
    @Transactional
    public EmployeeDto resetDevice(UUID organizationId, UUID employeeId) {
        Employee e = employeeRepository.findByOrganizationIdAndId(organizationId, employeeId)
                .orElseThrow(() -> ApiException.notFound("Employee not found."));
        e.setBoundDeviceId(null);
        return EmployeeDto.from(employeeRepository.save(e));
    }

    // Callers that can generate a code (see create) overwrite it after
    // this; the null-guard is for the ones that can't reach here with a
    // blank one anyway.
    private void applyRequest(Employee e, EmployeeRequest req) {
        if (req.employeeCode() != null && !req.employeeCode().isBlank()) {
            e.setEmployeeCode(req.employeeCode().trim());
        }
        e.setName(req.name().trim());
        e.setDepartment(req.department());
        e.setPhone(req.phone());
        e.setEmail(req.email().trim().toLowerCase(Locale.ROOT));
        e.setRole(parseRole(req.role()));
    }

    // A missing or unrecognised role becomes EMPLOYEE rather than an
    // error: a roster exported from an HR system has job titles in that
    // column, if it has the column at all, and "Senior Analyst" should
    // land someone in the app as an ordinary employee rather than
    // rejecting their row. Elevated roles are set deliberately by the
    // Administrator in Company Setup, never inferred from a spreadsheet.
    private Role parseRole(String raw) {
        if (raw == null || raw.isBlank()) {
            return Role.EMPLOYEE;
        }
        try {
            return Role.valueOf(raw.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException ex) {
            return Role.EMPLOYEE;
        }
    }
}

'@
$path = Join-Path (Get-Location) 'server\src\main\java\com\visilog\api\service\EmployeeService.java'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/main/java/com/visilog/api/service/EmployeeService.java'

Write-Host ''
Write-Host 'Done. 2 files written.'
Write-Host 'Next: run   cd server; .\mvnw -q test'
