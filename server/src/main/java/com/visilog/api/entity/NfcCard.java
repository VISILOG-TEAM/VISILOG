package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "nfc_cards")
@Getter
@Setter
@NoArgsConstructor
public class NfcCard {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    @Column(nullable = false)
    private UUID holderId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private NfcHolderType holderType;

    @Column(nullable = false)
    private String tokenHash;

    @Column(nullable = false)
    private Instant issuedAt;
    private Instant expiresAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private NfcStatus status;
}
