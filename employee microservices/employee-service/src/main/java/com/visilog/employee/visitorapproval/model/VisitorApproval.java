package com.visilog.employee.visitorapproval.model;

import java.time.LocalDateTime;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

@Entity
@Table(name = "visitor_approvals")
public class VisitorApproval {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long approvalId;

    @NotNull(message = "Appointment ID is required")
    private Long appointmentId;

    @NotBlank(message = "Decision is required")
    private String decision;

    @NotBlank(message = "Approved by is required")
    private String approvedBy;

    private String reason;

    private LocalDateTime decisionDate;

    public VisitorApproval() {
        this.decisionDate = LocalDateTime.now();
    }

    public Long getApprovalId() {
        return approvalId;
    }

    public void setApprovalId(Long approvalId) {
        this.approvalId = approvalId;
    }

    public Long getAppointmentId() {
        return appointmentId;
    }

    public void setAppointmentId(Long appointmentId) {
        this.appointmentId = appointmentId;
    }

    public String getDecision() {
        return decision;
    }

    public void setDecision(String decision) {
        this.decision = decision;
    }

    public String getApprovedBy() {
        return approvedBy;
    }

    public void setApprovedBy(String approvedBy) {
        this.approvedBy = approvedBy;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }

    public LocalDateTime getDecisionDate() {
        return decisionDate;
    }

    public void setDecisionDate(LocalDateTime decisionDate) {
        this.decisionDate = decisionDate;
    }
}