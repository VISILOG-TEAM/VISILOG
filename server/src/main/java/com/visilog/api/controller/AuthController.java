package com.visilog.api.controller;

import com.visilog.api.dto.AuthResponse;
import com.visilog.api.dto.ForgotPasswordRequest;
import com.visilog.api.dto.GoogleAuthRequest;
import com.visilog.api.dto.LoginRequest;
import com.visilog.api.dto.MessageResponse;
import com.visilog.api.dto.ResetPasswordRequest;
import com.visilog.api.dto.SignupRequest;
import com.visilog.api.dto.UserDto;
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

    @GetMapping("/me")
    public ResponseEntity<UserDto> me(@CurrentUser AuthPrincipal principal) {
        return ResponseEntity.ok(authService.me(principal));
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