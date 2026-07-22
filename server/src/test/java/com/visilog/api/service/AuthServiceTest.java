package com.visilog.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
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
        when(jwtService.issueToken(any(), any(), any(), any(), any())).thenReturn("fake-jwt");
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