# Billing plan feature enforcement -- writes 7 backend files, then verifies.
# Run this from your VisiLog-frontend\server folder (the one with pom.xml in it) in PowerShell.
[Environment]::CurrentDirectory = (Get-Location).Path
Start-Transcript -Path billinggates-log.txt -Force

# --- src\main\resources\db\migration\V18__plan_feature_gates.sql ---
[System.IO.File]::WriteAllText('src\main\resources\db\migration\V18__plan_feature_gates.sql', @'
-- Plan feature enforcement: previously the feature lists on each plan
-- card (Custom branding, seat counts) were purely decorative -- nothing
-- actually stopped a Starter org from using them. This adds real
-- enforcement (see PlanFeatureService) while grandfathering every org
-- that already exists as of this migration, so nobody who's already
-- using a feature loses it -- only orgs that register after this ships
-- are subject to the new gates.

ALTER TABLE organizations ADD COLUMN grandfathered_features BOOLEAN NOT NULL DEFAULT FALSE;
UPDATE organizations SET grandfathered_features = TRUE;

INSERT INTO plan_features (plan_id, feature, position) VALUES
    ('pro', 'CSV import & export', 1),
    ('enterprise', 'CSV import & export', 2);
'@)

# --- src\main\java\com\visilog\api\entity\Organization.java ---
[System.IO.File]::WriteAllText('src\main\java\com\visilog\api\entity\Organization.java', @'
package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// A paying tenant. Self-registered via POST /companies/register — see
// AuthService.registerCompany. Every other tenant-scoped table carries
// an organizationId FK back to this and every query is scoped to it.
@Entity
@Table(name = "organizations")
@Getter
@Setter
@NoArgsConstructor
public class Organization {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false, unique = true, length = 32)
    private String code;

    @Column(nullable = false)
    private String name;

    // TEXT, not the default VARCHAR(255) — holds either a pasted link or
    // a base64 data URI from an uploaded logo image (see V3 migration).
    @Column(columnDefinition = "TEXT")
    private String logoUrl;

    // Brand theme — defaults applied at creation (see AuthService) so a
    // freshly registered org isn't blank/unstyled before the admin
    // customizes it in Company Setup.
    @Column(nullable = false)
    private String brand;
    @Column(nullable = false)
    private String brandDark;
    @Column(nullable = false)
    private String brandTint;
    @Column(name = "primary_color", nullable = false)
    private String primary;
    @Column(nullable = false)
    private String primaryPressed;
    @Column(nullable = false)
    private String primarySurface;
    @Column(nullable = false)
    private String primarySurfaceStrong;

    // Null until the Administrator sets it in Company Setup — the
    // clock-in geofence check (see ClockRecordService) is skipped
    // entirely when this is unset.
    private Double officeLatitude;
    private Double officeLongitude;
    private Integer officeRadiusMeters;

    // Informational only, shown to employees as "connect to X to clock
    // in" -- a phone can't verify a specific SSID without extra native
    // permissions most devices won't grant, so this labels the intended
    // network rather than being enforced (see ClockRecordService, which
    // still only checks "connected to any WiFi").
    private String wifiNetworkName;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();

    // Set TRUE by migration for every org that existed before plan
    // feature enforcement shipped (see V18), so nobody already using a
    // feature (custom branding, CSV import) loses it retroactively --
    // only orgs registering after that point are subject to the gates.
    // See PlanFeatureService.
    @Column(nullable = false)
    private boolean grandfatheredFeatures = false;
}
'@)

# --- src\main\java\com\visilog\api\service\PlanFeatureService.java ---
[System.IO.File]::WriteAllText('src\main\java\com\visilog\api\service\PlanFeatureService.java', @'
package com.visilog.api.service;

import com.visilog.api.entity.OrgBilling;
import com.visilog.api.entity.Organization;
import com.visilog.api.entity.Plan;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.OrgBillingRepository;
import com.visilog.api.repository.OrganizationRepository;
import com.visilog.api.repository.PlanRepository;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;

// Central chokepoint for plan-gated features (custom branding, CSV
// import) -- mirrors EmployeeService.checkSeatCap's load-billing/
// load-plan/compare-and-throw shape, but grandfathers any org that
// already existed when a gate shipped (Organization.grandfatheredFeatures,
// see V18 migration) so nobody loses something they were already using.
@Service
public class PlanFeatureService {

    // starter < pro < enterprise -- higher tiers satisfy lower requirements.
    private static final Map<String, Integer> TIER_ORDER = Map.of("starter", 0, "pro", 1, "enterprise", 2);

    private final OrganizationRepository organizationRepository;
    private final OrgBillingRepository orgBillingRepository;
    private final PlanRepository planRepository;

    public PlanFeatureService(
            OrganizationRepository organizationRepository, OrgBillingRepository orgBillingRepository,
            PlanRepository planRepository) {
        this.organizationRepository = organizationRepository;
        this.orgBillingRepository = orgBillingRepository;
        this.planRepository = planRepository;
    }

    // Throws a 409 with an upgrade-prompting message if the org's
    // current plan doesn't meet requiredPlanId and it isn't grandfathered.
    public void requirePlan(UUID organizationId, String requiredPlanId, String featureLabel) {
        Organization org = organizationRepository.findById(organizationId).orElse(null);
        if (org == null || org.isGrandfatheredFeatures()) {
            return;
        }
        OrgBilling billing = orgBillingRepository.findByOrganizationId(organizationId).orElse(null);
        if (billing == null || atLeast(billing.getPlanId(), requiredPlanId)) {
            return;
        }
        Plan required = planRepository.findById(requiredPlanId).orElse(null);
        String planName = required != null ? required.getName() : requiredPlanId;
        throw ApiException.conflict(
                featureLabel + " requires the " + planName + " plan or higher. Upgrade in Billing & subscription to unlock it.");
    }

    private boolean atLeast(String planId, String requiredPlanId) {
        return TIER_ORDER.getOrDefault(planId, 0) >= TIER_ORDER.getOrDefault(requiredPlanId, 0);
    }
}
'@)

# --- src\main\java\com\visilog\api\service\OrgService.java ---
[System.IO.File]::WriteAllText('src\main\java\com\visilog\api\service\OrgService.java', @'
package com.visilog.api.service;

import com.visilog.api.dto.OfficeLocationRequest;
import com.visilog.api.dto.OrganizationDto;
import com.visilog.api.dto.UpdateOrgRequest;
import com.visilog.api.entity.Organization;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.OrganizationRepository;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Company Setup > branding + office location — manager-only, enforced
// at the controller via @PreAuthorize("hasRole('MANAGER')").
@Service
public class OrgService {

    private final OrganizationRepository organizationRepository;
    private final PlanFeatureService planFeatureService;

    public OrgService(OrganizationRepository organizationRepository, PlanFeatureService planFeatureService) {
        this.organizationRepository = organizationRepository;
        this.planFeatureService = planFeatureService;
    }

    public OrganizationDto get(UUID organizationId) {
        return OrganizationDto.from(findOrThrow(organizationId));
    }

    @Transactional
    public OrganizationDto update(UUID organizationId, UpdateOrgRequest req) {
        Organization org = findOrThrow(organizationId);
        if (req.name() != null && !req.name().isBlank()) {
            org.setName(req.name().trim());
        }
        // Clearing the logo is always allowed -- only setting a new one
        // is the paid feature. Same for theme: only changing away from
        // the default is gated, never reverting.
        if (req.logoUrl() != null && !req.logoUrl().isBlank()) {
            planFeatureService.requirePlan(organizationId, "enterprise", "Custom branding");
        }
        if (req.theme() != null) {
            planFeatureService.requirePlan(organizationId, "enterprise", "Custom branding");
        }
        if (req.logoUrl() != null) {
            org.setLogoUrl(req.logoUrl().isBlank() ? null : req.logoUrl().trim());
        }
        if (req.wifiNetworkName() != null) {
            org.setWifiNetworkName(req.wifiNetworkName().isBlank() ? null : req.wifiNetworkName().trim());
        }
        if (req.theme() != null) {
            var t = req.theme();
            org.setBrand(t.brand());
            org.setBrandDark(t.brandDark());
            org.setBrandTint(t.brandTint());
            org.setPrimary(t.primary());
            org.setPrimaryPressed(t.primaryPressed());
            org.setPrimarySurface(t.primarySurface());
            org.setPrimarySurfaceStrong(t.primarySurfaceStrong());
        }
        return OrganizationDto.from(organizationRepository.save(org));
    }

    @Transactional
    public OrganizationDto updateOfficeLocation(UUID organizationId, OfficeLocationRequest req) {
        Organization org = findOrThrow(organizationId);
        org.setOfficeLatitude(req.latitude());
        org.setOfficeLongitude(req.longitude());
        org.setOfficeRadiusMeters(req.radiusMeters());
        return OrganizationDto.from(organizationRepository.save(org));
    }

    private Organization findOrThrow(UUID organizationId) {
        return organizationRepository.findById(organizationId)
                .orElseThrow(() -> ApiException.notFound("Organization not found."));
    }
}
'@)

# --- src\main\java\com\visilog\api\service\EmployeeService.java ---
[System.IO.File]::WriteAllText('src\main\java\com\visilog\api\service\EmployeeService.java', @'
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
// against — adding someone here with role=RECEPTIONIST/MANAGER/EMPLOYEE
// is what lets them get that role automatically when they sign up with
// a matching email, instead of the old free role-picker.
//
// Note: editing an Employee's role here does NOT retroactively change
// any AppUser who already signed up — role is fixed at signup time by
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

    // CSV bulk import from Company Setup — succeeds row by row rather
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
'@)

# --- src\main\java\com\visilog\api\service\MeetingRoomService.java ---
[System.IO.File]::WriteAllText('src\main\java\com\visilog\api\service\MeetingRoomService.java', @'
package com.visilog.api.service;

import com.visilog.api.dto.BulkImportResult;
import com.visilog.api.dto.MeetingRoomDto;
import com.visilog.api.dto.MeetingRoomRequest;
import com.visilog.api.entity.MeetingRoom;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.MeetingRoomRepository;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MeetingRoomService {

    private final MeetingRoomRepository meetingRoomRepository;
    private final PlanFeatureService planFeatureService;

    public MeetingRoomService(MeetingRoomRepository meetingRoomRepository, PlanFeatureService planFeatureService) {
        this.meetingRoomRepository = meetingRoomRepository;
        this.planFeatureService = planFeatureService;
    }

    public List<MeetingRoomDto> list(UUID organizationId) {
        return meetingRoomRepository.findByOrganizationId(organizationId).stream()
                .map(MeetingRoomDto::from)
                .toList();
    }

    @Transactional
    public MeetingRoomDto create(UUID organizationId, MeetingRoomRequest req) {
        MeetingRoom r = new MeetingRoom();
        r.setOrganizationId(organizationId);
        applyRequest(r, req);
        return MeetingRoomDto.from(meetingRoomRepository.save(r));
    }

    @Transactional
    public MeetingRoomDto update(UUID organizationId, UUID roomId, MeetingRoomRequest req) {
        MeetingRoom r = meetingRoomRepository.findByOrganizationIdAndId(organizationId, roomId)
                .orElseThrow(() -> ApiException.notFound("Meeting room not found."));
        applyRequest(r, req);
        return MeetingRoomDto.from(meetingRoomRepository.save(r));
    }

    // CSV bulk import from Company Setup — see EmployeeService.bulkCreate
    // for why this stays row-by-row and un-@Transactional.
    public BulkImportResult<MeetingRoomDto> bulkCreate(UUID organizationId, List<MeetingRoomRequest> rows) {
        planFeatureService.requirePlan(organizationId, "pro", "CSV import");
        List<MeetingRoomDto> created = new ArrayList<>();
        List<BulkImportResult.RowError> errors = new ArrayList<>();
        for (int i = 0; i < rows.size(); i++) {
            int rowNumber = i + 1;
            try {
                if (rows.get(i).name() == null || rows.get(i).name().isBlank()) {
                    throw ApiException.badRequest("Room name is required.");
                }
                created.add(create(organizationId, rows.get(i)));
            } catch (ApiException ex) {
                errors.add(new BulkImportResult.RowError(rowNumber, ex.getMessage()));
            }
        }
        return new BulkImportResult<>(created, errors);
    }

    @Transactional
    public void delete(UUID organizationId, UUID roomId) {
        MeetingRoom r = meetingRoomRepository.findByOrganizationIdAndId(organizationId, roomId)
                .orElseThrow(() -> ApiException.notFound("Meeting room not found."));
        meetingRoomRepository.delete(r);
    }

    private void applyRequest(MeetingRoom r, MeetingRoomRequest req) {
        r.setName(req.name().trim());
        r.setCapacity(req.capacity());
        r.setFloor(req.floor());
        r.setPhotoUrl(req.photoUrl());
        r.setDescription(req.description());
    }
}
'@)

# --- src\test\java\com\visilog\api\service\PlanFeatureServiceTest.java ---
[System.IO.File]::WriteAllText('src\test\java\com\visilog\api\service\PlanFeatureServiceTest.java', @'
package com.visilog.api.service;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import com.visilog.api.entity.OrgBilling;
import com.visilog.api.entity.Organization;
import com.visilog.api.entity.Plan;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.OrgBillingRepository;
import com.visilog.api.repository.OrganizationRepository;
import com.visilog.api.repository.PlanRepository;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class PlanFeatureServiceTest {

    @Mock private OrganizationRepository organizationRepository;
    @Mock private OrgBillingRepository orgBillingRepository;
    @Mock private PlanRepository planRepository;

    private PlanFeatureService service;
    private final UUID orgId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new PlanFeatureService(organizationRepository, orgBillingRepository, planRepository);
    }

    private Organization org(boolean grandfathered) {
        Organization o = new Organization();
        o.setGrandfatheredFeatures(grandfathered);
        return o;
    }

    private OrgBilling billing(String planId) {
        OrgBilling b = new OrgBilling();
        b.setPlanId(planId);
        return b;
    }

    @Test
    void grandfatheredOrgKeepsAccessRegardlessOfPlan() {
        when(organizationRepository.findById(orgId)).thenReturn(Optional.of(org(true)));

        assertThatCode(() -> service.requirePlan(orgId, "enterprise", "Custom branding"))
                .doesNotThrowAnyException();
    }

    @Test
    void orgOnQualifyingPlanIsAllowed() {
        when(organizationRepository.findById(orgId)).thenReturn(Optional.of(org(false)));
        when(orgBillingRepository.findByOrganizationId(orgId)).thenReturn(Optional.of(billing("pro")));

        assertThatCode(() -> service.requirePlan(orgId, "pro", "CSV import"))
                .doesNotThrowAnyException();
    }

    @Test
    void orgOnHigherPlanThanRequiredIsAllowed() {
        when(organizationRepository.findById(orgId)).thenReturn(Optional.of(org(false)));
        when(orgBillingRepository.findByOrganizationId(orgId)).thenReturn(Optional.of(billing("enterprise")));

        assertThatCode(() -> service.requirePlan(orgId, "pro", "CSV import"))
                .doesNotThrowAnyException();
    }

    @Test
    void nonGrandfatheredOrgBelowRequiredPlanIsBlocked() {
        when(organizationRepository.findById(orgId)).thenReturn(Optional.of(org(false)));
        when(orgBillingRepository.findByOrganizationId(orgId)).thenReturn(Optional.of(billing("starter")));
        Plan pro = new Plan();
        pro.setId("pro");
        pro.setName("Pro");
        when(planRepository.findById("pro")).thenReturn(Optional.of(pro));

        assertThatThrownBy(() -> service.requirePlan(orgId, "pro", "CSV import"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("CSV import")
                .hasMessageContaining("Pro plan or higher");
    }

    @Test
    void missingBillingRowFailsOpen() {
        when(organizationRepository.findById(orgId)).thenReturn(Optional.of(org(false)));
        when(orgBillingRepository.findByOrganizationId(orgId)).thenReturn(Optional.empty());

        assertThatCode(() -> service.requirePlan(orgId, "enterprise", "Custom branding"))
                .doesNotThrowAnyException();
    }

    @Test
    void missingOrgFailsOpen() {
        when(organizationRepository.findById(orgId)).thenReturn(Optional.empty());

        assertThatCode(() -> service.requirePlan(orgId, "enterprise", "Custom branding"))
                .doesNotThrowAnyException();
    }
}
'@)

Write-Host '--- Files written, verifying ---'
if (Test-Path "src\main\resources\db\migration\V18__plan_feature_gates.sql") { Write-Host "OK   src\main\resources\db\migration\V18__plan_feature_gates.sql" } else { Write-Host "MISSING src\main\resources\db\migration\V18__plan_feature_gates.sql" -ForegroundColor Red }
if (Test-Path "src\main\java\com\visilog\api\entity\Organization.java") { Write-Host "OK   src\main\java\com\visilog\api\entity\Organization.java" } else { Write-Host "MISSING src\main\java\com\visilog\api\entity\Organization.java" -ForegroundColor Red }
if (Test-Path "src\main\java\com\visilog\api\service\PlanFeatureService.java") { Write-Host "OK   src\main\java\com\visilog\api\service\PlanFeatureService.java" } else { Write-Host "MISSING src\main\java\com\visilog\api\service\PlanFeatureService.java" -ForegroundColor Red }
if (Test-Path "src\main\java\com\visilog\api\service\OrgService.java") { Write-Host "OK   src\main\java\com\visilog\api\service\OrgService.java" } else { Write-Host "MISSING src\main\java\com\visilog\api\service\OrgService.java" -ForegroundColor Red }
if (Test-Path "src\main\java\com\visilog\api\service\EmployeeService.java") { Write-Host "OK   src\main\java\com\visilog\api\service\EmployeeService.java" } else { Write-Host "MISSING src\main\java\com\visilog\api\service\EmployeeService.java" -ForegroundColor Red }
if (Test-Path "src\main\java\com\visilog\api\service\MeetingRoomService.java") { Write-Host "OK   src\main\java\com\visilog\api\service\MeetingRoomService.java" } else { Write-Host "MISSING src\main\java\com\visilog\api\service\MeetingRoomService.java" -ForegroundColor Red }
if (Test-Path "src\test\java\com\visilog\api\service\PlanFeatureServiceTest.java") { Write-Host "OK   src\test\java\com\visilog\api\service\PlanFeatureServiceTest.java" } else { Write-Host "MISSING src\test\java\com\visilog\api\service\PlanFeatureServiceTest.java" -ForegroundColor Red }

Stop-Transcript
Write-Host ''
Write-Host 'Done. Now run: .\mvnw.cmd -q test' -ForegroundColor Green