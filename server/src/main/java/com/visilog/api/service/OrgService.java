package com.visilog.api.service;

import com.visilog.api.dto.OrganizationDto;
import com.visilog.api.dto.UpdateOrgRequest;
import com.visilog.api.entity.OrgBilling;
import com.visilog.api.entity.Organization;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.OrgBillingRepository;
import com.visilog.api.repository.OrganizationRepository;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Company Setup > branding -- manager-only, enforced at the controller
// via @PreAuthorize("hasRole('MANAGER')"). Office location moved to
// OfficeLocationService/Controller (see V21 migration).
@Service
public class OrgService {

    private final OrganizationRepository organizationRepository;
    private final OrgBillingRepository orgBillingRepository;
    private final PlanFeatureService planFeatureService;

    public OrgService(
            OrganizationRepository organizationRepository, OrgBillingRepository orgBillingRepository,
            PlanFeatureService planFeatureService) {
        this.organizationRepository = organizationRepository;
        this.orgBillingRepository = orgBillingRepository;
        this.planFeatureService = planFeatureService;
    }

    public OrganizationDto get(UUID organizationId) {
        return OrganizationDto.from(findOrThrow(organizationId), currentPlanId(organizationId));
    }

    private String currentPlanId(UUID organizationId) {
        return orgBillingRepository.findByOrganizationId(organizationId)
                .map(OrgBilling::getPlanId).orElse(null);
    }

    @Transactional
    public OrganizationDto update(UUID organizationId, UpdateOrgRequest req) {
        Organization org = findOrThrow(organizationId);
        if (req.name() != null && !req.name().isBlank()) {
            org.setName(req.name().trim());
        }
        // Clearing the logo is always allowed -- only setting a new one
        // is the paid feature. Same for theme: only changing away from
        // the default is gated, never reverting.
        if (req.logoUrl() != null && !req.logoUrl().isBlank()) {
            planFeatureService.requirePlan(organizationId, "enterprise", "Custom branding");
        }
        if (req.theme() != null) {
            planFeatureService.requirePlan(organizationId, "enterprise", "Custom branding");
        }
        if (req.logoUrl() != null) {
            org.setLogoUrl(req.logoUrl().isBlank() ? null : req.logoUrl().trim());
        }
        if (req.wifiNetworkName() != null) {
            org.setWifiNetworkName(req.wifiNetworkName().isBlank() ? null : req.wifiNetworkName().trim());
        }
        if (req.theme() != null) {
            var t = req.theme();
            org.setBrand(t.brand());
            org.setBrandDark(t.brandDark());
            org.setBrandTint(t.brandTint());
            org.setPrimary(t.primary());
            org.setPrimaryPressed(t.primaryPressed());
            org.setPrimarySurface(t.primarySurface());
            org.setPrimarySurfaceStrong(t.primarySurfaceStrong());
        }
        return OrganizationDto.from(organizationRepository.save(org), currentPlanId(organizationId));
    }

    private Organization findOrThrow(UUID organizationId) {
        return organizationRepository.findById(organizationId)
                .orElseThrow(() -> ApiException.notFound("Organization not found."));
    }
}
