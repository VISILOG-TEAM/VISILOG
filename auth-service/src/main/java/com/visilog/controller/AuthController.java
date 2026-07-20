package com.visilog.controller;

import java.util.HashMap;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.visilog.dto.ApiResponse;
import com.visilog.dto.LoginRequest;
import com.visilog.dto.SignUpRequest;
import com.visilog.model.UserAccount;
import com.visilog.service.EmailService;
import com.visilog.service.JwtService;
import com.visilog.service.UserService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserService userService;
    private final EmailService emailService;
    private final JwtService jwtService;

   public AuthController(
        UserService userService,
        EmailService emailService,
        JwtService jwtService
) {
    this.userService = userService;
    this.emailService = emailService;
    this.jwtService = jwtService;
}

    @PostMapping("/signup")
    public ResponseEntity<ApiResponse<Object>> signup(
            @Valid @RequestBody SignUpRequest request
    ) {

        try {
            UserAccount userAccount = userService.register(
        request.getCompanyCode(),
        request.getFullName(),
        request.getEmail(),
        request.getPassword(),
        request.getConfirmPassword(),
        request.getRole(),
        request.getStaffRole()
);

            emailService.sendEmailAsync(
                    userAccount.getEmail(),
                    "Welcome to VISILOG",
                    "Hello " + userAccount.getFullName()
                            + ",\n\nYour VISILOG account has been created successfully."
            );

            Map<String, Object> data = new HashMap<>();
            data.put("userId", userAccount.getUserId());
            data.put("fullName", userAccount.getFullName());
            data.put("email", userAccount.getEmail());
            data.put("role", userAccount.getRole());
            data.put("staffRole", userAccount.getStaffRole());
            data.put("companyCode", userAccount.getCompanyCode());

            return ResponseEntity
                    .status(HttpStatus.CREATED)
                    .body(ApiResponse.success(
                            "Account created successfully.",
                            data
                    ));

        } catch (IllegalArgumentException exception) {
            return ResponseEntity
                    .status(HttpStatus.CONFLICT)
                    .body(ApiResponse.failure(exception.getMessage()));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<Object>> login(
            @Valid @RequestBody LoginRequest request
    ) {

        try {
            UserAccount userAccount = userService.login(
                    request.getEmail(),
                    request.getPassword()
            );

            String dashboard =
                    userService.determineDashboard(userAccount);
                  String token = jwtService.generateToken(userAccount);   

            Map<String, Object> data = new HashMap<>();
            data.put("userId", userAccount.getUserId());
            data.put("fullName", userAccount.getFullName());
            data.put("email", userAccount.getEmail());
            data.put("role", userAccount.getRole());
            data.put("staffRole", userAccount.getStaffRole());
            data.put("dashboard", dashboard);
            data.put("token", token);

            emailService.sendEmailAsync(
                    userAccount.getEmail(),
                    "VISILOG Login Alert",
                    "You have successfully logged into VISILOG."
            );

            return ResponseEntity.ok(
                    ApiResponse.success(
                            "Login successful.",
                            data
                    )
            );

        } catch (IllegalArgumentException exception) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.failure(exception.getMessage()));
        }
    }
}