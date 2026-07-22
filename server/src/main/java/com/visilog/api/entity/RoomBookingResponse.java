package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// One row per invited participant on a RoomBooking — created PENDING
// when the meeting is booked, updated when that participant
// acknowledges ("seen it") or declines (with a reason) the invite.
// The organiser doesn't get one for their own meeting.
@Entity
@Table(name = "room_booking_responses", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"room_booking_id", "employee_id"})
})
@Getter
@Setter
@NoArgsConstructor
public class RoomBookingResponse {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    @Column(name = "room_booking_id", nullable = false)
    private UUID roomBookingId;

    @Column(name = "employee_id", nullable = false)
    private UUID employeeId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private RoomBookingResponseStatus status = RoomBookingResponseStatus.PENDING;

    @Column(name = "decline_reason", length = 1000)
    private String declineReason;

    @Column(name = "responded_at")
    private Instant respondedAt;
}
