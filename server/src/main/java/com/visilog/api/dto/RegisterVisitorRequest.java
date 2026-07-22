package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record RegisterVisitorRequest(
        @NotBlank(message = "is required") String firstName,
        @NotBlank(message = "is required") String lastName,
        @NotBlank(message = "is required") String phone,
        String email,
        String company,
        String purpose,
        @NotNull(message = "is required") UUID hostId,
        String notes
) {
}