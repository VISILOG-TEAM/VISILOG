package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public record RescheduleRequest(
        @NotNull(message = "is required") Instant newScheduledAt,
        @NotBlank(message = "is required") String reason
) {
}
