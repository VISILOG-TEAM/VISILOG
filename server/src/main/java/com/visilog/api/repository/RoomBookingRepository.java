package com.visilog.api.repository;

import com.visilog.api.entity.RoomBooking;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RoomBookingRepository extends JpaRepository<RoomBooking, UUID> {
    List<RoomBooking> findByOrganizationIdOrderByStartTimeDesc(UUID organizationId);

    // Standard interval-overlap test: two ranges overlap unless one ends
    // before the other starts. Used to block double-booking the same room.
    @Query("select b from RoomBooking b where b.organizationId = :organizationId and b.roomId = :roomId "
            + "and b.startTime < :endTime and b.endTime > :startTime")
    List<RoomBooking> findOverlapping(
            @Param("organizationId") UUID organizationId, @Param("roomId") UUID roomId,
            @Param("startTime") Instant startTime, @Param("endTime") Instant endTime);

    // Same overlap test, but keyed on a person (organiser or invited
    // participant) rather than a room — used to stop someone being
    // double-booked into two meetings at once, regardless of place.
    @Query("select b from RoomBooking b where b.organizationId = :organizationId "
            + "and (b.organiserId = :employeeId or :employeeId member of b.participantIds) "
            + "and b.startTime < :endTime and b.endTime > :startTime")
    List<RoomBooking> findOverlappingForPerson(
            @Param("organizationId") UUID organizationId, @Param("employeeId") UUID employeeId,
            @Param("startTime") Instant startTime, @Param("endTime") Instant endTime);
}
