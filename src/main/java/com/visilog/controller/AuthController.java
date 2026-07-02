package com.visilog.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.visilog.dto.ApiResponse;
import com.visilog.dto.LoginRequest;
import com.visilog.dto.SignUpRequest;
import com.visilog.service.EmailService;
import com.visilog.service.UserService;

import jakarta.validation.Valid;

/**
 * REST endpoints for signup and login.
 *
 * This replaces the ActionListener code that used to live directly inside
 * Login.java and SignUpForm.java. Same underlying logic (UserService /
 * EmailService), just triggered by an HTTP request instead of a button
 * click, and returning JSON instead of a JOptionPane dialog.
 *
 * Base URL once running locally: http://localhost:8080/api/auth
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserService userService;
    private final EmailService emailService;

    @Autowired
    public AuthController(UserService userService, EmailService emailService) {
        this.userService = userService;
        this.emailService = emailService;

        // Sample account for testing, same as the old Login.java constructor.
        // Remove this once real signup is working end-to-end.
        this.userService.register("admin", "Admin@1234", "admin@example.com");
    }

    /**
     * POST /api/auth/signup
     * Body: { "username": "...", "email": "...", "password": "..." }
     *
     * Note: confirm-password matching happens in the React Native app now
     * (compare the two fields before this request is even sent) - this
     * endpoint only receives the final, already-confirmed password.
     */
    @PostMapping("/signup")
    public ResponseEntity<ApiResponse<Object>> signup(@Valid @RequestBody SignUpRequest request) {
        if (userService.userExists(request.getUsername())) {
            return ResponseEntity
                    .status(HttpStatus.CONFLICT)
                    .body(ApiResponse.failure("Username already exists. Please choose another."));
        }

        boolean registered = userService.register(
                request.getUsername(), request.getPassword(), request.getEmail());

        if (!registered) {
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.failure("Registration failed. Please try again."));
        }

        emailService.sendEmailAsync(
                request.getEmail(),
                "Welcome to VISILOG",
                "Hello " + request.getUsername()
                        + ",\n\nThank you for registering with VISILOG.\n\n"
                        + "Your account has been created successfully."
        );

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Account created successfully! Check your email."));
    }

    /**
     * POST /api/auth/login
     * Body: { "username": "...", "password": "..." }
     */
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<Object>> login(@Valid @RequestBody LoginRequest request) {
        if (!userService.login(request.getUsername(), request.getPassword())) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.failure("Invalid username or password!"));
        }

        String email = userService.getEmail(request.getUsername());
        if (email != null) {
            emailService.sendEmailAsync(
                    email,
                    "Login Alert",
                    "You have successfully logged into VISILOG."
            );
        }

        return ResponseEntity.ok(ApiResponse.success("Login successful!"));
    }
}
