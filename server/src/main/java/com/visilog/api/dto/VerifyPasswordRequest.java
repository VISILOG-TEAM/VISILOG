package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;

public record VerifyPasswordRequest(
        @NotBlank(message = "is required") String password
) {
}
