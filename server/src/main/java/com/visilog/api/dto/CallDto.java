package com.visilog.api.dto;

import com.visilog.api.entity.Call;
import java.time.Instant;
import java.util.UUID;

public record CallDto(
        UUID id, String callerName, String callerPhone, UUID hostId,
        String callType, String purpose, Integer durationMinutes, String notes, Instant timestamp
) {
    public static CallDto from(Call c) {
        return new CallDto(
                c.getId(), c.getCallerName(), c.getCallerPhone(), c.getHostId(),
                c.getCallType().name(), c.getPurpose(), c.getDurationMinutes(), c.getNotes(), c.getTimestamp());
    }
}
