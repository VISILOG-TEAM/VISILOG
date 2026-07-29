# VisiLog backend - email verification, profile rename, manager appointment visibility
# Generated for VisiLog. Run from the repository root.
$ErrorActionPreference = 'Stop'
$written = 0

$content = @'
-- Email verification at signup: a 6-digit code emailed to the address
-- the account was created with, entered in-app before the account can
-- do anything else.
--
-- Note the DEFAULT TRUE on the ADD, flipped to FALSE immediately
-- after: that backfills every account that already exists as verified.
-- Everyone currently using VisiLog signed up before this feature
-- existed and never had a chance to enter a code, so defaulting them
-- to unverified would lock every one of them out of their own app.
-- New rows created from here on get FALSE.
ALTER TABLE app_users ADD COLUMN email_verified BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE app_users ALTER COLUMN email_verified SET DEFAULT FALSE;

ALTER TABLE app_users ADD COLUMN verification_code VARCHAR(10);
ALTER TABLE app_users ADD COLUMN verification_code_expires_at TIMESTAMP;

'@
$path = Join-Path (Get-Location) 'server\src\main\resources\db\migration\V22__email_verification.sql'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/main/resources/db/migration/V22__email_verification.sql'
$written = $written + 1

$content = @'
package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// A login account. Role is fixed at creation (see AuthService) -- never
// user-chosen. employeeId is set only when this account was matched to
// a roster entry at signup (i.e. role != VISITOR).
@Entity
@Table(name = "app_users", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"organization_id", "email"})
})
@Getter
@Setter
@NoArgsConstructor
public class AppUser {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    @Column(nullable = false)
    private String email;

    @Column(nullable = false)
    private String passwordHash;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private Role role;

    private UUID employeeId;

    // Set only while a Forgot Password reset is in flight -- cleared as
    // soon as it's used (or replaced by a fresh request). Never exposed
    // in any DTO.
    private String resetCode;
    private Instant resetCodeExpiresAt;

    // Email verification. False until the account owner enters the
    // 6-digit code we emailed them at signup; until then the JWT carries
    // verified=false and JwtAuthFilter refuses everything except the
    // handful of endpoints the verify screen itself needs. Accounts that
    // predate this feature were backfilled as true (see V22) -- and
    // Google accounts are created as true, since Google has already
    // proved the person controls that mailbox.
    @Column(nullable = false)
    private boolean emailVerified = false;

    private String verificationCode;
    private Instant verificationCodeExpiresAt;

    // Login lockout -- resets to 0 on any successful login. Once it
    // hits AuthService.MAX_LOGIN_ATTEMPTS, lockedUntil is set and
    // login() rejects attempts (even with the right password) until
    // that time passes.
    @Column(nullable = false)
    private int failedLoginAttempts = 0;
    private Instant lockedUntil;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();
}

'@
$path = Join-Path (Get-Location) 'server\src\main\java\com\visilog\api\entity\AppUser.java'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/main/java/com/visilog/api/entity/AppUser.java'
$written = $written + 1

$content = @'
package com.visilog.api.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.util.Date;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

// HS256 JWT issuing/parsing. Claims: sub=userId, org=organizationId,
// role, email, employeeId (null for visitors), verified (email
// verification state). Kept deliberately simple (one shared secret,
// one service) -- no need for the old multi-service
// internal-API-key dance now that this is a monolith.
//
// `verified` lives in the token rather than being re-read from the
// database on every request: it's signed, so a client can't flip it,
// and it costs nothing per request. The trade-off is that it only
// changes when a new token is issued -- which is exactly what
// AuthService.verifyEmail() does on success.
@Service
public class JwtService {

    private final SecretKey signingKey;
    private final long expirationMs;

    public JwtService(
            @Value("${visilog.jwt.secret}") String secret,
            @Value("${visilog.jwt.expiration-ms}") long expirationMs) {
        this.signingKey = Keys.hmacShaKeyFor(secret.getBytes());
        this.expirationMs = expirationMs;
    }

    public String issueToken(
            UUID userId, UUID organizationId, String role, String email, UUID employeeId, boolean emailVerified) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + expirationMs);
        var builder = Jwts.builder()
                .subject(userId.toString())
                .claim("org", organizationId.toString())
                .claim("role", role)
                .claim("email", email)
                .claim("verified", emailVerified)
                .issuedAt(now)
                .expiration(expiry);
        if (employeeId != null) {
            builder.claim("employeeId", employeeId.toString());
        }
        return builder.signWith(signingKey).compact();
    }

    public Claims parse(String token) {
        return Jwts.parser()
                .verifyWith(signingKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}

'@
$path = Join-Path (Get-Location) 'server\src\main\java\com\visilog\api\security\JwtService.java'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/main/java/com/visilog/api/security/JwtService.java'
$written = $written + 1

$content = @'
package com.visilog.api.security;

import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

// Reads "Authorization: Bearer <token>", validates it, and populates
// the SecurityContext with an AuthPrincipal + a single ROLE_<role>
// authority so @PreAuthorize("hasRole('MANAGER')") works on admin-only
// endpoints. Requests with no/invalid token simply proceed
// unauthenticated -- SecurityConfig decides what that's allowed to reach.
public class JwtAuthFilter extends OncePerRequestFilter {

    // The only endpoints an account with an unverified email may reach.
    // Everything else is refused here rather than in each controller, so
    // a new endpoint is gated by default instead of by remembering to
    // gate it: /auth/me and GET /org are what the app needs to render
    // the verify screen at all, and the other two are the verify step
    // itself. (POST/PATCH /org -- Company Setup branding -- is NOT in
    // this set; only the GET is allowed through, see below.)
    private static final Set<String> UNVERIFIED_ALLOWED_PATHS = Set.of(
            "/api/v1/auth/me",
            "/api/v1/auth/verify-email",
            "/api/v1/auth/resend-verification");

    private static final String ORG_PATH = "/api/v1/org";

    private final JwtService jwtService;

    public JwtAuthFilter(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            try {
                var claims = jwtService.parse(header.substring(7));
                String employeeIdClaim = claims.get("employeeId", String.class);
                var principal = new AuthPrincipal(
                        UUID.fromString(claims.getSubject()),
                        UUID.fromString(claims.get("org", String.class)),
                        claims.get("role", String.class),
                        claims.get("email", String.class),
                        employeeIdClaim == null ? null : UUID.fromString(employeeIdClaim));
                var authorities = List.of(new SimpleGrantedAuthority("ROLE_" + principal.role()));
                var authentication = new UsernamePasswordAuthenticationToken(principal, null, authorities);
                SecurityContextHolder.getContext().setAuthentication(authentication);

                if (!isEmailVerified(claims) && !isAllowedWhileUnverified(request)) {
                    response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    response.setContentType("application/json");
                    response.getWriter().write(
                            "{\"error\":\"EMAIL_NOT_VERIFIED\","
                            + "\"message\":\"Verify your email address to finish setting up your account.\"}");
                    return;
                }
            } catch (JwtException | IllegalArgumentException ex) {
                SecurityContextHolder.clearContext();
            }
        }
        filterChain.doFilter(request, response);
    }

    // Tokens issued before email verification existed carry no `verified`
    // claim at all. Those are treated as verified -- the accounts behind
    // them were backfilled as verified too (see migration V22), so this
    // matches, and it means nobody signed in right now gets kicked into
    // a verify screen for an email they were never asked to confirm.
    private boolean isEmailVerified(io.jsonwebtoken.Claims claims) {
        Boolean verified = claims.get("verified", Boolean.class);
        return verified == null || verified;
    }

    private boolean isAllowedWhileUnverified(HttpServletRequest request) {
        String path = request.getRequestURI();
        if (UNVERIFIED_ALLOWED_PATHS.contains(path)) {
            return true;
        }
        // Reading the org is needed to theme the verify screen with the
        // company's own colors and to show a manager their company code;
        // changing it is not.
        return ORG_PATH.equals(path) && "GET".equalsIgnoreCase(request.getMethod());
    }
}

'@
$path = Join-Path (Get-Location) 'server\src\main\java\com\visilog\api\security\JwtAuthFilter.java'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/main/java/com/visilog/api/security/JwtAuthFilter.java'
$written = $written + 1

$content = @'
package com.visilog.api.dto;

import com.visilog.api.entity.AppUser;
import com.visilog.api.entity.Organization;
import java.util.UUID;

public record UserDto(
        UUID id,
        String email,
        String name,
        String role,
        UUID employeeId,
        UUID organizationId,
        String organizationName,
        boolean emailVerified
) {
    public static UserDto from(AppUser user, Organization org) {
        return new UserDto(
                user.getId(), user.getEmail(), user.getName(), user.getRole().name(),
                user.getEmployeeId(), org.getId(), org.getName(), user.isEmailVerified());
    }
}

'@
$path = Join-Path (Get-Location) 'server\src\main\java\com\visilog\api\dto\UserDto.java'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/main/java/com/visilog/api/dto/UserDto.java'
$written = $written + 1

$content = @'
package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// The 6-digit code from the verification email. Which account it
// belongs to comes from the caller's own token, never the body.
public record VerifyEmailRequest(
        @NotBlank @Size(max = 10) String code
) {}

'@
$path = Join-Path (Get-Location) 'server\src\main\java\com\visilog\api\dto\VerifyEmailRequest.java'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/main/java/com/visilog/api/dto/VerifyEmailRequest.java'
$written = $written + 1

$content = @'
package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// Settings > "Your profile": the signed-in user editing their own
// display name. Deliberately does NOT carry email or role -- email is
// the login identity and role is fixed at signup from the staff roster
// (see AuthService.signup), so neither is user-editable here.
public record UpdateProfileRequest(
        @NotBlank @Size(max = 120) String name
) {
}

'@
$path = Join-Path (Get-Location) 'server\src\main\java\com\visilog\api\dto\UpdateProfileRequest.java'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/main/java/com/visilog/api/dto/UpdateProfileRequest.java'
$written = $written + 1

$content = @'
package com.visilog.api.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

// Sends transactional email (welcome, password reset, meeting invites
// to outside guests) via Resend's HTTP API rather than raw SMTP --
// Render's free tier blocks outbound traffic to SMTP ports (25/465/587)
// entirely, which is what silently broke Gmail SMTP delivery in
// production. Resend sends over plain HTTPS, so it isn't affected by
// that restriction. Until RESEND_API_KEY is set, sending is a silent
// no-op (logged, not thrown) so nothing else ever fails just because
// mail isn't configured yet.
@Service
public class MailService {

    private static final Logger log = LoggerFactory.getLogger(MailService.class);
    private static final URI RESEND_ENDPOINT = URI.create("https://api.resend.com/emails");
    private static final Duration TIMEOUT = Duration.ofSeconds(10);

    private final HttpClient httpClient = HttpClient.newBuilder().connectTimeout(TIMEOUT).build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${visilog.resend.api-key:}")
    private String apiKey;

    @Value("${visilog.resend.from:VisiLog <onboarding@resend.dev>}")
    private String fromAddress;

    public void sendMeetingInvite(
            String toEmail, String guestName, String organiserName, String companyName, String companyCode,
            String title, String when, String placeLabel) {
        String subject = organiserName + " invited you to \"" + title + "\" on VisiLog";
        String body =
                "Hi " + (guestName == null || guestName.isBlank() ? "there" : guestName) + ",\n\n"
                + organiserName + " has invited you to a meeting:\n\n"
                + "  " + title + "\n"
                + "  " + when + "\n"
                + (placeLabel != null && !placeLabel.isBlank() ? "  " + placeLabel + "\n" : "")
                + "\nTo see the details and check in when you arrive, download the VisiLog app and "
                + "sign up with " + companyName + "'s company code: " + companyCode + "\n\n"
                + "-- VisiLog";
        send(toEmail, subject, body, "meeting invite");
    }

    public void sendPasswordResetEmail(String toEmail, String name, String code) {
        String subject = "Your VisiLog password reset code";
        String body =
                "Hi " + (name == null || name.isBlank() ? "there" : name) + ",\n\n"
                + "Here's your VisiLog password reset code:\n\n"
                + "  " + code + "\n\n"
                + "Enter this in the app to choose a new password. It expires in 15 minutes.\n\n"
                + "If you didn't ask to reset your password, you can ignore this email.\n\n"
                + "-- VisiLog";
        send(toEmail, subject, body, "password reset");
    }

    public void sendVerificationEmail(String toEmail, String name, String code) {
        String subject = "Your VisiLog verification code";
        String body =
                "Hi " + (name == null || name.isBlank() ? "there" : name) + ",\n\n"
                + "Here's the code to confirm your email address and finish setting up your "
                + "VisiLog account:\n\n"
                + "  " + code + "\n\n"
                + "Enter this in the app. It expires in 30 minutes -- if it runs out, tap "
                + "\"Resend code\" for a new one.\n\n"
                + "If you didn't sign up for VisiLog, you can ignore this email.\n\n"
                + "-- VisiLog";
        send(toEmail, subject, body, "email verification");
    }

    public void sendWelcomeEmail(String toEmail, String name, String companyName) {
        String subject = "Welcome to VisiLog";
        String body =
                "Hi " + (name == null || name.isBlank() ? "there" : name) + ",\n\n"
                + "Welcome to VisiLog! Your account with " + companyName + " is ready to go.\n\n"
                + "You can now check in visitors, book meetings, and clock in right from the app.\n\n"
                + "-- VisiLog";
        send(toEmail, subject, body, "welcome");
    }

    private void send(String toEmail, String subject, String textBody, String kind) {
        if (apiKey == null || apiKey.isBlank()) {
            log.info("Mail not configured -- skipping {} email to {}", kind, toEmail);
            return;
        }
        try {
            String json = objectMapper.writeValueAsString(Map.of(
                    "from", fromAddress,
                    "to", List.of(toEmail),
                    "subject", subject,
                    "text", textBody));
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(RESEND_ENDPOINT)
                    .timeout(TIMEOUT)
                    .header("Authorization", "Bearer " + apiKey)
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(json))
                    .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() >= 400) {
                log.warn("Could not send {} email to {}: Resend returned {} - {}",
                        kind, toEmail, response.statusCode(), response.body());
            }
        } catch (Exception ex) {
            log.warn("Could not send {} email to {}: {}", kind, toEmail, ex.getMessage());
        }
    }
}

'@
$path = Join-Path (Get-Location) 'server\src\main\java\com\visilog\api\service\MailService.java'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/main/java/com/visilog/api/service/MailService.java'
$written = $written + 1

$content = @'
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

        mailService.sendWelcomeEmail(user.getEmail(), user.getName(), org.getName());
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

    private Organization findOrgByCodeOrThrow(String code) {
        return organizationRepository.findByCode(code.trim().toUpperCase(Locale.ROOT))
                .orElseThrow(() -> ApiException.badRequest("Enter a valid company code."));
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
$path = Join-Path (Get-Location) 'server\src\main\java\com\visilog\api\service\AuthService.java'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/main/java/com/visilog/api/service/AuthService.java'
$written = $written + 1

$content = @'
package com.visilog.api.service;

import com.visilog.api.dto.AppointmentDto;
import com.visilog.api.dto.BookAppointmentRequest;
import com.visilog.api.dto.RescheduleRequest;
import com.visilog.api.dto.UpdateAppointmentStatusRequest;
import com.visilog.api.entity.Appointment;
import com.visilog.api.entity.AppointmentStatus;
import com.visilog.api.entity.Employee;
import com.visilog.api.entity.RoomBooking;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.AppointmentRepository;
import com.visilog.api.repository.EmployeeRepository;
import com.visilog.api.repository.RoomBookingRepository;
import com.visilog.api.security.AuthPrincipal;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AppointmentService {

    // Same assumed-visit-length window RoomBookingService uses for the
    // reverse check -- a visit has no stored duration, only a scheduledAt
    // instant, so this is how long it's assumed to occupy the host.
    private static final Duration ASSUMED_APPOINTMENT_DURATION = Duration.ofMinutes(30);

    private final AppointmentRepository appointmentRepository;
    private final VisitorService visitorService;
    private final RoomBookingRepository roomBookingRepository;
    private final EmployeeRepository employeeRepository;
    private final NotificationService notificationService;

    public AppointmentService(
            AppointmentRepository appointmentRepository, VisitorService visitorService,
            RoomBookingRepository roomBookingRepository, EmployeeRepository employeeRepository,
            NotificationService notificationService) {
        this.appointmentRepository = appointmentRepository;
        this.visitorService = visitorService;
        this.roomBookingRepository = roomBookingRepository;
        this.employeeRepository = employeeRepository;
        this.notificationService = notificationService;
    }

    // Reception sees every appointment in the org -- that's the front-desk
    // job, greeting whoever walks in regardless of host. Employees and
    // Managers only see appointments where *they* are the host: an
    // Administrator is staff too, and neither role should be able to see,
    // let alone admit or reject, a visit that isn't theirs to answer for.
    // Receptionists and Managers see every appointment in the org;
    // Employees see only the ones they're hosting.
    //
    // Managers used to be filtered down to their own hosted visits like
    // an Employee, which meant the person responsible for the whole
    // organization couldn't see what anyone else had booked. They're
    // the Administrator role (same one that owns Company Setup, the
    // staff roster and billing), so org-wide visibility is the point.
    public List<AppointmentDto> list(UUID organizationId, AuthPrincipal me) {
        List<Appointment> all = appointmentRepository.findByOrganizationIdOrderByScheduledAtDesc(organizationId);
        if ("EMPLOYEE".equals(me.role()) && me.employeeId() != null) {
            all = all.stream().filter(a -> me.employeeId().equals(a.getHostId())).toList();
        }
        return all.stream().map(AppointmentDto::from).toList();
    }

    public List<AppointmentDto> listForVisitor(UUID organizationId, String email) {
        return appointmentRepository
                .findByOrganizationIdAndBookedByEmailIgnoreCaseOrderByScheduledAtDesc(organizationId, email).stream()
                .map(AppointmentDto::from)
                .toList();
    }

    public AppointmentDto findByCode(UUID organizationId, String code) {
        Appointment a = appointmentRepository.findByOrganizationIdAndNfcCodeIgnoreCase(organizationId, code)
                .orElseThrow(() -> ApiException.notFound("No booking matches that code."));
        return AppointmentDto.from(a);
    }

    @Transactional
    public AppointmentDto book(UUID organizationId, BookAppointmentRequest req, String bookedByEmail) {
        Instant scheduledAt = req.scheduledAt() != null ? req.scheduledAt() : Instant.now();
        checkHostAvailability(organizationId, req.hostId(), scheduledAt);

        Appointment a = new Appointment();
        a.setOrganizationId(organizationId);
        a.setVisitorName(req.visitorName().trim());
        a.setVisitorPhone(req.visitorPhone().trim());
        a.setVisitorEmail(req.visitorEmail());
        a.setVisitorCompany(req.visitorCompany());
        a.setPurpose(req.purpose());
        a.setHostId(req.hostId());
        a.setScheduledAt(scheduledAt);
        a.setStatus(AppointmentStatus.PENDING);
        a.setBookedByEmail(bookedByEmail);
        Appointment saved = appointmentRepository.save(a);
        notificationService.notifyAppointmentRequested(saved);
        return AppointmentDto.from(saved);
    }

    // The reverse of RoomBookingService's clash check: booking a visit
    // with a host who's already in a meeting, or already has another
    // visit, around that time went through silently before -- this is
    // what the user hit when a visitor booked with someone mid-meeting.
    private void checkHostAvailability(UUID organizationId, UUID hostId, Instant scheduledAt) {
        Instant windowStart = scheduledAt.minus(ASSUMED_APPOINTMENT_DURATION);
        Instant windowEnd = scheduledAt.plus(ASSUMED_APPOINTMENT_DURATION);

        List<RoomBooking> meetingClashes = roomBookingRepository.findOverlappingForPerson(
                organizationId, hostId, scheduledAt, windowEnd);
        if (!meetingClashes.isEmpty()) {
            throw ApiException.conflict(hostName(organizationId, hostId)
                    + " is in a meeting around that time -- try a different time.");
        }

        List<Appointment> appointmentClashes = appointmentRepository
                .findByOrganizationIdAndHostIdAndScheduledAtBetweenAndStatusNot(
                        organizationId, hostId, windowStart, windowEnd, AppointmentStatus.REJECTED);
        if (!appointmentClashes.isEmpty()) {
            throw ApiException.conflict(hostName(organizationId, hostId)
                    + " already has another visit booked around that time.");
        }
    }

    private String hostName(UUID organizationId, UUID hostId) {
        return employeeRepository.findByOrganizationIdAndId(organizationId, hostId)
                .map(Employee::getName)
                .orElse("This host");
    }

    @Transactional
    public AppointmentDto updateStatus(UUID organizationId, UUID appointmentId, UpdateAppointmentStatusRequest req, AuthPrincipal me) {
        Appointment a = findOrThrow(organizationId, appointmentId);
        requireHost(a, me);
        AppointmentStatus status = parseStatus(req.status());
        if (status == AppointmentStatus.REJECTED) {
            if (req.reason() == null || req.reason().trim().isEmpty()) {
                throw ApiException.badRequest("Please give a reason for rejecting this visit.");
            }
            a.setRejectReason(req.reason().trim());
        }
        a.setStatus(status);
        Appointment saved = appointmentRepository.save(a);
        if (status == AppointmentStatus.REJECTED) {
            notificationService.notifyAppointmentDecision(saved, false);
        }
        return AppointmentDto.from(saved);
    }

    // Admitting = approve the pending request AND check the visitor in,
    // in one step, so reception doesn't repeat the visitor's details.
    // Only valid from PENDING -- without this guard, a double-tap (or a
    // retry after a slow response) created a brand new Visitor check-in
    // record every single time it was called, with no limit.
    @Transactional
    public AppointmentDto admit(UUID organizationId, UUID appointmentId, AuthPrincipal me) {
        Appointment a = findOrThrow(organizationId, appointmentId);
        requireHost(a, me);
        if (a.getStatus() != AppointmentStatus.PENDING) {
            throw ApiException.conflict("This appointment has already been " + a.getStatus().name().toLowerCase(Locale.ROOT) + ".");
        }
        a.setStatus(AppointmentStatus.ADMITTED);
        a.setNfcCode(uniqueNfcCode(organizationId));
        appointmentRepository.save(a);
        notificationService.notifyAppointmentDecision(a, true);

        String[] parts = (a.getVisitorName() == null ? "" : a.getVisitorName()).trim().split(" ", 2);
        String firstName = parts.length > 0 ? parts[0] : "";
        String lastName = parts.length > 1 ? parts[1] : "";
        visitorService.registerAndCheckInInternal(
                organizationId, firstName, lastName, a.getVisitorPhone(), a.getVisitorEmail(), a.getVisitorCompany(),
                a.getPurpose(), a.getHostId());

        return AppointmentDto.from(a);
    }

    @Transactional
    public AppointmentDto reschedule(UUID organizationId, UUID appointmentId, RescheduleRequest req) {
        Appointment a = findOrThrow(organizationId, appointmentId);
        a.setScheduledAt(req.newScheduledAt());
        a.setRescheduleReason(req.reason());
        a.setRescheduledAt(Instant.now());
        Appointment saved = appointmentRepository.save(a);
        notificationService.notifyAppointmentRescheduled(saved);
        return AppointmentDto.from(saved);
    }

    // No role is exempt: reception can see every appointment (for status
    // tracking -- "has this been admitted or rejected yet") but, like
    // everyone else, may only admit or reject one where they are the
    // actual host. Nobody acts on a visit that isn't theirs to answer for.
    private void requireHost(Appointment a, AuthPrincipal me) {
        if (me.employeeId() == null || !me.employeeId().equals(a.getHostId())) {
            throw ApiException.forbidden("Only the host this visit is for can admit or reject it.");
        }
    }

    private Appointment findOrThrow(UUID organizationId, UUID appointmentId) {
        return appointmentRepository.findByOrganizationIdAndId(organizationId, appointmentId)
                .orElseThrow(() -> ApiException.notFound("Appointment not found."));
    }

    private AppointmentStatus parseStatus(String raw) {
        try {
            return AppointmentStatus.valueOf(raw.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException ex) {
            throw ApiException.badRequest("status must be one of: pending, admitted, rejected.");
        }
    }

    private String uniqueNfcCode(UUID organizationId) {
        String code;
        do {
            code = CodeGenerator.generateVisitorCode();
        } while (appointmentRepository.findByOrganizationIdAndNfcCodeIgnoreCase(organizationId, code).isPresent());
        return code;
    }
}

'@
$path = Join-Path (Get-Location) 'server\src\main\java\com\visilog\api\service\AppointmentService.java'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/main/java/com/visilog/api/service/AppointmentService.java'
$written = $written + 1

$content = @'
package com.visilog.api.controller;

import com.visilog.api.dto.AuthResponse;
import com.visilog.api.dto.ForgotPasswordRequest;
import com.visilog.api.dto.GoogleAuthRequest;
import com.visilog.api.dto.LoginRequest;
import com.visilog.api.dto.MessageResponse;
import com.visilog.api.dto.ResetPasswordRequest;
import com.visilog.api.dto.SignupRequest;
import com.visilog.api.dto.UpdateProfileRequest;
import com.visilog.api.dto.UserDto;
import com.visilog.api.dto.VerifyEmailRequest;
import com.visilog.api.dto.VerifyPasswordRequest;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/signup")
    public ResponseEntity<AuthResponse> signup(@Valid @RequestBody SignupRequest request) {
        return ResponseEntity.ok(authService.signup(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/google")
    public ResponseEntity<AuthResponse> google(@Valid @RequestBody GoogleAuthRequest request) {
        return ResponseEntity.ok(authService.googleAuth(request));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<MessageResponse> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        return ResponseEntity.ok(authService.forgotPassword(request));
    }

    @PostMapping("/reset-password")
    public ResponseEntity<MessageResponse> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        return ResponseEntity.ok(authService.resetPassword(request));
    }

    // Email verification. Both need a token (the caller identifies
    // themselves with it) but are reachable while that token still says
    // verified=false -- see JwtAuthFilter's allow-list, which is exactly
    // these two plus /me and GET /org.
    //
    // verify-email returns a full AuthResponse, not just the user: the
    // token the client is holding says unverified, so it has to be
    // replaced with the fresh one in this response.
    @PostMapping("/verify-email")
    public ResponseEntity<AuthResponse> verifyEmail(
            @CurrentUser AuthPrincipal principal, @Valid @RequestBody VerifyEmailRequest request) {
        return ResponseEntity.ok(authService.verifyEmail(principal, request));
    }

    @PostMapping("/resend-verification")
    public ResponseEntity<MessageResponse> resendVerification(@CurrentUser AuthPrincipal principal) {
        return ResponseEntity.ok(authService.resendVerification(principal));
    }

    @GetMapping("/me")
    public ResponseEntity<UserDto> me(@CurrentUser AuthPrincipal principal) {
        return ResponseEntity.ok(authService.me(principal));
    }

    // Settings > "Your profile". No role check: every signed-in user may
    // rename themselves, and the target is always the caller's own
    // record (taken from the JWT, never from the request body).
    @PatchMapping("/me")
    public ResponseEntity<UserDto> updateProfile(
            @CurrentUser AuthPrincipal principal, @Valid @RequestBody UpdateProfileRequest request) {
        return ResponseEntity.ok(authService.updateProfile(principal, request));
    }

    // Step-up re-authentication for a sensitive action on the current
    // session (see ClockCard on the frontend) -- throws (401) on a wrong
    // password rather than returning an ok/not-ok body, same as login.
    @PostMapping("/verify-password")
    public ResponseEntity<Void> verifyPassword(
            @CurrentUser AuthPrincipal principal, @Valid @RequestBody VerifyPasswordRequest request) {
        authService.verifyPassword(principal, request.password());
        return ResponseEntity.noContent().build();
    }
}

'@
$path = Join-Path (Get-Location) 'server\src\main\java\com\visilog\api\controller\AuthController.java'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/main/java/com/visilog/api/controller/AuthController.java'
$written = $written + 1

$content = @'
package com.visilog.api;

import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.jayway.jsonpath.JsonPath;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

// Drives the real end-to-end story this whole rebuild exists for:
// a company signs itself up, the admin adds staff with roles, and a
// person's role is decided automatically by matching their email at
// signup -- no free role-picker anywhere in the flow.
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OnboardingFlowIntegrationTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private com.visilog.api.repository.AppUserRepository appUserRepository;

    @Test
    void selfServeCompanySignupThenStaffAndVisitorSignupResolveRolesAutomatically() throws Exception {
        // 1. Company signs itself up -- one call gets an org + admin account + company code.
        var registerBody = Map.of(
                "companyName", "Acme Logistics",
                "adminName", "Ama Owusu",
                "adminEmail", "ama@acmelogistics.com",
                "adminPassword", "adminpass123"
        );
        String registerResponse = mockMvc.perform(post("/api/v1/companies/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.role", is("MANAGER")))
                .andReturn().getResponse().getContentAsString();

        String adminToken = JsonPath.read(registerResponse, "$.token");
        String companyCode = JsonPath.read(registerResponse, "$.organization.code");
        String orgId = JsonPath.read(registerResponse, "$.user.organizationId");

        // 1b. A brand-new account's email isn't verified yet, and the token
        //     it was handed refuses everything but the verify step.
        mockMvc.perform(get("/api/v1/employees").header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isForbidden());

        // 1c. A wrong code is rejected...
        mockMvc.perform(post("/api/v1/auth/verify-email")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("code", "000000"))))
                .andExpect(status().isBadRequest());

        // ...and the real one (read straight from the row, standing in for
        // the email the admin would actually receive) unlocks the account
        // and hands back a replacement token that is no longer restricted.
        String verifyResponse = mockMvc.perform(post("/api/v1/auth/verify-email")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("code", verificationCodeFor(orgId, "ama@acmelogistics.com")))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.emailVerified", is(true)))
                .andReturn().getResponse().getContentAsString();
        adminToken = JsonPath.read(verifyResponse, "$.token");

        // 2. The admin adds a receptionist to the roster in Company Setup.
        var employeeBody = Map.of(
                "employeeCode", companyCode + "-2001",
                "name", "Wendy Abagna",
                "department", "Reception",
                "email", "wendy@acmelogistics.com",
                "role", "RECEPTIONIST"
        );
        mockMvc.perform(post("/api/v1/employees")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(employeeBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role", is("RECEPTIONIST")));

        // 3. Wendy signs up with the company code + her real email -- gets
        //    RECEPTIONIST automatically, no role-picker.
        var wendySignup = Map.of(
                "companyCode", companyCode,
                "email", "wendy@acmelogistics.com",
                "password", "wendyspass123",
                "name", "Wendy Abagna"
        );
        mockMvc.perform(post("/api/v1/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(wendySignup)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.role", is("RECEPTIONIST")))
                .andExpect(jsonPath("$.user.employeeId").exists());

        // 4. A stranger signs up with the same company code but an email
        //    that isn't on the roster -- becomes a visitor automatically.
        var strangerSignup = Map.of(
                "companyCode", companyCode,
                "email", "visitor1@example.com",
                "password", "visitorpass123",
                "name", "Selasi Akoto"
        );
        mockMvc.perform(post("/api/v1/auth/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(strangerSignup)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.role", is("VISITOR")))
                .andExpect(jsonPath("$.user.employeeId").doesNotExist());

        // 5. Wendy logs back in later -- her role is already fixed.
        var wendyLogin = Map.of("companyCode", companyCode, "email", "wendy@acmelogistics.com", "password", "wendyspass123");
        String loginResponse = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(wendyLogin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.role", is("RECEPTIONIST")))
                .andReturn().getResponse().getContentAsString();
        String wendyToken = JsonPath.read(loginResponse, "$.token");

        // 5b. Wendy confirms her email too, so step 7 below is genuinely
        //     testing the manager-only role check rather than just
        //     tripping over the unverified gate.
        String wendyVerify = mockMvc.perform(post("/api/v1/auth/verify-email")
                        .header("Authorization", "Bearer " + wendyToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("code", verificationCodeFor(orgId, "wendy@acmelogistics.com")))))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        wendyToken = JsonPath.read(wendyVerify, "$.token");

        // 6. /auth/me reflects the same fixed role.
        mockMvc.perform(get("/api/v1/auth/me").header("Authorization", "Bearer " + wendyToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.role", is("RECEPTIONIST")));

        // 7. A non-manager cannot manage the staff roster.
        mockMvc.perform(post("/api/v1/employees")
                        .header("Authorization", "Bearer " + wendyToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "employeeCode", "X-1", "name", "X", "email", "x@acmelogistics.com", "role", "EMPLOYEE"))))
                .andExpect(status().isForbidden());

        // 8. An unknown company code is rejected on login.
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "companyCode", "NOPE0000", "email", "wendy@acmelogistics.com", "password", "wendyspass123"))))
                .andExpect(status().isBadRequest());

        // 9. A request with no token at all is rejected.
        mockMvc.perform(get("/api/v1/auth/me"))
                .andExpect(status().isUnauthorized());
    }

    // Stands in for reading the verification email: no mail actually goes
    // out in tests (MailService no-ops without an API key), so the code is
    // read from the row it was stored on.
    private String verificationCodeFor(String orgId, String email) {
        return appUserRepository
                .findByOrganizationIdAndEmailIgnoreCase(java.util.UUID.fromString(orgId), email)
                .orElseThrow()
                .getVerificationCode();
    }
}

'@
$path = Join-Path (Get-Location) 'server\src\test\java\com\visilog\api\OnboardingFlowIntegrationTest.java'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/test/java/com/visilog/api/OnboardingFlowIntegrationTest.java'
$written = $written + 1

$content = @'
package com.visilog.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.visilog.api.dto.ForgotPasswordRequest;
import com.visilog.api.dto.ResetPasswordRequest;
import com.visilog.api.dto.SignupRequest;
import com.visilog.api.entity.AppUser;
import com.visilog.api.entity.Employee;
import com.visilog.api.entity.Organization;
import com.visilog.api.entity.Role;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.AppUserRepository;
import com.visilog.api.repository.EmployeeRepository;
import com.visilog.api.repository.OrgBillingRepository;
import com.visilog.api.repository.OrganizationRepository;
import com.visilog.api.security.JwtService;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.crypto.password.PasswordEncoder;

// Unit tests for the core business rule this whole rebuild is about:
// role is resolved automatically at signup by matching the email
// against the org's Employee roster -- no free role-picker.
//
// LENIENT: setUp() stubs a few things (password encoding, JWT issuing)
// that only some tests actually exercise, since not every test reaches
// buildAuthResponse() -- e.g. the rejection-path tests return before that.
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class AuthServiceTest {

    @Mock private OrganizationRepository organizationRepository;
    @Mock private AppUserRepository appUserRepository;
    @Mock private EmployeeRepository employeeRepository;
    @Mock private OrgBillingRepository orgBillingRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private JwtService jwtService;
    @Mock private GoogleTokenService googleTokenService;
    @Mock private MailService mailService;

    private AuthService authService;
    private Organization org;

    @BeforeEach
    void setUp() {
        authService = new AuthService(
                organizationRepository, appUserRepository, employeeRepository,
                orgBillingRepository, passwordEncoder, jwtService, googleTokenService, mailService);

        org = new Organization();
        org.setId(UUID.randomUUID());
        org.setCode("ACME1234");
        org.setName("Acme Inc");

        when(organizationRepository.findByCode("ACME1234")).thenReturn(Optional.of(org));
        when(passwordEncoder.encode(any())).thenReturn("hashed");
        when(jwtService.issueToken(any(), any(), any(), any(), any(), anyBoolean())).thenReturn("fake-jwt");
        when(appUserRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    void signupWithEmailMatchingRosterEntryInheritsThatRole() {
        Employee receptionist = new Employee();
        receptionist.setId(UUID.randomUUID());
        receptionist.setRole(Role.RECEPTIONIST);
        receptionist.setEmail("wendy@acme.com");
        when(employeeRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), "wendy@acme.com"))
                .thenReturn(Optional.of(receptionist));
        when(appUserRepository.existsByOrganizationIdAndEmailIgnoreCase(org.getId(), "wendy@acme.com"))
                .thenReturn(false);

        var response = authService.signup(new SignupRequest("ACME1234", "wendy@acme.com", "password123", "Wendy"));

        assertThat(response.user().role()).isEqualTo("RECEPTIONIST");
        assertThat(response.user().employeeId()).isEqualTo(receptionist.getId());
    }

    @Test
    void signupWithNoMatchingRosterEntryBecomesVisitor() {
        when(employeeRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), "stranger@example.com"))
                .thenReturn(Optional.empty());
        when(appUserRepository.existsByOrganizationIdAndEmailIgnoreCase(org.getId(), "stranger@example.com"))
                .thenReturn(false);

        var response = authService.signup(new SignupRequest("ACME1234", "stranger@example.com", "password123", "A Visitor"));

        assertThat(response.user().role()).isEqualTo("VISITOR");
        assertThat(response.user().employeeId()).isNull();
    }

    @Test
    void signupWithAlreadyRegisteredEmailIsRejected() {
        when(appUserRepository.existsByOrganizationIdAndEmailIgnoreCase(org.getId(), "existing@acme.com"))
                .thenReturn(true);

        assertThatThrownBy(() ->
                authService.signup(new SignupRequest("ACME1234", "existing@acme.com", "password123", "Someone")))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("already exists");
    }

    @Test
    void signupWithUnknownCompanyCodeIsRejected() {
        when(organizationRepository.findByCode("NOPE9999")).thenReturn(Optional.empty());

        assertThatThrownBy(() ->
                authService.signup(new SignupRequest("NOPE9999", "a@b.com", "password123", "A")))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("valid company code");
    }

    @Test
    void loginRejectsWrongPassword() {
        AppUser existing = new AppUser();
        existing.setId(UUID.randomUUID());
        existing.setOrganizationId(org.getId());
        existing.setEmail("wendy@acme.com");
        existing.setPasswordHash("hashed");
        existing.setRole(Role.RECEPTIONIST);
        when(appUserRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), "wendy@acme.com"))
                .thenReturn(Optional.of(existing));
        when(passwordEncoder.matches("wrong-password", "hashed")).thenReturn(false);

        assertThatThrownBy(() ->
                authService.login(new com.visilog.api.dto.LoginRequest("ACME1234", "wendy@acme.com", "wrong-password")))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("Incorrect email or password");
    }

    @Test
    void loginLocksAccountAfterFiveFailedAttempts() {
        AppUser existing = new AppUser();
        existing.setId(UUID.randomUUID());
        existing.setOrganizationId(org.getId());
        existing.setEmail("wendy@acme.com");
        existing.setPasswordHash("hashed");
        existing.setRole(Role.RECEPTIONIST);
        when(appUserRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), "wendy@acme.com"))
                .thenReturn(Optional.of(existing));
        when(passwordEncoder.matches("wrong-password", "hashed")).thenReturn(false);

        for (int i = 0; i < 5; i++) {
            assertThatThrownBy(() -> authService.login(
                    new com.visilog.api.dto.LoginRequest("ACME1234", "wendy@acme.com", "wrong-password")))
                    .isInstanceOf(ApiException.class);
        }

        assertThat(existing.getLockedUntil()).isNotNull();
        assertThatThrownBy(() -> authService.login(
                new com.visilog.api.dto.LoginRequest("ACME1234", "wendy@acme.com", "wrong-password")))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("Too many failed attempts");
    }

    @Test
    void loginResetsFailedAttemptsOnSuccess() {
        AppUser existing = new AppUser();
        existing.setId(UUID.randomUUID());
        existing.setOrganizationId(org.getId());
        existing.setEmail("wendy@acme.com");
        existing.setPasswordHash("hashed");
        existing.setRole(Role.RECEPTIONIST);
        existing.setFailedLoginAttempts(3);
        when(appUserRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), "wendy@acme.com"))
                .thenReturn(Optional.of(existing));
        when(passwordEncoder.matches("correct-password", "hashed")).thenReturn(true);

        authService.login(new com.visilog.api.dto.LoginRequest("ACME1234", "wendy@acme.com", "correct-password"));

        assertThat(existing.getFailedLoginAttempts()).isEqualTo(0);
        assertThat(existing.getLockedUntil()).isNull();
    }

    @Test
    void forgotPasswordSendsCodeWhenEmailMatchesAnAccount() {
        AppUser existing = new AppUser();
        existing.setId(UUID.randomUUID());
        existing.setOrganizationId(org.getId());
        existing.setEmail("wendy@acme.com");
        existing.setName("Wendy");
        when(appUserRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), "wendy@acme.com"))
                .thenReturn(Optional.of(existing));

        var response = authService.forgotPassword(new ForgotPasswordRequest("ACME1234", "wendy@acme.com"));

        assertThat(response.message()).contains("If that email is registered");
        assertThat(existing.getResetCode()).isNotNull();
        assertThat(existing.getResetCodeExpiresAt()).isNotNull();
    }

    @Test
    void forgotPasswordReturnsSameGenericMessageWhenEmailDoesNotMatch() {
        when(appUserRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), "nobody@acme.com"))
                .thenReturn(Optional.empty());

        var response = authService.forgotPassword(new ForgotPasswordRequest("ACME1234", "nobody@acme.com"));

        assertThat(response.message()).contains("If that email is registered");
    }

    @Test
    void resetPasswordRejectsWrongCode() {
        AppUser existing = new AppUser();
        existing.setId(UUID.randomUUID());
        existing.setOrganizationId(org.getId());
        existing.setEmail("wendy@acme.com");
        existing.setResetCode("123456");
        existing.setResetCodeExpiresAt(java.time.Instant.now().plusSeconds(300));
        when(appUserRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), "wendy@acme.com"))
                .thenReturn(Optional.of(existing));

        assertThatThrownBy(() -> authService.resetPassword(
                new ResetPasswordRequest("ACME1234", "wendy@acme.com", "000000", "newpassword123")))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("invalid or has expired");
    }

    @Test
    void resetPasswordRejectsExpiredCode() {
        AppUser existing = new AppUser();
        existing.setId(UUID.randomUUID());
        existing.setOrganizationId(org.getId());
        existing.setEmail("wendy@acme.com");
        existing.setResetCode("123456");
        existing.setResetCodeExpiresAt(java.time.Instant.now().minusSeconds(1));
        when(appUserRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), "wendy@acme.com"))
                .thenReturn(Optional.of(existing));

        assertThatThrownBy(() -> authService.resetPassword(
                new ResetPasswordRequest("ACME1234", "wendy@acme.com", "123456", "newpassword123")))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("invalid or has expired");
    }

    @Test
    void resetPasswordSucceedsWithValidCodeAndClearsIt() {
        AppUser existing = new AppUser();
        existing.setId(UUID.randomUUID());
        existing.setOrganizationId(org.getId());
        existing.setEmail("wendy@acme.com");
        existing.setResetCode("123456");
        existing.setResetCodeExpiresAt(java.time.Instant.now().plusSeconds(300));
        when(appUserRepository.findByOrganizationIdAndEmailIgnoreCase(org.getId(), "wendy@acme.com"))
                .thenReturn(Optional.of(existing));

        var response = authService.resetPassword(
                new ResetPasswordRequest("ACME1234", "wendy@acme.com", "123456", "newpassword123"));

        assertThat(response.message()).contains("password has been reset");
        assertThat(existing.getResetCode()).isNull();
        assertThat(existing.getResetCodeExpiresAt()).isNull();
    }
}

'@
$path = Join-Path (Get-Location) 'server\src\test\java\com\visilog\api\service\AuthServiceTest.java'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  server/src/test/java/com/visilog/api/service/AuthServiceTest.java'
$written = $written + 1

Write-Host ''
Write-Host "Done. $written files written."
Write-Host 'Next: run   cd server; .\mvnw -q test   to confirm the test suite passes.'
