package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// A named WiFi network shown to staff as "connect to X to clock in" --
// informational only, same as the single wifiNetworkName field this
// replaced (see V28 migration): a phone can't verify a specific SSID
// without extra native permissions most devices won't grant, so this
// just labels the intended network(s) rather than being enforced. An
// org can list more than one (e.g. separate networks per floor/building).
@Entity
@Table(name = "wifi_networks")
@Getter
@Setter
@NoArgsConstructor
public class WifiNetwork {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false)
    private UUID organizationId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();
}
