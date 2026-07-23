package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record ClockActionRequest(
        @NotNull(message = "is required") UUID employeeId,
        @NotBlank(message = "is required") String employeeName,
        // Optional -- a device that can't report one (e.g. an older app
        // build) just skips the device-binding check rather than being
        // blocked outright. See ClockRecordService.
        String deviceId
) {
}
