package com.visilog.api.repository;

import com.visilog.api.entity.Notification;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NotificationRepository extends JpaRepository<Notification, UUID> {
    List<Notification> findByOrganizationIdAndRecipientEmployeeIdOrderByCreatedAtDesc(
            UUID organizationId, UUID recipientEmployeeId);
    List<Notification> findByOrganizationIdAndRecipientEmailIgnoreCaseOrderByCreatedAtDesc(
            UUID organizationId, String recipientEmail);
    Optional<Notification> findByOrganizationIdAndId(UUID organizationId, UUID id);
}
