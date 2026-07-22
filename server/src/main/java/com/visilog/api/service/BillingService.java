package com.visilog.api.service;

import com.visilog.api.dto.BillingDto;
import com.visilog.api.dto.InvoiceDto;
import com.visilog.api.dto.PlanDto;
import com.visilog.api.entity.BillingStatus;
import com.visilog.api.entity.OrgBilling;
import com.visilog.api.entity.Plan;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.InvoiceRepository;
import com.visilog.api.repository.OrgBillingRepository;
import com.visilog.api.repository.PlanRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class BillingService {

    private final OrgBillingRepository orgBillingRepository;
    private final InvoiceRepository invoiceRepository;
    private final PlanRepository planRepository;

    public BillingService(
            OrgBillingRepository orgBillingRepository,
            InvoiceRepository invoiceRepository,
            PlanRepository planRepository) {
        this.orgBillingRepository = orgBillingRepository;
        this.invoiceRepository = invoiceRepository;
        this.planRepository = planRepository;
    }

    // readOnly: PlanDto.from reads the lazy `features` element
    // collection — needs an open session for the whole mapping, not
    // just the initial query (open-in-view is off).
    @Transactional(readOnly = true)
    public List<PlanDto> listPlans() {
        return planRepository.findAll().stream().map(PlanDto::from).toList();
    }

    @Transactional(readOnly = true)
    public BillingDto get(UUID organizationId) {
        return toDto(findBillingOrThrow(organizationId));
    }

    public List<InvoiceDto> listInvoices(UUID organizationId) {
        return invoiceRepository.findByOrganizationIdOrderByDateDesc(organizationId).stream()
                .map(InvoiceDto::from)
                .toList();
    }

    // Switching plans resets status to active (a successful switch
    // clears any trial/past-due state) — stands in for a real Stripe
    // checkout/upgrade flow.
    @Transactional
    public BillingDto changePlan(UUID organizationId, String planId) {
        Plan plan = planRepository.findById(planId)
                .orElseThrow(() -> ApiException.badRequest("Unknown plan."));
        OrgBilling billing = findBillingOrThrow(organizationId);
        billing.setPlanId(plan.getId());
        billing.setStatus(BillingStatus.ACTIVE);
        return toDto(orgBillingRepository.save(billing));
    }

    private OrgBilling findBillingOrThrow(UUID organizationId) {
        return orgBillingRepository.findByOrganizationId(organizationId)
                .orElseThrow(() -> ApiException.notFound("No billing record for this organization."));
    }

    private BillingDto toDto(OrgBilling billing) {
        Plan plan = planRepository.findById(billing.getPlanId())
                .orElseThrow(() -> ApiException.notFound("Plan not found."));
        return new BillingDto(
                PlanDto.from(plan), billing.getStatus().name(), billing.getSeatsUsed(),
                billing.getRenewalDate(), billing.getPaymentLast4());
    }
}
