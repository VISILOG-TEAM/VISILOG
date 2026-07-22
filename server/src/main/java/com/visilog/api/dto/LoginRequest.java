package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
        @NotBlank(message = "is required") String companyCode,
        @NotBlank(message = "is required") String email,
        @NotBlank(message = "is required") String password
) {
}
