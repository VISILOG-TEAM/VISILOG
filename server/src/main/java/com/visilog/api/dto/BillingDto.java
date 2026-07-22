package com.visilog.api.dto;

import java.time.Instant;

public record BillingDto(
        PlanDto plan, String status, Integer seatsUsed, Instant renewalDate, String paymentLast4
) {
}
