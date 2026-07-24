# VisiLog -- billing-tier features: priority support badge, interactive
# tour map gating, and multiple office locations (backend).
# Run this from the SERVER folder (VisiLog-frontend\server), NOT the frontend root.
$ErrorActionPreference = 'Stop'
Start-Transcript -Path "$PSScriptRoot\billingfeatures-backend-log.txt" -Force | Out-Null

function Write-File($RelPath, $Content) {
    $full = Join-Path $PSScriptRoot $RelPath
    $dir = Split-Path $full -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($full, $Content)
}

Write-Host "--- Writing files ---"
$f0 = @'
-- Priority support becomes a real, visible plan perk again (it existed
-- as a bullet in the original V2 seed but was dropped by later
-- reseeds). Purely a display-driven gate -- SettingsScreen shows a
-- badge and a different Help & support message when the org's current
-- plan's features list contains this string, no new enforcement logic
-- needed since there's no action being blocked, just a UI difference.
--
-- Same pattern for the interactive tour map (CompanyMapSection, already
-- built for visitors) -- reserving it to Pro/Enterprise rather than
-- building anything new; VisitorHomeScreen checks for this string.

INSERT INTO plan_features (plan_id, feature, position) VALUES
    ('pro', 'Priority support', 2),
    ('pro', 'Interactive tour map', 3),
    ('enterprise', 'Priority support', 3),
    ('enterprise', 'Interactive tour map', 4);

'@
Write-File "src\main\resources\db\migration\V20__priority_support_and_tour_map_features.sql" $f0
$f1 = @'
package db.migration;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.UUID;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

// Organizations move from a single office_latitude/longitude/radius to
// a real one-to-many office_locations table (see OfficeLocation entity,
// gated to more than one location per org via
// PlanFeatureService/OfficeLocationService). A Java migration rather
// than plain SQL purely so the backfilled rows' ids can be generated
// with java.util.UUID instead of a Postgres-only function like
// gen_random_uuid(), which the H2-in-Postgres-mode test database (see
// application-test.yml) isn't guaranteed to support.
public class V21__MultipleOfficeLocations extends BaseJavaMigration {

    @Override
    public void migrate(Context context) throws Exception {
        Connection conn = context.getConnection();

        try (Statement st = conn.createStatement()) {
            st.execute(
                    "CREATE TABLE office_locations ("
                            + "id               UUID PRIMARY KEY,"
                            + "organization_id  UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,"
                            + "name             VARCHAR(255) NOT NULL,"
                            + "latitude         DOUBLE PRECISION NOT NULL,"
                            + "longitude        DOUBLE PRECISION NOT NULL,"
                            + "radius_meters    INTEGER NOT NULL,"
                            + "created_at       TIMESTAMP NOT NULL"
                            + ")");
        }

        try (PreparedStatement select = conn.prepareStatement(
                "SELECT id, office_latitude, office_longitude, office_radius_meters "
                        + "FROM organizations WHERE office_latitude IS NOT NULL");
                ResultSet rs = select.executeQuery()) {
            try (PreparedStatement insert = conn.prepareStatement(
                    "INSERT INTO office_locations "
                            + "(id, organization_id, name, latitude, longitude, radius_meters, created_at) "
                            + "VALUES (?, ?, 'Main office', ?, ?, ?, ?)")) {
                boolean any = false;
                while (rs.next()) {
                    insert.setObject(1, UUID.randomUUID());
                    insert.setObject(2, rs.getObject("id", UUID.class));
                    insert.setDouble(3, rs.getDouble("office_latitude"));
                    insert.setDouble(4, rs.getDouble("office_longitude"));
                    insert.setInt(5, rs.getInt("office_radius_meters"));
                    insert.setTimestamp(6, Timestamp.from(Instant.now()));
                    insert.addBatch();
                    any = true;
                }
                if (any) {
                    insert.executeBatch();
                }
            }
        }

        try (Statement st = conn.createStatement()) {
            st.execute("ALTER TABLE organizations DROP COLUMN office_latitude");
            st.execute("ALTER TABLE organizations DROP COLUMN office_longitude");
            st.execute("ALTER TABLE organizations DROP COLUMN office_radius_meters");
        }
    }
}

'@
Write-File "src\main\java\db\migration\V21__MultipleOfficeLocations.java" $f1
$f2 = @'
package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// A paying tenant. Self-registered via POST /companies/register -- see
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

    // TEXT, not the default VARCHAR(255) -- holds either a pasted link or
    // a base64 data URI from an uploaded logo image (see V3 migration).
    @Column(columnDefinition = "TEXT")
    private String logoUrl;

    // Brand theme -- defaults applied at creation (see AuthService) so a
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

'@
Write-File "src\main\java\com\visilog\api\entity\Organization.java" $f2
$f3 = @'
package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// A named GPS point + radius an org's clock-in/visitor-check-in
// geofence check (client-side, see locationCheck.ts) can be satisfied
// against -- an org can have more than one (see V21 migration, which
// replaced Organization's single office_latitude/longitude/radius).
// Every org gets one free; a second+ requires the enterprise plan (see
// OfficeLocationService).
@Entity
@Table(name = "office_locations")
@Getter
@Setter
@NoArgsConstructor
public class OfficeLocation {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false)
    private UUID organizationId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    @Column(nullable = false)
    private Integer radiusMeters;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();
}

'@
Write-File "src\main\java\com\visilog\api\entity\OfficeLocation.java" $f3
$f4 = @'
package com.visilog.api.repository;

import com.visilog.api.entity.OfficeLocation;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OfficeLocationRepository extends JpaRepository<OfficeLocation, UUID> {
    List<OfficeLocation> findByOrganizationId(UUID organizationId);
    Optional<OfficeLocation> findByOrganizationIdAndId(UUID organizationId, UUID id);
    long countByOrganizationId(UUID organizationId);
}

'@
Write-File "src\main\java\com\visilog\api\repository\OfficeLocationRepository.java" $f4
$f5 = @'
package com.visilog.api.dto;

import com.visilog.api.entity.OfficeLocation;
import java.util.UUID;

public record OfficeLocationDto(
        UUID id, String name, Double latitude, Double longitude, Integer radiusMeters
) {
    public static OfficeLocationDto from(OfficeLocation loc) {
        return new OfficeLocationDto(
                loc.getId(), loc.getName(), loc.getLatitude(), loc.getLongitude(), loc.getRadiusMeters());
    }
}

'@
Write-File "src\main\java\com\visilog\api\dto\OfficeLocationDto.java" $f5
$f6 = @'
package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record OfficeLocationRequest(
        @NotBlank String name,
        @NotNull Double latitude,
        @NotNull Double longitude,
        @NotNull Integer radiusMeters
) {
}

'@
Write-File "src\main\java\com\visilog\api\dto\OfficeLocationRequest.java" $f6
$f7 = @'
package com.visilog.api.dto;

import com.visilog.api.entity.Organization;
import java.util.UUID;

public record OrganizationDto(
        UUID id,
        String code,
        String name,
        String logoUrl,
        ThemeDto theme,
        String wifiNetworkName,
        // The org's current plan id -- exposed here (not just via the
        // manager-only GET /billing) so every role can do client-side
        // plan-feature checks like SettingsScreen's priority-support
        // badge and VisitorHomeScreen's tour map gate, without needing
        // access to the rest of Billing (payment info, invoices).
        String planId
) {
    public record ThemeDto(
            String brand, String brandDark, String brandTint,
            String primary, String primaryPressed, String primarySurface, String primarySurfaceStrong
    ) {
    }

    public static OrganizationDto from(Organization org, String planId) {
        return new OrganizationDto(
                org.getId(), org.getCode(), org.getName(), org.getLogoUrl(),
                new ThemeDto(
                        org.getBrand(), org.getBrandDark(), org.getBrandTint(),
                        org.getPrimary(), org.getPrimaryPressed(), org.getPrimarySurface(), org.getPrimarySurfaceStrong()),
                org.getWifiNetworkName(), planId);
    }
}

'@
Write-File "src\main\java\com\visilog\api\dto\OrganizationDto.java" $f7
$f8 = @'
package com.visilog.api.service;

import com.visilog.api.dto.OrganizationDto;
import com.visilog.api.dto.UpdateOrgRequest;
import com.visilog.api.entity.OrgBilling;
import com.visilog.api.entity.Organization;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.OrgBillingRepository;
import com.visilog.api.repository.OrganizationRepository;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Company Setup > branding -- manager-only, enforced at the controller
// via @PreAuthorize("hasRole('MANAGER')"). Office location moved to
// OfficeLocationService/Controller (see V21 migration).
@Service
public class OrgService {

    private final OrganizationRepository organizationRepository;
    private final OrgBillingRepository orgBillingRepository;
    private final PlanFeatureService planFeatureService;

    public OrgService(
            OrganizationRepository organizationRepository, OrgBillingRepository orgBillingRepository,
            PlanFeatureService planFeatureService) {
        this.organizationRepository = organizationRepository;
        this.orgBillingRepository = orgBillingRepository;
        this.planFeatureService = planFeatureService;
    }

    public OrganizationDto get(UUID organizationId) {
        return OrganizationDto.from(findOrThrow(organizationId), currentPlanId(organizationId));
    }

    private String currentPlanId(UUID organizationId) {
        return orgBillingRepository.findByOrganizationId(organizationId)
                .map(OrgBilling::getPlanId).orElse(null);
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
        return OrganizationDto.from(organizationRepository.save(org), currentPlanId(organizationId));
    }

    private Organization findOrThrow(UUID organizationId) {
        return organizationRepository.findById(organizationId)
                .orElseThrow(() -> ApiException.notFound("Organization not found."));
    }
}

'@
Write-File "src\main\java\com\visilog\api\service\OrgService.java" $f8
$f9 = @'
package com.visilog.api.service;

import com.visilog.api.dto.OfficeLocationDto;
import com.visilog.api.dto.OfficeLocationRequest;
import com.visilog.api.entity.OfficeLocation;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.OfficeLocationRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Company Setup > office locations -- every org gets one free; a
// second (or more) requires the enterprise plan. Replaced Organization's
// single office_latitude/longitude/radius (see V21 migration) so an org
// with multiple sites can have the clock-in/visitor-check-in geofence
// check (client-side, see locationCheck.ts) pass at any one of them.
@Service
public class OfficeLocationService {

    private final OfficeLocationRepository officeLocationRepository;
    private final PlanFeatureService planFeatureService;

    public OfficeLocationService(
            OfficeLocationRepository officeLocationRepository, PlanFeatureService planFeatureService) {
        this.officeLocationRepository = officeLocationRepository;
        this.planFeatureService = planFeatureService;
    }

    public List<OfficeLocationDto> list(UUID organizationId) {
        return officeLocationRepository.findByOrganizationId(organizationId).stream()
                .map(OfficeLocationDto::from)
                .toList();
    }

    @Transactional
    public OfficeLocationDto create(UUID organizationId, OfficeLocationRequest req) {
        if (officeLocationRepository.countByOrganizationId(organizationId) >= 1) {
            planFeatureService.requirePlan(organizationId, "enterprise", "A second office location");
        }
        OfficeLocation loc = new OfficeLocation();
        loc.setOrganizationId(organizationId);
        applyRequest(loc, req);
        return OfficeLocationDto.from(officeLocationRepository.save(loc));
    }

    @Transactional
    public OfficeLocationDto update(UUID organizationId, UUID id, OfficeLocationRequest req) {
        OfficeLocation loc = findOrThrow(organizationId, id);
        applyRequest(loc, req);
        return OfficeLocationDto.from(officeLocationRepository.save(loc));
    }

    @Transactional
    public void delete(UUID organizationId, UUID id) {
        OfficeLocation loc = findOrThrow(organizationId, id);
        officeLocationRepository.delete(loc);
    }

    private void applyRequest(OfficeLocation loc, OfficeLocationRequest req) {
        loc.setName(req.name().trim());
        loc.setLatitude(req.latitude());
        loc.setLongitude(req.longitude());
        loc.setRadiusMeters(req.radiusMeters());
    }

    private OfficeLocation findOrThrow(UUID organizationId, UUID id) {
        return officeLocationRepository.findByOrganizationIdAndId(organizationId, id)
                .orElseThrow(() -> ApiException.notFound("Office location not found."));
    }
}

'@
Write-File "src\main\java\com\visilog\api\service\OfficeLocationService.java" $f9
$f10 = @'
package com.visilog.api.controller;

import com.visilog.api.dto.OrganizationDto;
import com.visilog.api.dto.UpdateOrgRequest;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.OrgService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/org")
public class OrgController {

    private final OrgService orgService;

    public OrgController(OrgService orgService) {
        this.orgService = orgService;
    }

    @GetMapping
    public ResponseEntity<OrganizationDto> get(@CurrentUser AuthPrincipal me) {
        return ResponseEntity.ok(orgService.get(me.organizationId()));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @PatchMapping
    public ResponseEntity<OrganizationDto> update(@CurrentUser AuthPrincipal me, @RequestBody UpdateOrgRequest request) {
        return ResponseEntity.ok(orgService.update(me.organizationId(), request));
    }
}

'@
Write-File "src\main\java\com\visilog\api\controller\OrgController.java" $f10
$f11 = @'
package com.visilog.api.controller;

import com.visilog.api.dto.OfficeLocationDto;
import com.visilog.api.dto.OfficeLocationRequest;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.OfficeLocationService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/office-locations")
public class OfficeLocationController {

    private final OfficeLocationService officeLocationService;

    public OfficeLocationController(OfficeLocationService officeLocationService) {
        this.officeLocationService = officeLocationService;
    }

    // Every role can read the list -- the clock-in/visitor-check-in
    // geofence check (client-side, see locationCheck.ts) needs it
    // regardless of who's signed in, not just managers.
    @GetMapping
    public ResponseEntity<List<OfficeLocationDto>> list(@CurrentUser AuthPrincipal me) {
        return ResponseEntity.ok(officeLocationService.list(me.organizationId()));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @PostMapping
    public ResponseEntity<OfficeLocationDto> create(
            @CurrentUser AuthPrincipal me, @Valid @RequestBody OfficeLocationRequest request) {
        return ResponseEntity.ok(officeLocationService.create(me.organizationId(), request));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @PatchMapping("/{id}")
    public ResponseEntity<OfficeLocationDto> update(
            @CurrentUser AuthPrincipal me, @PathVariable UUID id,
            @Valid @RequestBody OfficeLocationRequest request) {
        return ResponseEntity.ok(officeLocationService.update(me.organizationId(), id, request));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@CurrentUser AuthPrincipal me, @PathVariable UUID id) {
        officeLocationService.delete(me.organizationId(), id);
        return ResponseEntity.noContent().build();
    }
}

'@
Write-File "src\main\java\com\visilog\api\controller\OfficeLocationController.java" $f11
$f12 = @'
package com.visilog.api.service;

import com.visilog.api.dto.AuthResponse;
import com.visilog.api.dto.ForgotPasswordRequest;
import com.visilog.api.dto.GoogleAuthRequest;
import com.visilog.api.dto.LoginRequest;
import com.visilog.api.dto.MessageResponse;
import com.visilog.api.dto.OrganizationDto;
import com.visilog.api.dto.RegisterCompanyRequest;
import com.visilog.api.dto.ResetPasswordRequest;
import com.visilog.api.dto.SignupRequest;
import com.visilog.api.dto.UserDto;
import com.visilog.api.entity.AppUser;
import com.visilog.api.entity.BillingStatus;
import com.visilog.api.entity.Employee;
import com.visilog.api.entity.OrgBilling;
import com.visilog.api.entity.Organization;
import com.visilog.api.entity.Role;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.AppUserRepository;
import com.visilog.api.repository.EmployeeRepository;
import com.visilog.api.repository.OrgBillingRepository;
import com.visilog.api.repository.OrganizationRepository;
import com.visilog.api.security.AuthPrincipal;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// The heart of the self-serve onboarding redesign:
//   1. registerCompany -- a company signs itself up, gets a unique code
//      and its first Administrator account, in one step.
//   2. signup -- a person joins an existing org with the company code +
//      their real email. Their role is decided HERE, once, by matching
//      that email against the org's Employee roster (Company Setup) --
//      a match inherits that employee's role; no match becomes a
//      Role.VISITOR. There is no free role-picker anywhere after this.
//   3. login -- an existing account's role is already fixed; just
//      verify the password and hand back a token.
@Service
public class AuthService {

    // VRA's own original green/gold shades -- applied as the default
    // theme for every newly registered org until the admin customizes
    // it in Company Setup, so a fresh org isn't visually blank.
    private static final String DEFAULT_BRAND = "#0F3D2A";
    private static final String DEFAULT_BRAND_DARK = "#0A2A1D";
    private static final String DEFAULT_BRAND_TINT = "#155636";
    private static final String DEFAULT_PRIMARY = "#C9A227";
    private static final String DEFAULT_PRIMARY_PRESSED = "#D4AF37";
    private static final String DEFAULT_PRIMARY_SURFACE = "#FBF3DE";
    private static final String DEFAULT_PRIMARY_SURFACE_STRONG = "#F5E6BC";

    private static final SecureRandom RANDOM = new SecureRandom();

    // Login lockout -- unlimited password guesses is a real risk on a
    // login form with no other rate-limit layer in front of it.
    private static final int MAX_LOGIN_ATTEMPTS = 5;
    private static final Duration LOCKOUT_DURATION = Duration.ofMinutes(15);

    // Generic response for forgotPassword regardless of whether the email
    // actually matched an account -- never confirm/deny account existence.
    private static final MessageResponse FORGOT_PASSWORD_RESPONSE = new MessageResponse(
            "If that email is registered, we've sent a password reset code to it.");

    private final OrganizationRepository organizationRepository;
    private final AppUserRepository appUserRepository;
    private final EmployeeRepository employeeRepository;
    private final OrgBillingRepository orgBillingRepository;
    private final PasswordEncoder passwordEncoder;
    private final com.visilog.api.security.JwtService jwtService;
    private final GoogleTokenService googleTokenService;
    private final MailService mailService;

    public AuthService(
            OrganizationRepository organizationRepository,
            AppUserRepository appUserRepository,
            EmployeeRepository employeeRepository,
            OrgBillingRepository orgBillingRepository,
            PasswordEncoder passwordEncoder,
            com.visilog.api.security.JwtService jwtService,
            GoogleTokenService googleTokenService,
            MailService mailService) {
        this.organizationRepository = organizationRepository;
        this.appUserRepository = appUserRepository;
        this.employeeRepository = employeeRepository;
        this.orgBillingRepository = orgBillingRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.googleTokenService = googleTokenService;
        this.mailService = mailService;
    }

    @Transactional
    public AuthResponse registerCompany(RegisterCompanyRequest req) {
        String email = req.adminEmail().trim().toLowerCase(Locale.ROOT);

        Organization org = new Organization();
        org.setCode(generateUniqueCompanyCode(req.companyName()));
        org.setName(req.companyName().trim());
        org.setBrand(DEFAULT_BRAND);
        org.setBrandDark(DEFAULT_BRAND_DARK);
        org.setBrandTint(DEFAULT_BRAND_TINT);
        org.setPrimary(DEFAULT_PRIMARY);
        org.setPrimaryPressed(DEFAULT_PRIMARY_PRESSED);
        org.setPrimarySurface(DEFAULT_PRIMARY_SURFACE);
        org.setPrimarySurfaceStrong(DEFAULT_PRIMARY_SURFACE_STRONG);
        org = organizationRepository.save(org);

        // The admin also appears in their own staff roster, as Manager --
        // consistent with how every other staff member joins: through
        // an Employee record with a role attached.
        Employee adminEmployee = new Employee();
        adminEmployee.setOrganizationId(org.getId());
        adminEmployee.setEmployeeCode(org.getCode() + "-1001");
        adminEmployee.setName(req.adminName().trim());
        adminEmployee.setEmail(email);
        adminEmployee.setDepartment("Administration");
        adminEmployee.setRole(Role.MANAGER);
        adminEmployee = employeeRepository.save(adminEmployee);

        AppUser user = new AppUser();
        user.setOrganizationId(org.getId());
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(req.adminPassword()));
        user.setName(req.adminName().trim());
        user.setRole(Role.MANAGER);
        user.setEmployeeId(adminEmployee.getId());
        user = appUserRepository.save(user);

        // The frontend only calls this endpoint after the admin has agreed
        // to the legal terms and gone through the (placeholder -- no real
        // payment processor in this build) subscription checkout, so by
        // the time we get here the company has already "paid" for a
        // minimum 2-year term -- reflected as ACTIVE with a ~730-day
        // renewal instead of the old 30-day trial.
        OrgBilling billing = new OrgBilling();
        billing.setOrganizationId(org.getId());
        billing.setPlanId("starter");
        billing.setStatus(BillingStatus.ACTIVE);
        billing.setSeatsUsed(1);
        billing.setRenewalDate(Instant.now().plus(730, ChronoUnit.DAYS));
        orgBillingRepository.save(billing);

        mailService.sendWelcomeEmail(user.getEmail(), user.getName(), org.getName());
        return buildAuthResponse(user, org);
    }

    @Transactional
    public AuthResponse signup(SignupRequest req) {
        Organization org = findOrgByCodeOrThrow(req.companyCode());
        String email = req.email().trim().toLowerCase(Locale.ROOT);

        if (appUserRepository.existsByOrganizationIdAndEmailIgnoreCase(org.getId(), email)) {
            throw ApiException.conflict("An account with this email already exists -- try logging in instead.");
        }

        // The whole point of this flow: role is resolved automatically
        // from the roster, never picked by the user.
        Optional<Employee> match = employeeRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), email);
        Role role = match.map(Employee::getRole).orElse(Role.VISITOR);

        AppUser user = new AppUser();
        user.setOrganizationId(org.getId());
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(req.password()));
        user.setName(req.name().trim());
        user.setRole(role);
        if (match.isPresent()) {
            user.setEmployeeId(match.get().getId());
        }
        user = appUserRepository.save(user);

        mailService.sendWelcomeEmail(user.getEmail(), user.getName(), org.getName());
        return buildAuthResponse(user, org);
    }

    // "Continue with Google" -- the frontend hands us the ID token it got
    // from Google's own sign-in flow, we verify it ourselves (see
    // GoogleTokenService) rather than trusting the client, then treat it
    // exactly like signup/login: an existing account for this email in
    // this org logs straight in, a new one gets created with a role
    // resolved from the staff roster same as a normal signup. There's no
    // real password on a Google-only account, so a random value neither
    // this account nor anyone else will ever know just satisfies the
    // column -- the only way in is a fresh Google check.
    @Transactional
    public AuthResponse googleAuth(GoogleAuthRequest req) {
        Organization org = findOrgByCodeOrThrow(req.companyCode());
        GoogleTokenService.GoogleUser googleUser = googleTokenService.verify(req.idToken());
        String email = googleUser.email().trim().toLowerCase(Locale.ROOT);

        Optional<AppUser> existing = appUserRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), email);
        if (existing.isPresent()) {
            return buildAuthResponse(existing.get(), org);
        }

        Optional<Employee> match = employeeRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), email);
        Role role = match.map(Employee::getRole).orElse(Role.VISITOR);

        AppUser user = new AppUser();
        user.setOrganizationId(org.getId());
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(randomUnusablePassword()));
        user.setName(googleUser.name());
        user.setRole(role);
        if (match.isPresent()) {
            user.setEmployeeId(match.get().getId());
        }
        user = appUserRepository.save(user);

        mailService.sendWelcomeEmail(user.getEmail(), user.getName(), org.getName());
        return buildAuthResponse(user, org);
    }

    // Forgot Password: a numeric code emailed to the account, entered
    // manually in-app alongside a new password. Chose a code over a
    // clickable/deep-link flow specifically to avoid repeating the
    // custom-URI-scheme restrictions that Google Sign-In ran into --
    // this needs zero app-scheme/redirect wiring at all.
    //
    // Always returns the same generic message whether or not the email
    // matched an account, so this endpoint can't be used to test which
    // emails have a VisiLog account.
    @Transactional
    public MessageResponse forgotPassword(ForgotPasswordRequest req) {
        Organization org = findOrgByCodeOrThrow(req.companyCode());
        String email = req.email().trim().toLowerCase(Locale.ROOT);

        appUserRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), email).ifPresent(user -> {
            String code = String.format("%06d", RANDOM.nextInt(1_000_000));
            user.setResetCode(code);
            user.setResetCodeExpiresAt(Instant.now().plus(15, ChronoUnit.MINUTES));
            appUserRepository.save(user);
            mailService.sendPasswordResetEmail(user.getEmail(), user.getName(), code);
        });

        return FORGOT_PASSWORD_RESPONSE;
    }

    @Transactional
    public MessageResponse resetPassword(ResetPasswordRequest req) {
        Organization org = findOrgByCodeOrThrow(req.companyCode());
        String email = req.email().trim().toLowerCase(Locale.ROOT);

        AppUser user = appUserRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), email)
                .orElseThrow(() -> ApiException.badRequest("That code is invalid or has expired."));

        if (user.getResetCode() == null || user.getResetCodeExpiresAt() == null
                || !user.getResetCode().equals(req.code().trim())
                || Instant.now().isAfter(user.getResetCodeExpiresAt())) {
            throw ApiException.badRequest("That code is invalid or has expired.");
        }

        user.setPasswordHash(passwordEncoder.encode(req.newPassword()));
        user.setResetCode(null);
        user.setResetCodeExpiresAt(null);
        appUserRepository.save(user);

        return new MessageResponse("Your password has been reset. You can now log in.");
    }

    @Transactional
    public AuthResponse login(LoginRequest req) {
        Organization org = findOrgByCodeOrThrow(req.companyCode());
        String email = req.email().trim().toLowerCase(Locale.ROOT);

        AppUser user = appUserRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), email)
                .orElseThrow(() -> ApiException.unauthorized("Incorrect email or password."));

        if (user.getLockedUntil() != null && Instant.now().isBefore(user.getLockedUntil())) {
            long minutesLeft = Math.max(1, Duration.between(Instant.now(), user.getLockedUntil()).toMinutes());
            throw ApiException.tooManyRequests(
                    "Too many failed attempts. Try again in " + minutesLeft
                            + (minutesLeft == 1 ? " minute." : " minutes."));
        }

        if (!passwordEncoder.matches(req.password(), user.getPasswordHash())) {
            user.setFailedLoginAttempts(user.getFailedLoginAttempts() + 1);
            if (user.getFailedLoginAttempts() >= MAX_LOGIN_ATTEMPTS) {
                user.setLockedUntil(Instant.now().plus(LOCKOUT_DURATION));
            }
            appUserRepository.save(user);
            throw ApiException.unauthorized("Incorrect email or password.");
        }

        user.setFailedLoginAttempts(0);
        user.setLockedUntil(null);
        appUserRepository.save(user);

        return buildAuthResponse(user, org);
    }

    public UserDto me(AuthPrincipal principal) {
        AppUser user = appUserRepository.findById(principal.userId())
                .orElseThrow(() -> ApiException.unauthorized("Session no longer valid."));
        Organization org = organizationRepository.findById(principal.organizationId())
                .orElseThrow(() -> ApiException.unauthorized("Session no longer valid."));
        return UserDto.from(user, org);
    }

    // Step-up confirmation for a sensitive action on an *already signed
    // in* session (currently: clocking in) -- re-checks the caller's own
    // password without issuing a new token. Doesn't stop someone who
    // genuinely knows a coworker's password, but blocks the far more
    // common case of clocking in from a phone someone else left signed
    // in and unattended.
    public void verifyPassword(AuthPrincipal principal, String password) {
        AppUser user = appUserRepository.findById(principal.userId())
                .orElseThrow(() -> ApiException.unauthorized("Session no longer valid."));
        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            throw ApiException.unauthorized("Incorrect password.");
        }
    }

    private Organization findOrgByCodeOrThrow(String code) {
        return organizationRepository.findByCode(code.trim().toUpperCase(Locale.ROOT))
                .orElseThrow(() -> ApiException.badRequest("Enter a valid company code."));
    }

    private AuthResponse buildAuthResponse(AppUser user, Organization org) {
        String token = jwtService.issueToken(
                user.getId(), org.getId(), user.getRole().name(), user.getEmail(), user.getEmployeeId());
        String planId = orgBillingRepository.findByOrganizationId(org.getId())
                .map(OrgBilling::getPlanId).orElse(null);
        return new AuthResponse(token, UserDto.from(user, org), OrganizationDto.from(org, planId));
    }

    private String randomUnusablePassword() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return java.util.Base64.getEncoder().encodeToString(bytes);
    }

    // "<NAMEPART><4 random digits>", e.g. "VRA2026"-shaped -- retried
    // until it doesn't collide (astronomically unlikely, but cheap to
    // guard against for a company code that gets printed on letters).
    private String generateUniqueCompanyCode(String companyName) {
        String base = companyName.toUpperCase(Locale.ROOT).replaceAll("[^A-Z0-9]", "");
        if (base.isEmpty()) {
            base = "VISILOG";
        }
        base = base.substring(0, Math.min(base.length(), 6));
        String code;
        do {
            code = base + (1000 + RANDOM.nextInt(9000));
        } while (organizationRepository.existsByCode(code));
        return code;
    }
}

'@
Write-File "src\main\java\com\visilog\api\service\AuthService.java" $f12

Write-Host "--- Files written, verifying ---"
$paths = @(
    "src\main\resources\db\migration\V20__priority_support_and_tour_map_features.sql",
    "src\main\java\db\migration\V21__MultipleOfficeLocations.java",
    "src\main\java\com\visilog\api\entity\Organization.java",
    "src\main\java\com\visilog\api\entity\OfficeLocation.java",
    "src\main\java\com\visilog\api\repository\OfficeLocationRepository.java",
    "src\main\java\com\visilog\api\dto\OfficeLocationDto.java",
    "src\main\java\com\visilog\api\dto\OfficeLocationRequest.java",
    "src\main\java\com\visilog\api\dto\OrganizationDto.java",
    "src\main\java\com\visilog\api\service\OrgService.java",
    "src\main\java\com\visilog\api\service\OfficeLocationService.java",
    "src\main\java\com\visilog\api\controller\OrgController.java",
    "src\main\java\com\visilog\api\controller\OfficeLocationController.java",
    "src\main\java\com\visilog\api\service\AuthService.java"
)
foreach ($p in $paths) {
    $full = Join-Path $PSScriptRoot $p
    if (Test-Path $full) { Write-Host "OK   $p" } else { Write-Host "MISSING   $p" }
}

Stop-Transcript | Out-Null
Write-Host ""
Write-Host "Done. Now run: .\mvnw.cmd -q clean test"
