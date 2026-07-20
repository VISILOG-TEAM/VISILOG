package com.visilog.employee.meeting.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.visilog.employee.meeting.model.Meeting;
import com.visilog.employee.meeting.service.MeetingService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/meetings")
public class MeetingController {

    private final MeetingService meetingService;

    public MeetingController(MeetingService meetingService) {
        this.meetingService = meetingService;
    }

    @GetMapping
    public ResponseEntity<List<Meeting>> getAllMeetings() {
        return ResponseEntity.ok(meetingService.getAllMeetings());
    }

    @GetMapping("/{meetingId}")
    public ResponseEntity<Meeting> getMeetingById(
            @PathVariable Long meetingId
    ) {
        return ResponseEntity.ok(
                meetingService.getMeetingById(meetingId)
        );
    }

    @PostMapping
    public ResponseEntity<Meeting> createMeeting(
            @Valid @RequestBody Meeting meeting
    ) {
        Meeting createdMeeting =
                meetingService.createMeeting(meeting);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(createdMeeting);
    }

    @PutMapping("/{meetingId}")
    public ResponseEntity<Meeting> updateMeeting(
            @PathVariable Long meetingId,
            @Valid @RequestBody Meeting meeting
    ) {
        return ResponseEntity.ok(
                meetingService.updateMeeting(meetingId, meeting)
        );
    }

    @DeleteMapping("/{meetingId}")
    public ResponseEntity<Void> deleteMeeting(
            @PathVariable Long meetingId
    ) {
        meetingService.deleteMeeting(meetingId);
        return ResponseEntity.noContent().build();
    }
}