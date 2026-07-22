package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// A walked-in/registered visitor's on-site record -- created at
// check-in (either directly by reception, or via admitting a pending
// Appointment). Distinct from Appointment, which is a pre-booking.
@Entity
@Table(name = "visitors", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"organization_id", "badge_id"})
})
@Getter
@Setter
@NoArgsConstructor
public class Visitor {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    @Column(nullable = false)
    private String badgeId;

    private String firstName;
    private String lastName;
    private String phone;
    private String email;
    private String company;
    private String purpose;
    private UUID hostId;

    @Column(nullable = false)
    private Instant checkInAt;
    private Instant checkOutAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private VisitorStatus status;

    @Column(length = 2000)
    private String notes;

    public String getFullName() {
        String f = firstName == null ? "" : firstName.trim();
        String l = lastName == null ? "" : lastName.trim();
        return (f + " " + l).trim();
    }
}