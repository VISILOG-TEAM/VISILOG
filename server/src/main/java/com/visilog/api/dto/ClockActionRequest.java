package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record ClockActionRequest(
        @NotNull(message = "is required") UUID employeeId,
        @NotBlank(message = "is required") String employeeName
) {
}
