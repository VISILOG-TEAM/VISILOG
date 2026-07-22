package com.visilog.api.dto;

import com.visilog.api.entity.Organization;
import java.util.UUID;

public record OrganizationDto(
        UUID id,
        String code,
        String name,
        String logoUrl,
        ThemeDto theme,
        OfficeLocationDto officeLocation,
        String wifiNetworkName
) {
    public record ThemeDto(
            String brand, String brandDark, String brandTint,
            String primary, String primaryPressed, String primarySurface, String primarySurfaceStrong
    ) {
    }

    public record OfficeLocationDto(Double latitude, Double longitude, Integer radiusMeters) {
    }

    public static OrganizationDto from(Organization org) {
        var officeLocation = org.getOfficeLatitude() == null ? null
                : new OfficeLocationDto(org.getOfficeLatitude(), org.getOfficeLongitude(), org.getOfficeRadiusMeters());
        return new OrganizationDto(
                org.getId(), org.getCode(), org.getName(), org.getLogoUrl(),
                new ThemeDto(
                        org.getBrand(), org.getBrandDark(), org.getBrandTint(),
                        org.getPrimary(), org.getPrimaryPressed(), org.getPrimarySurface(), org.getPrimarySurfaceStrong()),
                officeLocation, org.getWifiNetworkName());
    }
}
