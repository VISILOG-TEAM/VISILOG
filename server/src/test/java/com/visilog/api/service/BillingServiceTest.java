package com.visilog.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.visilog.api.entity.BillingStatus;
import com.visilog.api.entity.OrgBilling;
import com.visilog.api.entity.Plan;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.EmployeeRepository;
import com.visilog.api.repository.InvoiceRepository;
import com.visilog.api.repository.OrgBillingRepository;
import com.visilog.api.repository.PlanRepository;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class BillingServiceTest {

    @Mock private OrgBillingRepository orgBillingRepository;
    @Mock private InvoiceRepository invoiceRepository;
    @Mock private PlanRepository planRepository;
    @Mock private EmployeeRepository employeeRepository;

    private BillingService service;
    private final UUID orgId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new BillingService(orgBillingRepository, invoiceRepository, planRepository, employeeRepository);
    }

    @Test
    void switchingPlanClearsPastDueStatus() {
        OrgBilling billing = new OrgBilling();
        billing.setOrganizationId(orgId);
        billing.setPlanId("starter");
        billing.setStatus(BillingStatus.PAST_DUE);
        billing.setRenewalDate(Instant.now());
        when(orgBillingRepository.findByOrganizationId(orgId)).thenReturn(Optional.of(billing));
        when(orgBillingRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        Plan enterprise = new Plan();
        enterprise.setId("enterprise");
        enterprise.setName("Enterprise");
        enterprise.setPrice(new BigDecimal("3500.00"));
        enterprise.setSeatLimit(500);
        when(planRepository.findById("enterprise")).thenReturn(Optional.of(enterprise));

        var result = service.changePlan(orgId, "enterprise");

        assertThat(result.status()).isEqualTo("ACTIVE");
        assertThat(result.plan().id()).isEqualTo("enterprise");
    }

    @Test
    void switchingToUnknownPlanIsRejected() {
        when(planRepository.findById("nonexistent")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.changePlan(orgId, "nonexistent"))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("Unknown plan");
    }
}
