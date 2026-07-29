package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// A pre-booked visit, made either by the visitor themselves (self-
// service, carries bookedByEmail) or by reception on a visitor's
// behalf. Admitting one creates a matching Visitor check-in record --
// see AppointmentService.admit.
@Entity
@Table(name = "appointments", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"organization_id", "nfc_code"})
})
@Getter
@Setter
@NoArgsConstructor
public class Appointment {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    private String visitorName;
    private String visitorPhone;
    private String visitorEmail;
    private String visitorCompany;
    private String purpose;
    private UUID hostId;

    @Column(nullable = false)
    private Instant scheduledAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private AppointmentStatus status;

    // Null until the host admits this visit -- see AppointmentService.admit.
    // A rejected or still-pending appointment never gets a code.
    private String nfcCode;

    private String bookedByEmail;

    @Column(length = 1000)
    private String rescheduleReason;
    private Instant rescheduledAt;

    @Column(name = "reject_reason", length = 1000)
    private String rejectReason;

    @Column(nullable = false)
    private boolean checkedIn = false;
}
