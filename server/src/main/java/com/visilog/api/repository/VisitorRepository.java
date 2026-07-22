package com.visilog.api.repository;

import com.visilog.api.entity.Visitor;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface VisitorRepository extends JpaRepository<Visitor, UUID> {
    List<Visitor> findByOrganizationIdOrderByCheckInAtDesc(UUID organizationId);
    Optional<Visitor> findByOrganizationIdAndId(UUID organizationId, UUID id);
    long countByOrganizationId(UUID organizationId);
}
