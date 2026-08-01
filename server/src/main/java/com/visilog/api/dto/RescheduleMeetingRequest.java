package com.visilog.api.dto;

import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public record RescheduleMeetingRequest(
        @NotNull(message = "is required") Instant newStartTime,
        @NotNull(message = "is required") Instant newEndTime,
        String reason
) {
}
