package com.visilog.api.dto;

import com.visilog.api.entity.AppUser;
import java.time.Instant;
import java.util.UUID;

// One row on the Manager's Pending Approvals screen. Never carries the
// approval code itself -- that only ever goes out by email.
public record PendingApprovalDto(
        UUID id,
        String name,
        String email,
        String role,
        Instant createdAt
) {
    public static PendingApprovalDto from(AppUser user) {
        return new PendingApprovalDto(
                user.getId(), user.getName(), user.getEmail(), user.getRole().name(), user.getCreatedAt());
    }
}
