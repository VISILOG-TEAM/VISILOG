package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// A login account. Role is fixed at creation (see AuthService) -- never
// user-chosen. employeeId is set only when this account was matched to
// a roster entry at signup (i.e. role != VISITOR).
@Entity
@Table(name = "app_users", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"organization_id", "email"})
})
@Getter
@Setter
@NoArgsConstructor
public class AppUser {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    @Column(nullable = false)
    private String email;

    @Column(nullable = false)
    private String passwordHash;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private Role role;

    private UUID employeeId;

    // Set only while a Forgot Password reset is in flight -- cleared as
    // soon as it's used (or replaced by a fresh request). Never exposed
    // in any DTO.
    private String resetCode;
    private Instant resetCodeExpiresAt;

    // Email verification. False until the account owner enters the
    // 6-digit code we emailed them at signup; until then the JWT carries
    // verified=false and JwtAuthFilter refuses everything except the
    // handful of endpoints the verify screen itself needs. Accounts that
    // predate this feature were backfilled as true (see V22) -- and
    // Google accounts are created as true, since Google has already
    // proved the person controls that mailbox.
    @Column(nullable = false)
    private boolean emailVerified = false;

    private String verificationCode;
    private Instant verificationCodeExpiresAt;

    // Login lockout -- resets to 0 on any successful login. Once it
    // hits AuthService.MAX_LOGIN_ATTEMPTS, lockedUntil is set and
    // login() rejects attempts (even with the right password) until
    // that time passes.
    @Column(nullable = false)
    private int failedLoginAttempts = 0;
    private Instant lockedUntil;

    @Column(nullable = false)
    private Instant createdAt = Instant.now();
}
