package com.visilog.employee.visitorapproval.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.visilog.employee.visitorapproval.model.VisitorApproval;

public interface VisitorApprovalRepository
        extends JpaRepository<VisitorApproval, Long> {

    Optional<VisitorApproval> findByAppointmentId(Long appointmentId);

    List<VisitorApproval> findByDecision(String decision);

    List<VisitorApproval> findByApprovedBy(String approvedBy);
}