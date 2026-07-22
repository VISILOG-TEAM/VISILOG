package com.visilog.api.controller;

import com.visilog.api.dto.BulkImportResult;
import com.visilog.api.dto.BulkMeetingRoomRequest;
import com.visilog.api.dto.MeetingRoomDto;
import com.visilog.api.dto.MeetingRoomRequest;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.MeetingRoomService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/meeting-rooms")
public class MeetingRoomController {

    private final MeetingRoomService meetingRoomService;

    public MeetingRoomController(MeetingRoomService meetingRoomService) {
        this.meetingRoomService = meetingRoomService;
    }

    @GetMapping
    public ResponseEntity<List<MeetingRoomDto>> list(@CurrentUser AuthPrincipal me) {
        return ResponseEntity.ok(meetingRoomService.list(me.organizationId()));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @PostMapping
    public ResponseEntity<MeetingRoomDto> create(@CurrentUser AuthPrincipal me, @Valid @RequestBody MeetingRoomRequest request) {
        return ResponseEntity.ok(meetingRoomService.create(me.organizationId(), request));
    }

    // CSV bulk import from Company Setup — same row-by-row pattern as
    // EmployeeController.bulkCreate.
    @PreAuthorize("hasRole('MANAGER')")
    @PostMapping("/bulk")
    public ResponseEntity<BulkImportResult<MeetingRoomDto>> bulkCreate(
            @CurrentUser AuthPrincipal me, @RequestBody BulkMeetingRoomRequest request) {
        return ResponseEntity.ok(meetingRoomService.bulkCreate(me.organizationId(), request.rooms()));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @PatchMapping("/{id}")
    public ResponseEntity<MeetingRoomDto> update(
            @CurrentUser AuthPrincipal me, @PathVariable UUID id, @Valid @RequestBody MeetingRoomRequest request) {
        return ResponseEntity.ok(meetingRoomService.update(me.organizationId(), id, request));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@CurrentUser AuthPrincipal me, @PathVariable UUID id) {
        meetingRoomService.delete(me.organizationId(), id);
        return ResponseEntity.noContent().build();
    }
}
