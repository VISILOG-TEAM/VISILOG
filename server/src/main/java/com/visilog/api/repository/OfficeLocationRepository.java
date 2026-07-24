package com.visilog.api.repository;

import com.visilog.api.entity.OfficeLocation;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OfficeLocationRepository extends JpaRepository<OfficeLocation, UUID> {
    List<OfficeLocation> findByOrganizationId(UUID organizationId);
    Optional<OfficeLocation> findByOrganizationIdAndId(UUID organizationId, UUID id);
    long countByOrganizationId(UUID organizationId);
}
