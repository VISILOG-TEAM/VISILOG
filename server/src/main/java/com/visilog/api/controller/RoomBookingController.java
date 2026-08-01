package com.visilog.api.controller;

import com.visilog.api.dto.BookRoomRequest;
import com.visilog.api.dto.MarkAbsentRequest;
import com.visilog.api.dto.RespondToMeetingRequest;
import com.visilog.api.dto.RescheduleMeetingRequest;
import com.visilog.api.dto.RoomBookingDto;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.RoomBookingService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/room-bookings")
public class RoomBookingController {

    private final RoomBookingService roomBookingService;

    public RoomBookingController(RoomBookingService roomBookingService) {
        this.roomBookingService = roomBookingService;
    }

    @GetMapping
    public ResponseEntity<List<RoomBookingDto>> list(@CurrentUser AuthPrincipal me) {
        return ResponseEntity.ok(roomBookingService.list(me.organizationId()));
    }

    @PostMapping
    public ResponseEntity<RoomBookingDto> book(@CurrentUser AuthPrincipal me, @Valid @RequestBody BookRoomRequest request) {
        return ResponseEntity.ok(roomBookingService.book(me.organizationId(), me.employeeId(), request));
    }

    @PatchMapping("/{id}/respond")
    public ResponseEntity<RoomBookingDto> respond(
            @CurrentUser AuthPrincipal me, @PathVariable UUID id, @Valid @RequestBody RespondToMeetingRequest request) {
        return ResponseEntity.ok(roomBookingService.respond(me.organizationId(), id, me.employeeId(), request));
    }

    @PatchMapping("/{id}/participants/{employeeId}/absent")
    public ResponseEntity<RoomBookingDto> markAbsent(
            @CurrentUser AuthPrincipal me, @PathVariable UUID id, @PathVariable UUID employeeId,
            @Valid @RequestBody MarkAbsentRequest request) {
        return ResponseEntity.ok(
                roomBookingService.markAbsent(me.organizationId(), me.employeeId(), id, employeeId, request));
    }

    @PatchMapping("/{id}/reschedule")
    public ResponseEntity<RoomBookingDto> reschedule(
            @CurrentUser AuthPrincipal me, @PathVariable UUID id, @Valid @RequestBody RescheduleMeetingRequest request) {
        return ResponseEntity.ok(roomBookingService.reschedule(me.organizationId(), id, me.employeeId(), request));
    }
}