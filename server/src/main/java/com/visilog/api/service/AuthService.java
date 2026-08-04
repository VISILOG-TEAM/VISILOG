package com.visilog.api.service;

import com.visilog.api.dto.AuthResponse;
import com.visilog.api.dto.ForgotPasswordRequest;
import com.visilog.api.dto.GoogleAuthRequest;
import com.visilog.api.dto.LoginRequest;
import com.visilog.api.dto.MessageResponse;
import com.visilog.api.dto.OrganizationDto;
import com.visilog.api.dto.RegisterCompanyRequest;
import com.visilog.api.dto.ResetPasswordRequest;
import com.visilog.api.dto.UpdateProfileRequest;
import com.visilog.api.dto.SignupRequest;
import com.visilog.api.dto.UserDto;
import com.visilog.api.dto.VerifyEmailRequest;
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
import java.util.List;
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

    // Longer than the 15-minute password-reset window on purpose: this
    // one is entered while someone is mid-signup and may be switching
    // apps to find the email on a phone that's asking them to log into
    // their mailbox first.
    private static final Duration VERIFICATION_CODE_TTL = Duration.ofMinutes(30);

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

        // The welcome email waits until the address is actually
        // confirmed (see verifyEmail) -- sending "welcome!" to an
        // address nobody has proved they own is how a typo'd signup
        // ends up mailing a stranger.
        sendVerificationCode(user);
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

        sendVerificationCode(user);
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
        // No verification step for a Google account: Google only issued
        // us that ID token because the person signed into that mailbox,
        // so mailing them a code to prove the same thing again would be
        // a pointless extra screen.
        user.setEmailVerified(true);
        if (match.isPresent()) {
            user.setEmployeeId(match.get().getId());
        }
        user = appUserRepository.save(user);

        return buildAuthResponse(user, org);
    }

    // Confirms the address an account signed up with. The account is
    // identified by its own token, not by anything in the body -- the
    // signup response already handed the client a (restricted) token,
    // so there's nothing to look up and nothing an attacker could aim
    // at somebody else's account.
    //
    // On success a *fresh* token is returned, because the old one has
    // verified=false baked into it (see JwtService) and would keep
    // being refused by JwtAuthFilter otherwise.
    @Transactional
    public AuthResponse verifyEmail(AuthPrincipal principal, VerifyEmailRequest req) {
        AppUser user = appUserRepository.findById(principal.userId())
                .orElseThrow(() -> ApiException.unauthorized("Session no longer valid."));
        Organization org = organizationRepository.findById(principal.organizationId())
                .orElseThrow(() -> ApiException.unauthorized("Session no longer valid."));

        // Already verified: hand back a good token rather than an error.
        // This is what a double-tap on "Verify" looks like, and failing
        // it would strand the caller on the verify screen holding a
        // stale unverified token.
        if (user.isEmailVerified()) {
            return buildAuthResponse(user, org);
        }

        if (user.getVerificationCode() == null || user.getVerificationCodeExpiresAt() == null
                || !user.getVerificationCode().equals(req.code().trim())
                || Instant.now().isAfter(user.getVerificationCodeExpiresAt())) {
            throw ApiException.badRequest(
                    "That code is incorrect or has expired. Tap \"Resend code\" to get a new one.");
        }

        user.setEmailVerified(true);
        user.setVerificationCode(null);
        user.setVerificationCodeExpiresAt(null);
        user = appUserRepository.save(user);

        mailService.sendWelcomeEmail(user.getEmail(), user.getName(), org.getName());
        return buildAuthResponse(user, org);
    }

    @Transactional
    public MessageResponse resendVerification(AuthPrincipal principal) {
        AppUser user = appUserRepository.findById(principal.userId())
                .orElseThrow(() -> ApiException.unauthorized("Session no longer valid."));
        if (user.isEmailVerified()) {
            return new MessageResponse("Your email address is already verified.");
        }
        sendVerificationCode(user);
        return new MessageResponse("We've sent a new code to " + user.getEmail() + ".");
    }

    // Issues a fresh code (replacing any outstanding one) and mails it.
    private void sendVerificationCode(AppUser user) {
        String code = String.format("%06d", RANDOM.nextInt(1_000_000));
        user.setVerificationCode(code);
        user.setVerificationCodeExpiresAt(Instant.now().plus(VERIFICATION_CODE_TTL));
        appUserRepository.save(user);
        mailService.sendVerificationEmail(user.getEmail(), user.getName(), code);
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

    // Settings > "Your profile" -- the caller renaming themselves. No
    // new token is issued: the JWT carries userId/org/role/email but not
    // the display name (see JwtService), so the existing session stays
    // valid and the frontend just refreshes its own copy of the user.
    // Only the display name is editable -- email is the login identity
    // and role comes from the staff roster at signup.
    @Transactional
    public UserDto updateProfile(AuthPrincipal principal, UpdateProfileRequest req) {
        AppUser user = appUserRepository.findById(principal.userId())
                .orElseThrow(() -> ApiException.unauthorized("Session no longer valid."));
        Organization org = organizationRepository.findById(principal.organizationId())
                .orElseThrow(() -> ApiException.unauthorized("Session no longer valid."));
        user.setName(req.name().trim());
        return UserDto.from(appUserRepository.save(user), org);
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

    // Resolves the tenant from whatever the person typed into the
    // "Company name" field on Login/Signup/Forgot password.
    //
    // Normalised exactly the way generateUniqueCompanyCode builds the
    // stored code -- uppercased, with spaces and punctuation stripped --
    // so someone who types their company's actual name gets a match:
    // "Acme Logistics", "acme logistics" and "ACMELOGISTICS" all resolve
    // to the same organization. Without this, the field would promise a
    // company name and then reject every name with a space in it.
    //
    // This is a superset of the old behaviour, so codes in the previous
    // format (ACMELO4821) still resolve exactly as before.
    private Organization findOrgByCodeOrThrow(String code) {
        String normalized = code.toUpperCase(Locale.ROOT).replaceAll("[^A-Z0-9]", "");
        return organizationRepository.findByCode(normalized)
                .orElseThrow(() -> ApiException.badRequest(
                        "We couldn't find a company with that name. Check the spelling, "
                        + "or ask your Administrator for your company's code."));
    }

    private AuthResponse buildAuthResponse(AppUser user, Organization org) {
        String token = jwtService.issueToken(
                user.getId(), org.getId(), user.getRole().name(), user.getEmail(), user.getEmployeeId(),
                user.isEmailVerified());
        String planId = orgBillingRepository.findByOrganizationId(org.getId())
                .map(OrgBilling::getPlanId).orElse(null);
        return new AuthResponse(token, UserDto.from(user, org), OrganizationDto.from(org, planId));
    }

    private String randomUnusablePassword() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return java.util.Base64.getEncoder().encodeToString(bytes);
    }

    // The company's own name, uppercased with spaces and punctuation
    // stripped: "Acme Logistics" -> ACMELOGISTICS. This code is what a
    // company's entire staff and every visitor types on the login
    // screen, and gets printed on letters and shared in messages, so
    // it should read as the company rather than as a serial number.
    // It used to be a 6-character truncation plus 4 random digits
    // ("ACMELO4821"), which was unique but meant nothing to anyone.
    //
    // A number is appended ONLY on a collision, and counts up from 2
    // (ACMELOGISTICS2) rather than being random -- two unrelated firms
    // really can share a name, and this code is the only thing that
    // resolves which tenant a login belongs to, so it must stay
    // globally unique.
    //
    // Capped at 20 characters. The binding constraint isn't the code
    // column (VARCHAR(32)) but the admin's roster entry created in
    // registerCompany as "<code>-1001", which lands in employee_code
    // -- also VARCHAR(32). 20 leaves room for both a collision suffix
    // and that "-1001", so a company with a very long name can still
    // register instead of failing on a truncation error.
    private String generateUniqueCompanyCode(String companyName) {
        String base = companyName.toUpperCase(Locale.ROOT).replaceAll("[^A-Z0-9]", "");
        if (base.isEmpty()) {
            base = "VISILOG";
        }
        base = base.substring(0, Math.min(base.length(), 20));

        if (!organizationRepository.existsByCode(base)) {
            return base;
        }
        for (int suffix = 2; suffix < 1000; suffix++) {
            String candidate = base + suffix;
            if (!organizationRepository.existsByCode(candidate)) {
                return candidate;
            }
        }
        // 999 companies sharing one name is not a real scenario, but
        // falling back beats looping forever.
        String code;
        do {
            code = base + (1000 + RANDOM.nextInt(9000));
        } while (organizationRepository.existsByCode(code));
        return code;
    }
}
