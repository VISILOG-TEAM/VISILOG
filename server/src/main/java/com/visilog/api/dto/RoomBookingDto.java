package com.visilog.api.dto;

import com.visilog.api.entity.ExternalGuest;
import com.visilog.api.entity.RoomBooking;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record RoomBookingDto(
        UUID id, UUID roomId, String location, UUID organiserId, String title,
        Instant startTime, Instant endTime, List<UUID> participantIds, List<ExternalGuestDto> externalGuests,
        String priority, List<RoomBookingResponseDto> responses
) {
    public record ExternalGuestDto(String name, String email, String phone) {
        public static ExternalGuestDto from(ExternalGuest g) {
            return new ExternalGuestDto(g.getName(), g.getEmail(), g.getPhone());
        }
    }

    public static RoomBookingDto from(RoomBooking b, List<RoomBookingResponseDto> responses) {
        return new RoomBookingDto(
                b.getId(), b.getRoomId(), b.getLocation(), b.getOrganiserId(), b.getTitle(),
                b.getStartTime(), b.getEndTime(), List.copyOf(b.getParticipantIds()),
                b.getExternalGuests().stream().map(ExternalGuestDto::from).toList(),
                b.getPriority().name(), responses);
    }
}
