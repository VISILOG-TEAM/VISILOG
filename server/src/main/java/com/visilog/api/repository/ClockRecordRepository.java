package com.visilog.api.repository;

import com.visilog.api.entity.ClockRecord;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ClockRecordRepository extends JpaRepository<ClockRecord, UUID> {
    List<ClockRecord> findByOrganizationIdOrderByTimestampDesc(UUID organizationId);
    Optional<ClockRecord> findFirstByOrganizationIdAndEmployeeIdOrderByTimestampDesc(UUID organizationId, UUID employeeId);
    boolean existsByOrganizationIdAndEmployeeIdAndTypeAndTimestampBetween(
            UUID organizationId, UUID employeeId, com.visilog.api.entity.ClockType type, Instant from, Instant to);
}
