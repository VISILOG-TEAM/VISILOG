# VisiLog -- device-binding for clock-in (backend)
# Run this from the SERVER folder (VisiLog-frontend\server), NOT the frontend root.
$ErrorActionPreference = 'Stop'
Start-Transcript -Path "$PSScriptRoot\devicebinding-backend-log.txt" -Force | Out-Null

function Write-File($RelPath, $Content) {
    $full = Join-Path $PSScriptRoot $RelPath
    $dir = Split-Path $full -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($full, $Content)
}

Write-Host "--- Writing files ---"
$f0 = @'
-- Clock-in device binding, to stop the "give a coworker your password so
-- they clock in for you" case: the first phone an employee ever clocks
-- in from gets linked to their account, and a clock-in attempt from any
-- other phone is rejected regardless of whose login was used. A manager
-- can clear the link from Company Setup if someone genuinely gets a new
-- phone. See ClockRecordService.

ALTER TABLE employees ADD COLUMN bound_device_id VARCHAR(255);

'@
Write-File "src\main\resources\db\migration\V19__employee_device_binding.sql" $f0
$f1 = @'
package com.visilog.api.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// The Administrator's staff roster -- managed in Company Setup. This is
// the source of truth AuthService checks at signup: an AppUser whose
// email matches an Employee row here inherits that row's role and gets
// linked to it; no match falls back to Role.VISITOR.
@Entity
@Table(name = "employees", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"organization_id", "email"}),
    @UniqueConstraint(columnNames = {"organization_id", "employee_code"})
})
@Getter
@Setter
@NoArgsConstructor
public class Employee {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    // Human-readable badge-style code shown on the roster, e.g. "VRA-1004".
    @Column(name = "employee_code", nullable = false, length = 32)
    private String employeeCode;

    @Column(nullable = false)
    private String name;

    private String department;
    private String phone;

    @Column(nullable = false)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private Role role;

    // The device this employee last clocked in from -- null until their
    // first clock-in. See ClockRecordService.checkDeviceBinding.
    @Column(name = "bound_device_id")
    private String boundDeviceId;
}

'@
Write-File "src\main\java\com\visilog\api\entity\Employee.java" $f1
$f2 = @'
package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record ClockActionRequest(
        @NotNull(message = "is required") UUID employeeId,
        @NotBlank(message = "is required") String employeeName,
        // Optional -- a device that can't report one (e.g. an older app
        // build) just skips the device-binding check rather than being
        // blocked outright. See ClockRecordService.
        String deviceId
) {
}

'@
Write-File "src\main\java\com\visilog\api\dto\ClockActionRequest.java" $f2
$f3 = @'
package com.visilog.api.dto;

import com.visilog.api.entity.Employee;
import java.util.UUID;

public record EmployeeDto(
        UUID id, String employeeCode, String name, String department,
        String phone, String email, String role, boolean deviceBound
) {
    public static EmployeeDto from(Employee e) {
        return new EmployeeDto(
                e.getId(), e.getEmployeeCode(), e.getName(), e.getDepartment(),
                e.getPhone(), e.getEmail(), e.getRole().name(), e.getBoundDeviceId() != null);
    }
}

'@
Write-File "src\main\java\com\visilog\api\dto\EmployeeDto.java" $f3
$f4 = @'
package com.visilog.api.service;

import com.visilog.api.dto.ClockActionRequest;
import com.visilog.api.dto.ClockRecordDto;
import com.visilog.api.dto.ClockStatusDto;
import com.visilog.api.entity.ClockRecord;
import com.visilog.api.entity.ClockType;
import com.visilog.api.entity.Employee;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.ClockRecordRepository;
import com.visilog.api.repository.EmployeeRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Work attendance. WiFi and GPS-geofence checks happen client-side
// (src/data/wifiCheck.js, src/data/locationCheck.js) before the app
// ever calls clockIn -- an HTTP request alone can't verify a caller's
// WiFi network or GPS position, so the backend's job is the two rules
// an HTTP API *can* enforce reliably: one clock-in per employee per
// calendar day (UTC), and clock-in device binding (see
// checkDeviceBinding) -- stops "give a coworker my password so they can
// clock in for me," since it doesn't matter whose login was used, only
// whose phone it is.
@Service
public class ClockRecordService {

    private final ClockRecordRepository clockRecordRepository;
    private final EmployeeRepository employeeRepository;

    public ClockRecordService(ClockRecordRepository clockRecordRepository, EmployeeRepository employeeRepository) {
        this.clockRecordRepository = clockRecordRepository;
        this.employeeRepository = employeeRepository;
    }

    public List<ClockRecordDto> list(UUID organizationId) {
        return clockRecordRepository.findByOrganizationIdOrderByTimestampDesc(organizationId).stream()
                .map(ClockRecordDto::from)
                .toList();
    }

    public ClockStatusDto status(UUID organizationId, UUID employeeId) {
        var last = clockRecordRepository.findFirstByOrganizationIdAndEmployeeIdOrderByTimestampDesc(organizationId, employeeId);
        boolean clockedIn = last.isPresent() && last.get().getType() == ClockType.IN;
        boolean today = hasClockedInToday(organizationId, employeeId);
        return new ClockStatusDto(clockedIn, today, last.map(ClockRecordDto::from).orElse(null));
    }

    @Transactional
    public ClockRecordDto clockIn(UUID organizationId, ClockActionRequest req) {
        if (hasClockedInToday(organizationId, req.employeeId())) {
            throw ApiException.conflict("You can only clock in once per day -- see you tomorrow.");
        }
        checkDeviceBinding(organizationId, req.employeeId(), req.deviceId());
        return save(organizationId, req, ClockType.IN);
    }

    @Transactional
    public ClockRecordDto clockOut(UUID organizationId, ClockActionRequest req) {
        return save(organizationId, req, ClockType.OUT);
    }

    // First clock-in from a device links it to that employee going
    // forward; a later clock-in attempt from a different device is
    // rejected outright, regardless of which account's credentials were
    // used to sign in -- see the class comment. Missing deviceId (an
    // older app build, or the platform couldn't report one) skips this
    // check entirely rather than blocking the clock-in.
    private void checkDeviceBinding(UUID organizationId, UUID employeeId, String deviceId) {
        if (deviceId == null || deviceId.isBlank()) {
            return;
        }
        Employee employee = employeeRepository.findByOrganizationIdAndId(organizationId, employeeId).orElse(null);
        if (employee == null) {
            return;
        }
        if (employee.getBoundDeviceId() == null) {
            employee.setBoundDeviceId(deviceId);
            employeeRepository.save(employee);
            return;
        }
        if (!employee.getBoundDeviceId().equals(deviceId)) {
            throw ApiException.conflict(
                    "This account is registered to a different phone. If you've switched devices, "
                    + "ask your Administrator to reset it in Company Setup.");
        }
    }

    private boolean hasClockedInToday(UUID organizationId, UUID employeeId) {
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        Instant startOfDay = today.atStartOfDay(ZoneOffset.UTC).toInstant();
        Instant startOfNextDay = today.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();
        return clockRecordRepository.existsByOrganizationIdAndEmployeeIdAndTypeAndTimestampBetween(
                organizationId, employeeId, ClockType.IN, startOfDay, startOfNextDay);
    }

    private ClockRecordDto save(UUID organizationId, ClockActionRequest req, ClockType type) {
        ClockRecord r = new ClockRecord();
        r.setOrganizationId(organizationId);
        r.setEmployeeId(req.employeeId());
        r.setEmployeeName(req.employeeName());
        r.setType(type);
        r.setTimestamp(Instant.now());
        return ClockRecordDto.from(clockRecordRepository.save(r));
    }
}

'@
Write-File "src\main\java\com\visilog\api\service\ClockRecordService.java" $f4
$f5 = @'
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

    // See ClockRecordService.checkDeviceBinding -- clears the link so
    // the next clock-in from any device re-binds fresh.
    @Transactional
    public EmployeeDto resetDevice(UUID organizationId, UUID employeeId) {
        Employee e = employeeRepository.findByOrganizationIdAndId(organizationId, employeeId)
                .orElseThrow(() -> ApiException.notFound("Employee not found."));
        e.setBoundDeviceId(null);
        return EmployeeDto.from(employeeRepository.save(e));
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

'@
Write-File "src\main\java\com\visilog\api\service\EmployeeService.java" $f5
$f6 = @'
package com.visilog.api.controller;

import com.visilog.api.dto.BulkEmployeeRequest;
import com.visilog.api.dto.BulkImportResult;
import com.visilog.api.dto.EmployeeDto;
import com.visilog.api.dto.EmployeeRequest;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.EmployeeService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

// The staff directory. Reading it is open to any signed-in user in the
// org (host pickers on Book screens etc. need it); creating/editing/
// deleting entries -- including who gets which role -- is manager-only.
@RestController
@RequestMapping("/api/v1/employees")
public class EmployeeController {

    private final EmployeeService employeeService;

    public EmployeeController(EmployeeService employeeService) {
        this.employeeService = employeeService;
    }

    @GetMapping
    public ResponseEntity<List<EmployeeDto>> list(@CurrentUser AuthPrincipal me) {
        return ResponseEntity.ok(employeeService.list(me.organizationId()));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @PostMapping
    public ResponseEntity<EmployeeDto> create(@CurrentUser AuthPrincipal me, @Valid @RequestBody EmployeeRequest request) {
        return ResponseEntity.ok(employeeService.create(me.organizationId(), request));
    }

    // CSV bulk import from Company Setup -- parsed client-side, sent
    // here as plain JSON rows. Row-by-row result so a few bad rows
    // don't block the rest of a large roster.
    @PreAuthorize("hasRole('MANAGER')")
    @PostMapping("/bulk")
    public ResponseEntity<BulkImportResult<EmployeeDto>> bulkCreate(
            @CurrentUser AuthPrincipal me, @RequestBody BulkEmployeeRequest request) {
        return ResponseEntity.ok(employeeService.bulkCreate(me.organizationId(), request.employees()));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @PatchMapping("/{id}")
    public ResponseEntity<EmployeeDto> update(
            @CurrentUser AuthPrincipal me, @PathVariable UUID id, @Valid @RequestBody EmployeeRequest request) {
        return ResponseEntity.ok(employeeService.update(me.organizationId(), id, request));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@CurrentUser AuthPrincipal me, @PathVariable UUID id) {
        employeeService.delete(me.organizationId(), id);
        return ResponseEntity.noContent().build();
    }

    // Clears the phone linked to this employee's clock-ins (see
    // ClockRecordService) -- for when someone genuinely gets a new
    // phone. Deliberately manager-only so it can't be self-service
    // reset by whoever's trying to clock in from an unrecognised device.
    @PreAuthorize("hasRole('MANAGER')")
    @PostMapping("/{id}/reset-device")
    public ResponseEntity<EmployeeDto> resetDevice(@CurrentUser AuthPrincipal me, @PathVariable UUID id) {
        return ResponseEntity.ok(employeeService.resetDevice(me.organizationId(), id));
    }
}

'@
Write-File "src\main\java\com\visilog\api\controller\EmployeeController.java" $f6
$f7 = @'
package com.visilog.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.visilog.api.dto.ClockActionRequest;
import com.visilog.api.entity.ClockRecord;
import com.visilog.api.entity.Employee;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.ClockRecordRepository;
import com.visilog.api.repository.EmployeeRepository;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class ClockRecordServiceTest {

    @Mock private ClockRecordRepository clockRecordRepository;
    @Mock private EmployeeRepository employeeRepository;

    private ClockRecordService service;
    private final UUID orgId = UUID.randomUUID();
    private final UUID employeeId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new ClockRecordService(clockRecordRepository, employeeRepository);
    }

    private void stubNotClockedInToday() {
        when(clockRecordRepository.existsByOrganizationIdAndEmployeeIdAndTypeAndTimestampBetween(
                any(), any(), any(), any(), any())).thenReturn(false);
    }

    private void stubSaveEchoesRecord() {
        when(clockRecordRepository.save(any())).thenAnswer(inv -> {
            ClockRecord r = inv.getArgument(0);
            r.setId(UUID.randomUUID());
            return r;
        });
    }

    @Test
    void firstClockInOfTheDaySucceeds() {
        stubNotClockedInToday();
        stubSaveEchoesRecord();

        var result = service.clockIn(orgId, new ClockActionRequest(employeeId, "Wendy Abagna", null));

        assertThat(result.type()).isEqualTo("IN");
        assertThat(result.employeeId()).isEqualTo(employeeId);
    }

    @Test
    void secondClockInSameDayIsRejected() {
        when(clockRecordRepository.existsByOrganizationIdAndEmployeeIdAndTypeAndTimestampBetween(
                any(), any(), any(), any(), any())).thenReturn(true);

        assertThatThrownBy(() -> service.clockIn(orgId, new ClockActionRequest(employeeId, "Wendy Abagna", null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("once per day");
    }

    @Test
    void clockOutIsNeverBlockedByTheDailyLimit() {
        stubSaveEchoesRecord();

        var result = service.clockOut(orgId, new ClockActionRequest(employeeId, "Wendy Abagna", null));

        assertThat(result.type()).isEqualTo("OUT");
    }

    @Test
    void firstClockInFromAnyDeviceBindsIt() {
        stubNotClockedInToday();
        stubSaveEchoesRecord();
        Employee employee = new Employee();
        when(employeeRepository.findByOrganizationIdAndId(orgId, employeeId)).thenReturn(Optional.of(employee));

        service.clockIn(orgId, new ClockActionRequest(employeeId, "Wendy Abagna", "device-a"));

        assertThat(employee.getBoundDeviceId()).isEqualTo("device-a");
    }

    @Test
    void clockInFromTheSameBoundDeviceSucceeds() {
        stubNotClockedInToday();
        stubSaveEchoesRecord();
        Employee employee = new Employee();
        employee.setBoundDeviceId("device-a");
        when(employeeRepository.findByOrganizationIdAndId(orgId, employeeId)).thenReturn(Optional.of(employee));

        var result = service.clockIn(orgId, new ClockActionRequest(employeeId, "Wendy Abagna", "device-a"));

        assertThat(result.type()).isEqualTo("IN");
    }

    @Test
    void clockInFromADifferentDeviceThanTheBoundOneIsRejected() {
        stubNotClockedInToday();
        Employee employee = new Employee();
        employee.setBoundDeviceId("device-a");
        when(employeeRepository.findByOrganizationIdAndId(orgId, employeeId)).thenReturn(Optional.of(employee));

        assertThatThrownBy(() -> service.clockIn(orgId, new ClockActionRequest(employeeId, "Wendy Abagna", "device-b")))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("different phone");
    }

    @Test
    void clockInWithNoDeviceIdSkipsTheBindingCheck() {
        stubNotClockedInToday();
        stubSaveEchoesRecord();

        var result = service.clockIn(orgId, new ClockActionRequest(employeeId, "Wendy Abagna", null));

        assertThat(result.type()).isEqualTo("IN");
    }
}

'@
Write-File "src\test\java\com\visilog\api\service\ClockRecordServiceTest.java" $f7

Write-Host "--- Files written, verifying ---"
$paths = @(
    "src\main\resources\db\migration\V19__employee_device_binding.sql",
    "src\main\java\com\visilog\api\entity\Employee.java",
    "src\main\java\com\visilog\api\dto\ClockActionRequest.java",
    "src\main\java\com\visilog\api\dto\EmployeeDto.java",
    "src\main\java\com\visilog\api\service\ClockRecordService.java",
    "src\main\java\com\visilog\api\service\EmployeeService.java",
    "src\main\java\com\visilog\api\controller\EmployeeController.java",
    "src\test\java\com\visilog\api\service\ClockRecordServiceTest.java"
)
foreach ($p in $paths) {
    $full = Join-Path $PSScriptRoot $p
    if (Test-Path $full) { Write-Host "OK   $p" } else { Write-Host "MISSING   $p" }
}

Stop-Transcript | Out-Null
Write-Host ""
Write-Host "Done. Now run: .\mvnw.cmd -q test"
