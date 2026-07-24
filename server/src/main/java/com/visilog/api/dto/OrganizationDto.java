package com.visilog.api.dto;

import com.visilog.api.entity.Organization;
import java.util.UUID;

public record OrganizationDto(
        UUID id,
        String code,
        String name,
        String logoUrl,
        ThemeDto theme,
        String wifiNetworkName,
        // The org's current plan id -- exposed here (not just via the
        // manager-only GET /billing) so every role can do client-side
        // plan-feature checks like SettingsScreen's priority-support
        // badge and VisitorHomeScreen's tour map gate, without needing
        // access to the rest of Billing (payment info, invoices).
        String planId
) {
    public record ThemeDto(
            String brand, String brandDark, String brandTint,
            String primary, String primaryPressed, String primarySurface, String primarySurfaceStrong
    ) {
    }

    public static OrganizationDto from(Organization org, String planId) {
        return new OrganizationDto(
                org.getId(), org.getCode(), org.getName(), org.getLogoUrl(),
                new ThemeDto(
                        org.getBrand(), org.getBrandDark(), org.getBrandTint(),
                        org.getPrimary(), org.getPrimaryPressed(), org.getPrimarySurface(), org.getPrimarySurfaceStrong()),
                org.getWifiNetworkName(), planId);
    }
}
