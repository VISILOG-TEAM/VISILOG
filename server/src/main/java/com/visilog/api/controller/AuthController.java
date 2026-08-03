package com.visilog.api.controller;

import com.visilog.api.dto.ApproveUserRequest;
import com.visilog.api.dto.AuthResponse;
import com.visilog.api.dto.ForgotPasswordRequest;
import com.visilog.api.dto.GoogleAuthRequest;
import com.visilog.api.dto.LoginRequest;
import com.visilog.api.dto.MessageResponse;
import com.visilog.api.dto.PendingApprovalDto;
import com.visilog.api.dto.ResendApprovalRequest;
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
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
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

    // Re-issues a token from the caller's current DB state. Reachable
    // even while unverified/unapproved (see JwtAuthFilter's allow-list)
    // -- it's how either waiting screen picks up a state change made
    // from outside that session.
    @PostMapping("/refresh-token")
    public ResponseEntity<AuthResponse> refreshToken(@CurrentUser AuthPrincipal principal) {
        return ResponseEntity.ok(authService.refreshToken(principal));
    }

    // Owner approval. Manager-only: a Manager approves *other* accounts
    // in their own org, never their own (registerCompany already sets
    // that account approved).
    @GetMapping("/pending-approvals")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<List<PendingApprovalDto>> pendingApprovals(@CurrentUser AuthPrincipal principal) {
        return ResponseEntity.ok(authService.listPendingApprovals(principal));
    }

    @PostMapping("/approve-user")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<MessageResponse> approveUser(
            @CurrentUser AuthPrincipal principal, @Valid @RequestBody ApproveUserRequest request) {
        return ResponseEntity.ok(authService.approveUser(principal, request));
    }

    @PostMapping("/resend-approval")
    @PreAuthorize("hasRole('MANAGER')")
    public ResponseEntity<MessageResponse> resendApproval(
            @CurrentUser AuthPrincipal principal, @Valid @RequestBody ResendApprovalRequest request) {
        return ResponseEntity.ok(authService.resendApproval(principal, request.userId()));
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
