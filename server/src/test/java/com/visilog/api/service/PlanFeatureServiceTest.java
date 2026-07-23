package com.visilog.api.service;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import com.visilog.api.entity.OrgBilling;
import com.visilog.api.entity.Organization;
import com.visilog.api.entity.Plan;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.OrgBillingRepository;
import com.visilog.api.repository.OrganizationRepository;
import com.visilog.api.repository.PlanRepository;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class PlanFeatureServiceTest {

    @Mock private OrganizationRepository organizationRepository;
    @Mock private OrgBillingRepository orgBillingRepository;
    @Mock private PlanRepository planRepository;

    private PlanFeatureService service;
    private final UUID orgId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new PlanFeatureService(organizationRepository, orgBillingRepository, planRepository);
    }

    private Organization org(boolean grandfathered) {
        Organization o = new Organization();
        o.setGrandfatheredFeatures(grandfathered);
        return o;
    }

    private OrgBilling billing(String planId) {
        OrgBilling b = new OrgBilling();
        b.setPlanId(planId);
        return b;
    }

    @Test
    void grandfatheredOrgKeepsAccessRegardlessOfPlan() {
        when(organizationRepository.findById(orgId)).thenReturn(Optional.of(org(true)));

        assertThatCode(() -> service.requirePlan(orgId, "enterprise", "Custom branding"))
                .doesNotThrowAnyException();
    }

    @Test
    void orgOnQualifyingPlanIsAllowed() {
        when(organizationRepository.findById(orgId)).thenReturn(Optional.of(org(false)));
        when(orgBillingRepository.findByOrganizationId(orgId)).thenReturn(Optional.of(billing("pro")));

        assertThatCode(() -> service.requirePlan(orgId, "pro", "CSV import"))
                .doesNotThrowAnyException();
    }

    @Test
    void orgOnHigherPlanThanRequiredIsAllowed() {
        when(organizationRepository.findById(orgId)).thenReturn(Optional.of(org(false)));
        when(orgBillingRepository.findByOrganizationId(orgId)).thenReturn(Optional.of(billing("enterprise")));

        assertThatCode(() -> service.requirePlan(orgId, "pro", "CSV import"))
                .doesNotThrowAnyException();
    }

    @Test
    void nonGrandfatheredOrgBelowRequiredPlanIsBlocked() {
        when(organizationRepository.findById(orgId)).thenReturn(Optional.of(org(false)));
        when(orgBillingRepository.findByOrganizationId(orgId)).thenReturn(Optional.of(billing("starter")));
        Plan pro = new Plan();
        pro.setId("pro");
        pro.setName("Pro");
        when(planRepository.findById("pro")).thenReturn(Optional.of(pro));

        assertThatThrownBy(() -> service.requirePlan(orgId, "pro", "CSV import"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("CSV import")
                .hasMessageContaining("Pro plan or higher");
    }

    @Test
    void missingBillingRowFailsOpen() {
        when(organizationRepository.findById(orgId)).thenReturn(Optional.of(org(false)));
        when(orgBillingRepository.findByOrganizationId(orgId)).thenReturn(Optional.empty());

        assertThatCode(() -> service.requirePlan(orgId, "enterprise", "Custom branding"))
                .doesNotThrowAnyException();
    }

    @Test
    void missingOrgFailsOpen() {
        when(organizationRepository.findById(orgId)).thenReturn(Optional.empty());

        assertThatCode(() -> service.requirePlan(orgId, "enterprise", "Custom branding"))
                .doesNotThrowAnyException();
    }
}