package com.visilog.api.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// Admin-managed in Company Setup -- the rooms selectable in
// BookMeetingForm on the frontend and shown on the visitor map tour.
@Entity
@Table(name = "meeting_rooms")
@Getter
@Setter
@NoArgsConstructor
public class MeetingRoom {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    @Column(nullable = false)
    private String name;

    private Integer capacity;
    private String floor;

    // A real photo of the room, shown on the visitor map instead of the
    // stylized floor-plan icon -- base64 data URI or a pasted link, same
    // pattern as Organization.logoUrl.
    @Column(columnDefinition = "TEXT")
    private String photoUrl;

    // Free-text directions/notes for finding the room -- shown on the
    // visitor map alongside the auto-generated step directions.
    @Column(columnDefinition = "TEXT")
    private String description;
}
