package com.visilog.api.dto;

import com.visilog.api.entity.Visitor;
import java.time.Instant;
import java.util.UUID;

public record VisitorDto(
        UUID id, String badgeId, String firstName, String lastName, String fullName,
        String phone, String email, String company, String purpose, UUID hostId,
        Instant checkInAt, Instant checkOutAt, String status, String notes
) {
    public static VisitorDto from(Visitor v) {
        return new VisitorDto(
                v.getId(), v.getBadgeId(), v.getFirstName(), v.getLastName(), v.getFullName(),
                v.getPhone(), v.getEmail(), v.getCompany(), v.getPurpose(), v.getHostId(),
                v.getCheckInAt(), v.getCheckOutAt(), v.getStatus().name(), v.getNotes());
    }
}