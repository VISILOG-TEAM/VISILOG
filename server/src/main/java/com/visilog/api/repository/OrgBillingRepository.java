package com.visilog.api.repository;

import com.visilog.api.entity.OrgBilling;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrgBillingRepository extends JpaRepository<OrgBilling, UUID> {
    Optional<OrgBilling> findByOrganizationId(UUID organizationId);
}
