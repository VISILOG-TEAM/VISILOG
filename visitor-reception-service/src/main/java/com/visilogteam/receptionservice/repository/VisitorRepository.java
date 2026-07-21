package com.visilogteam.receptionservice.repository;

import com.visilogteam.receptionservice.entity.Visitor;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface VisitorRepository extends JpaRepository<Visitor, Long> {

    Optional<Visitor> findByNfcCardId(String nfcCardId);

    List<Visitor> findByStatus(String status);

    List<Visitor>
    findByFullNameContainingIgnoreCaseOrPhoneNumberContainingIgnoreCaseOrCompanyNameContainingIgnoreCaseOrHostEmployeeContainingIgnoreCaseOrNfcCardIdContainingIgnoreCase(
            String fullName,
            String phoneNumber,
            String companyName,
            String hostEmployee,
            String nfcCardId
    );

    long countByStatus(String status);

    long countByCheckInTimeBetween(
            LocalDateTime startTime,
            LocalDateTime endTime
    );

    long countByStatusAndCheckOutTimeBetween(
            String status,
            LocalDateTime startTime,
            LocalDateTime endTime
    );
}