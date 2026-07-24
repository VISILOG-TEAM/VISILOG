package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record OfficeLocationRequest(
        @NotBlank String name,
        @NotNull Double latitude,
        @NotNull Double longitude,
        @NotNull Integer radiusMeters
) {
}
