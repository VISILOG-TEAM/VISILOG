package com.visilog.api.dto;

import java.util.UUID;

public record LogCallRequest(
        String callerName, String callerPhone, UUID hostId,
        String callType, String purpose, Integer durationMinutes, String notes
) {
}
