package com.visilog.api.service;

import com.visilog.api.dto.AuthResponse;
import com.visilog.api.dto.LoginRequest;
import com.visilog.api.dto.OrganizationDto;
import com.visilog.api.dto.RegisterCompanyRequest;
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
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// The heart of the self-serve onboarding redesign:
//   1. registerCompany — a company signs itself up, gets a unique code
//      and its first Administrator account, in one step.
//   2. signup — a person joins an existing org with the company code +
//      their real email. Their role is decided HERE, once, by matching
//      that email against the org's Employee roster (Company Setup) —
//      a match inherits that employee's role; no match becomes a
//      Role.VISITOR. There is no free role-picker anywhere after this.
//   3. login — an existing account's role is already fixed; just
//      verify the password and hand back a token.
@Service
public class AuthService {

    // VRA's own original green/gold shades — applied as the default
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

    private final OrganizationRepository organizationRepository;
    private final AppUserRepository appUserRepository;
    private final EmployeeRepository employeeRepository;
    private final OrgBillingRepository orgBillingRepository;
    private final PasswordEncoder passwordEncoder;
    private final com.visilog.api.security.JwtService jwtService;

    public AuthService(
            OrganizationRepository organizationRepository,
            AppUserRepository appUserRepository,
            EmployeeRepository employeeRepository,
            OrgBillingRepository orgBillingRepository,
            PasswordEncoder passwordEncoder,
            com.visilog.api.security.JwtService jwtService) {
        this.organizationRepository = organizationRepository;
        this.appUserRepository = appUserRepository;
        this.employeeRepository = employeeRepository;
        this.orgBillingRepository = orgBillingRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
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

        // The admin also appears in their own staff roster, as Manager —
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
        // to the legal terms and gone through the (placeholder — no real
        // payment processor in this build) subscription checkout, so by
        // the time we get here the company has already "paid" for a
        // minimum 2-year term — reflected as ACTIVE with a ~730-day
        // renewal instead of the old 30-day trial.
        OrgBilling billing = new OrgBilling();
        billing.setOrganizationId(org.getId());
        billing.setPlanId("starter");
        billing.setStatus(BillingStatus.ACTIVE);
        billing.setSeatsUsed(1);
        billing.setRenewalDate(Instant.now().plus(730, ChronoUnit.DAYS));
        orgBillingRepository.save(billing);

        return buildAuthResponse(user, org);
    }

    @Transactional
    public AuthResponse signup(SignupRequest req) {
        Organization org = findOrgByCodeOrThrow(req.companyCode());
        String email = req.email().trim().toLowerCase(Locale.ROOT);

        if (appUserRepository.existsByOrganizationIdAndEmailIgnoreCase(org.getId(), email)) {
            throw ApiException.conflict("An account with this email already exists — try logging in instead.");
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

        return buildAuthResponse(user, org);
    }

    public AuthResponse login(LoginRequest req) {
        Organization org = findOrgByCodeOrThrow(req.companyCode());
        String email = req.email().trim().toLowerCase(Locale.ROOT);

        AppUser user = appUserRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), email)
                .orElseThrow(() -> ApiException.unauthorized("Incorrect email or password."));

        if (!passwordEncoder.matches(req.password(), user.getPasswordHash())) {
            throw ApiException.unauthorized("Incorrect email or password.");
        }

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
    // in* session (currently: clocking in) — re-checks the caller's own
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
        return new AuthResponse(token, UserDto.from(user, org), OrganizationDto.from(org));
    }

    // "<NAMEPART><4 random digits>", e.g. "VRA2026"-shaped — retried
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
