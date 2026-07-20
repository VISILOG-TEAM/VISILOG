package com.visilog.employee.visitorapproval.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.visilog.employee.visitorapproval.model.VisitorApproval;
import com.visilog.employee.visitorapproval.service.VisitorApprovalService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/visitor-approvals")
public class VisitorApprovalController {

    private final VisitorApprovalService visitorApprovalService;

    public VisitorApprovalController(
            VisitorApprovalService visitorApprovalService
    ) {
        this.visitorApprovalService = visitorApprovalService;
    }

    @GetMapping
    public ResponseEntity<List<VisitorApproval>> getAllApprovals() {
        return ResponseEntity.ok(
                visitorApprovalService.getAllApprovals()
        );
    }

    @GetMapping("/{approvalId}")
    public ResponseEntity<VisitorApproval> getApprovalById(
            @PathVariable Long approvalId
    ) {
        return ResponseEntity.ok(
                visitorApprovalService.getApprovalById(approvalId)
        );
    }

@GetMapping("/appointment/{appointmentId}")
public ResponseEntity<VisitorApproval> getApprovalByAppointmentId(
        @PathVariable Long appointmentId
) {
    return ResponseEntity.ok(
            visitorApprovalService.getApprovalByAppointmentId(appointmentId)
    );
}

    @PostMapping
    public ResponseEntity<VisitorApproval> createApproval(
            @Valid @RequestBody VisitorApproval visitorApproval
    ) {
        VisitorApproval createdApproval =
                visitorApprovalService.createApproval(visitorApproval);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(createdApproval);
    }

    @PutMapping("/{approvalId}")
    public ResponseEntity<VisitorApproval> updateApproval(
            @PathVariable Long approvalId,
            @Valid @RequestBody VisitorApproval visitorApproval
    ) {
        return ResponseEntity.ok(
                visitorApprovalService.updateApproval(
                        approvalId,
                        visitorApproval
                )
        );
    }

    @DeleteMapping("/{approvalId}")
    public ResponseEntity<Void> deleteApproval(
            @PathVariable Long approvalId
    ) {
        visitorApprovalService.deleteApproval(approvalId);

        return ResponseEntity.noContent().build();
    }
}