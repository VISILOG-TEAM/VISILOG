package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// One row per Organization — created automatically (trial, Starter
// plan) when a company registers. See AuthService.registerCompany and
// BillingService.changePlan.
@Entity
@Table(name = "org_billing")
@Getter
@Setter
@NoArgsConstructor
public class OrgBilling {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false, unique = true)
    private UUID organizationId;

    @Column(nullable = false)
    private String planId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private BillingStatus status;

    @Column(nullable = false)
    private Integer seatsUsed = 0;

    @Column(nullable = false)
    private Instant renewalDate;

    private String paymentLast4;
}
