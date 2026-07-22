package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.UUID;

public record BookAppointmentRequest(
        @NotBlank(message = "is required") String visitorName,
        @NotBlank(message = "is required") String visitorPhone,
        String visitorEmail,
        String visitorCompany,
        String purpose,
        @NotNull(message = "is required") UUID hostId,
        Instant scheduledAt // defaults to now if omitted -- a visitor's own instant booking
) {
}