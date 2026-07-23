package com.visilog.api.service;

import com.visilog.api.entity.OrgBilling;
import com.visilog.api.entity.Organization;
import com.visilog.api.entity.Plan;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.OrgBillingRepository;
import com.visilog.api.repository.OrganizationRepository;
import com.visilog.api.repository.PlanRepository;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;

// Central chokepoint for plan-gated features (custom branding, CSV
// import) -- mirrors EmployeeService.checkSeatCap's load-billing/
// load-plan/compare-and-throw shape, but grandfathers any org that
// already existed when a gate shipped (Organization.grandfatheredFeatures,
// see V18 migration) so nobody loses something they were already using.
@Service
public class PlanFeatureService {

    // starter < pro < enterprise -- higher tiers satisfy lower requirements.
    private static final Map<String, Integer> TIER_ORDER = Map.of("starter", 0, "pro", 1, "enterprise", 2);

    private final OrganizationRepository organizationRepository;
    private final OrgBillingRepository orgBillingRepository;
    private final PlanRepository planRepository;

    public PlanFeatureService(
            OrganizationRepository organizationRepository, OrgBillingRepository orgBillingRepository,
            PlanRepository planRepository) {
        this.organizationRepository = organizationRepository;
        this.orgBillingRepository = orgBillingRepository;
        this.planRepository = planRepository;
    }

    // Throws a 409 with an upgrade-prompting message if the org's
    // current plan doesn't meet requiredPlanId and it isn't grandfathered.
    public void requirePlan(UUID organizationId, String requiredPlanId, String featureLabel) {
        Organization org = organizationRepository.findById(organizationId).orElse(null);
        if (org == null || org.isGrandfatheredFeatures()) {
            return;
        }
        OrgBilling billing = orgBillingRepository.findByOrganizationId(organizationId).orElse(null);
        if (billing == null || atLeast(billing.getPlanId(), requiredPlanId)) {
            return;
        }
        Plan required = planRepository.findById(requiredPlanId).orElse(null);
        String planName = required != null ? required.getName() : requiredPlanId;
        throw ApiException.conflict(
                featureLabel + " requires the " + planName + " plan or higher. Upgrade in Billing & subscription to unlock it.");
    }

    private boolean atLeast(String planId, String requiredPlanId) {
        return TIER_ORDER.getOrDefault(planId, 0) >= TIER_ORDER.getOrDefault(requiredPlanId, 0);
    }
}