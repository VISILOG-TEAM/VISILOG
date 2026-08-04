package com.visilog.api.dto;

// Company Setup > branding. All fields optional — only non-null ones
// are applied (see OrgService.updateOrg). `theme`, if present, must be
// applied as a whole (partial theme updates would leave mismatched
// shades), so its own fields are required together. `openingTime` /
// `closingTime` are "HH:mm" strings; a blank string clears that one
// field independently (see WorkingHoursService for what "cleared" does).
public record UpdateOrgRequest(
        String name, String logoUrl, ThemeUpdate theme, String wifiNetworkName,
        String openingTime, String closingTime) {

    public record ThemeUpdate(
            String brand, String brandDark, String brandTint,
            String primary, String primaryPressed, String primarySurface, String primarySurfaceStrong
    ) {
    }
}
