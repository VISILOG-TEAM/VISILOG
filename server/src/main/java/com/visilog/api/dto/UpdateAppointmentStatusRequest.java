package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateAppointmentStatusRequest(@NotBlank(message = "is required") String status, String reason) {
}
