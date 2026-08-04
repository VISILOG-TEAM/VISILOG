package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// One row per device registered for push notifications -- an Expo push
// token (from expo-notifications' getExpoPushTokenAsync), not a raw
// FCM/APNs token, since PushNotificationService sends through Expo's
// push API rather than talking to Firebase/Apple directly. Exactly one
// of employeeId/visitorEmail is set, same convention as Notification.
@Entity
@Table(name = "push_tokens")
@Getter
@Setter
@NoArgsConstructor
public class PushToken {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    @Column(name = "employee_id")
    private UUID employeeId;

    @Column(name = "visitor_email")
    private String visitorEmail;

    @Column(nullable = false, unique = true)
    private String token;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
}
