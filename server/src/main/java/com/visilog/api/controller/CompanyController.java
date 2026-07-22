package com.visilog.api.controller;

import com.visilog.api.dto.AuthResponse;
import com.visilog.api.dto.RegisterCompanyRequest;
import com.visilog.api.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

// The self-serve "sign your company up" entry point — the whole point
// of this backend redesign. See AuthService.registerCompany.
@RestController
@RequestMapping("/api/v1/companies")
public class CompanyController {

    private final AuthService authService;

    public CompanyController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterCompanyRequest request) {
        return ResponseEntity.ok(authService.registerCompany(request));
    }
}
