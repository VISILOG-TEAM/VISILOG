package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;

// status: "acknowledged" or "declined" — reason is required when
// declining (see RoomBookingService.respond).
public record RespondToMeetingRequest(
        @NotBlank(message = "is required") String status,
        String reason
) {
}
