package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// A self-service meeting booking — either an internal MeetingRoom
// (roomId set) or an outside location (location set, roomId null).
// Bookable by Employee/Manager and, in "internal meeting" mode, by
// Receptionist too — see RoomBookingService.
@Entity
@Table(name = "room_bookings")
@Getter
@Setter
@NoArgsConstructor
public class RoomBooking {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    private UUID roomId; // null when this is an outside-location meeting
    private String location; // set only when roomId is null

    @Column(nullable = false)
    private UUID organiserId;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false)
    private Instant startTime;
    @Column(nullable = false)
    private Instant endTime;

    @ElementCollection
    @CollectionTable(name = "room_booking_participants", joinColumns = @JoinColumn(name = "room_booking_id"))
    @Column(name = "employee_id")
    private List<UUID> participantIds = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private MeetingPriority priority = MeetingPriority.NORMAL;

    // People outside the staff roster invited to this meeting (a
    // client, a candidate, a vendor) — participantIds only covers
    // employees. Each carries an email/phone (rather than just a
    // name) so RoomBookingService can actually send them an invite.
    @ElementCollection
    @CollectionTable(name = "room_booking_external_guests", joinColumns = @JoinColumn(name = "room_booking_id"))
    private List<ExternalGuest> externalGuests = new ArrayList<>();
}
