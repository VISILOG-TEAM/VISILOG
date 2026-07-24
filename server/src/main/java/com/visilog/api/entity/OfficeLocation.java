package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// A named GPS point + radius an org's clock-in/visitor-check-in
// geofence check (client-side, see locationCheck.ts) can be satisfied
// against -- an org can have more than one (see V21 migration, which
// replaced Organization's single office_latitude/longitude/radius).
// Every org gets one free; a second+ requires the enterprise plan (see
// OfficeLocationService).
@Entity
@Table(name = "office_locations")
@Getter
@Setter
@NoArgsConstructor
public class OfficeLocation {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false)
    private UUID organizationId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    @Column(nullable = false)
    private Integer radiusMeters;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();
}
