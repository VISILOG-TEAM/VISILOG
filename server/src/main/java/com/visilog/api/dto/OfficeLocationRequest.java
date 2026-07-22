package com.visilog.api.dto;

import jakarta.validation.constraints.NotNull;

public record OfficeLocationRequest(
        @NotNull Double latitude,
        @NotNull Double longitude,
        @NotNull Integer radiusMeters
) {
}
