package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "calls")
@Getter
@Setter
@NoArgsConstructor
public class Call {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    private String callerName;
    private String callerPhone;
    private UUID hostId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private CallType callType;

    private String purpose;

    @Column(nullable = false)
    private Integer durationMinutes = 0;

    @Column(length = 2000)
    private String notes;

    @Column(name = "occurred_at", nullable = false)
    private Instant timestamp;
}
