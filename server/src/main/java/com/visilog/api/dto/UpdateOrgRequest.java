package com.visilog.api.dto;

// Company Setup > branding. All fields optional — only non-null ones
// are applied (see OrgService.updateOrg). `theme`, if present, must be
// applied as a whole (partial theme updates would leave mismatched
// shades), so its own fields are required together.
public record UpdateOrgRequest(String name, String logoUrl, ThemeUpdate theme, String wifiNetworkName) {

    public record ThemeUpdate(
            String brand, String brandDark, String brandTint,
            String primary, String primaryPressed, String primarySurface, String primarySurfaceStrong
    ) {
    }
}
