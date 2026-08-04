package com.visilog.api.repository;

import com.visilog.api.entity.WifiNetwork;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WifiNetworkRepository extends JpaRepository<WifiNetwork, UUID> {
    List<WifiNetwork> findByOrganizationId(UUID organizationId);
    Optional<WifiNetwork> findByOrganizationIdAndId(UUID organizationId, UUID id);
}
