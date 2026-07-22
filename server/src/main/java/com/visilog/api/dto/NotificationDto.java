package com.visilog.api.dto;

import com.visilog.api.entity.Notification;
import java.time.Instant;
import java.util.UUID;

public record NotificationDto(
        UUID id, String type, String title, String body, UUID relatedId, boolean read, Instant createdAt
) {
    public static NotificationDto from(Notification n) {
        return new NotificationDto(
                n.getId(), n.getType().name(), n.getTitle(), n.getBody(), n.getRelatedId(), n.isRead(),
                n.getCreatedAt());
    }
}
