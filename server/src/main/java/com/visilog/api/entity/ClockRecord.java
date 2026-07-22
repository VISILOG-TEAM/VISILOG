package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// Work attendance ledger — one row per clock in/out action. See
// ClockRecordService for the once-per-calendar-day-per-employee rule
// and the WiFi/location checks applied before a clock-in is accepted.
@Entity
@Table(name = "clock_records")
@Getter
@Setter
@NoArgsConstructor
public class ClockRecord {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    @Column(nullable = false)
    private UUID employeeId;

    @Column(nullable = false)
    private String employeeName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 8)
    private ClockType type;

    @Column(name = "occurred_at", nullable = false)
    private Instant timestamp;
}
