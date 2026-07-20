package com.visilog.employee.meeting.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class MeetingNotFoundException extends RuntimeException {

    public MeetingNotFoundException(Long meetingId) {
        super("Meeting not found with ID: " + meetingId);
    }
}