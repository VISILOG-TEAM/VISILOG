package com.visilog.api.dto;

import com.visilog.api.entity.OfficeLocation;
import java.util.UUID;

public record OfficeLocationDto(
        UUID id, String name, Double latitude, Double longitude, Integer radiusMeters
) {
    public static OfficeLocationDto from(OfficeLocation loc) {
        return new OfficeLocationDto(
                loc.getId(), loc.getName(), loc.getLatitude(), loc.getLongitude(), loc.getRadiusMeters());
    }
}
