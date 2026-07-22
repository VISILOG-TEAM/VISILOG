package com.visilog.api.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// Flat subscription tiers, seeded once (see V1 migration) — every org
// picks one via OrgBilling. Not tenant-scoped; shared catalog.
@Entity
@Table(name = "plans")
@Getter
@Setter
@NoArgsConstructor
public class Plan {

    @Id
    private String id; // "starter" | "pro" | "enterprise" — stable, human-readable

    @Column(nullable = false)
    private String name;

    // The flat 2-year subscription price, in GHS — paid up front at
    // registration, not billed monthly.
    @Column(nullable = false)
    private BigDecimal price;

    @Column(nullable = false)
    private Integer seatLimit;

    @ElementCollection
    @CollectionTable(name = "plan_features", joinColumns = @JoinColumn(name = "plan_id"))
    @Column(name = "feature")
    @OrderColumn(name = "position")
    private List<String> features = new ArrayList<>();
}
