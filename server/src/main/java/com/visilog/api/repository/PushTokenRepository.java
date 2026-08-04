package com.visilog.api.repository;

import com.visilog.api.entity.PushToken;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PushTokenRepository extends JpaRepository<PushToken, UUID> {
    Optional<PushToken> findByToken(String token);
    List<PushToken> findByOrganizationIdAndEmployeeId(UUID organizationId, UUID employeeId);
    List<PushToken> findByOrganizationIdAndVisitorEmailIgnoreCase(UUID organizationId, String visitorEmail);
    void deleteByToken(String token);
}
