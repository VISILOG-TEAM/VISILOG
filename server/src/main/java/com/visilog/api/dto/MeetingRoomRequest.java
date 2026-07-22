package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;

public record MeetingRoomRequest(
        @NotBlank(message = "is required") String name,
        Integer capacity,
        String floor,
        String photoUrl,
        String description
) {
}
