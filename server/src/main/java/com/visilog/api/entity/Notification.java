package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// An in-app alert for a staff member — e.g. "you've been added to a
// meeting". Fetched by the recipient's own app on load/focus -- this
// row itself is never pushed to a device. Device push exists
// separately, only for the 30-min-before reminder (see PushToken,
// ReminderService), not for every notification type here.
@Entity
@Table(name = "notifications")
@Getter
@Setter
@NoArgsConstructor
public class Notification {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    // Exactly one of these two is set: staff are addressed by employee
    // id, visitors (who have no employee record) by their account email.
    @Column(name = "recipient_employee_id")
    private UUID recipientEmployeeId;

    @Column(name = "recipient_email")
    private String recipientEmail;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 32)
    private NotificationType type;

    @Column(nullable = false)
    private String title;

    @Column(length = 1000)
    private String body;

    private UUID relatedId;

    @Column(nullable = false)
    private boolean read = false;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
