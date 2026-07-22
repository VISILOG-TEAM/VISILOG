package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

// Either roomId or location must be set (not both) — an internal
// meeting room, or an outside spot. See RoomBookingService.book.
// priority is optional free text from the client ("normal" / "important"
// / "urgent") — defaults to normal when omitted; see RoomBookingService.
public record BookRoomRequest(
        UUID roomId,
        String location,
        @NotBlank(message = "is required") String title,
        @NotNull(message = "is required") Instant startTime,
        @NotNull(message = "is required") Instant endTime,
        List<UUID> participantIds,
        List<ExternalGuestRequest> externalGuests,
        String priority
) {
    public record ExternalGuestRequest(String name, String email, String phone) {
    }
}
