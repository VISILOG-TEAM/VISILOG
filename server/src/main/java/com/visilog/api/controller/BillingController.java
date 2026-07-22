package com.visilog.api.controller;

import com.visilog.api.dto.BillingDto;
import com.visilog.api.dto.ChangePlanRequest;
import com.visilog.api.dto.InvoiceDto;
import com.visilog.api.dto.PlanDto;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.BillingService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
public class BillingController {

    private final BillingService billingService;

    public BillingController(BillingService billingService) {
        this.billingService = billingService;
    }

    @GetMapping("/plans")
    public ResponseEntity<List<PlanDto>> plans() {
        return ResponseEntity.ok(billingService.listPlans());
    }

    @PreAuthorize("hasRole('MANAGER')")
    @GetMapping("/billing")
    public ResponseEntity<BillingDto> get(@CurrentUser AuthPrincipal me) {
        return ResponseEntity.ok(billingService.get(me.organizationId()));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @PatchMapping("/billing/plan")
    public ResponseEntity<BillingDto> changePlan(@CurrentUser AuthPrincipal me, @Valid @RequestBody ChangePlanRequest request) {
        return ResponseEntity.ok(billingService.changePlan(me.organizationId(), request.planId()));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @GetMapping("/billing/invoices")
    public ResponseEntity<List<InvoiceDto>> invoices(@CurrentUser AuthPrincipal me) {
        return ResponseEntity.ok(billingService.listInvoices(me.organizationId()));
    }
}
