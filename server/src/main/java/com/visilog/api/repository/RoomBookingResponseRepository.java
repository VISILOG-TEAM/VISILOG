package com.visilog.api.repository;

import com.visilog.api.entity.RoomBookingResponse;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RoomBookingResponseRepository extends JpaRepository<RoomBookingResponse, UUID> {
    List<RoomBookingResponse> findByRoomBookingId(UUID roomBookingId);
    Optional<RoomBookingResponse> findByRoomBookingIdAndEmployeeId(UUID roomBookingId, UUID employeeId);
}
