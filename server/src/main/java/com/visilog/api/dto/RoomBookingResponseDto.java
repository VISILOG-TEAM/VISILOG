package com.visilog.api.dto;

import com.visilog.api.entity.RoomBookingResponse;
import java.time.Instant;
import java.util.UUID;

public record RoomBookingResponseDto(
        UUID employeeId, String status, String declineReason, Instant respondedAt
) {
    public static RoomBookingResponseDto from(RoomBookingResponse r) {
        return new RoomBookingResponseDto(
                r.getEmployeeId(), r.getStatus().name(), r.getDeclineReason(), r.getRespondedAt());
    }
}
