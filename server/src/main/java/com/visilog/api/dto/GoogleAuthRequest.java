package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;

public record GoogleAuthRequest(
        @NotBlank(message = "is required") String companyCode,
        @NotBlank(message = "is required") String idToken
) {
}