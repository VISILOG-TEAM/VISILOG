package com.visilog.employee.visitorapproval.service;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;

import com.visilog.employee.appointment.service.AppointmentService;
import com.visilog.employee.visitorapproval.exception.VisitorApprovalNotFoundException;
import com.visilog.employee.visitorapproval.model.VisitorApproval;
import com.visilog.employee.visitorapproval.repository.VisitorApprovalRepository;

@Service
public class VisitorApprovalService {

    private final VisitorApprovalRepository visitorApprovalRepository;
    private final AppointmentService appointmentService;

    public VisitorApprovalService(
            VisitorApprovalRepository visitorApprovalRepository,
            AppointmentService appointmentService
    ) {
        this.visitorApprovalRepository = visitorApprovalRepository;
        this.appointmentService = appointmentService;
    }

    public List<VisitorApproval> getAllApprovals() {
        return visitorApprovalRepository.findAll();
    }

    public VisitorApproval getApprovalById(Long approvalId) {
        return visitorApprovalRepository.findById(approvalId)
                .orElseThrow(() ->
                        new VisitorApprovalNotFoundException(approvalId)
                );
    }

    public VisitorApproval createApproval(
        VisitorApproval visitorApproval
) {
    if (visitorApproval.getDecisionDate() == null) {
        visitorApproval.setDecisionDate(LocalDateTime.now());
    }

    visitorApproval.setDecision(
            visitorApproval.getDecision().toUpperCase()
    );

    appointmentService.updateAppointmentStatus(
            visitorApproval.getAppointmentId(),
            visitorApproval.getDecision()
    );

    return visitorApprovalRepository.save(visitorApproval);
}
       
    

    public VisitorApproval updateApproval(
        Long approvalId,
        VisitorApproval updatedApproval
) {
    VisitorApproval existingApproval =
            getApprovalById(approvalId);

    existingApproval.setAppointmentId(
            updatedApproval.getAppointmentId()
    );

    existingApproval.setDecision(
            updatedApproval.getDecision().toUpperCase()
    );

    existingApproval.setApprovedBy(
            updatedApproval.getApprovedBy()
    );

    existingApproval.setReason(
            updatedApproval.getReason()
    );

    existingApproval.setDecisionDate(
            updatedApproval.getDecisionDate() == null
                    ? LocalDateTime.now()
                    : updatedApproval.getDecisionDate()
    );

    appointmentService.updateAppointmentStatus(
            existingApproval.getAppointmentId(),
            existingApproval.getDecision()
    );

    return visitorApprovalRepository.save(existingApproval);
}

    public VisitorApproval getApprovalByAppointmentId(
            Long appointmentId
    ) {
        return visitorApprovalRepository.findByAppointmentId(appointmentId)
                .orElseThrow(() ->
                        new RuntimeException(
                                "Approval not found for appointment ID: "
                                        + appointmentId
                        )
                );
    }

    public void deleteApproval(Long approvalId) {
        VisitorApproval visitorApproval =
                getApprovalById(approvalId);

        visitorApprovalRepository.delete(visitorApproval);
    }
}