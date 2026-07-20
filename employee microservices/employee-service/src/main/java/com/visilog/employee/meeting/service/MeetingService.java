package com.visilog.employee.meeting.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.visilog.employee.meeting.exception.MeetingNotFoundException;
import com.visilog.employee.meeting.model.Meeting;
import com.visilog.employee.meeting.repository.MeetingRepository;
@Service
public class MeetingService {

    private final MeetingRepository meetingRepository;

    public MeetingService(MeetingRepository meetingRepository) {
        this.meetingRepository = meetingRepository;
    }

    public List<Meeting> getAllMeetings() {
        return meetingRepository.findAll();
    }

    public Meeting getMeetingById(Long meetingId) {
        return meetingRepository.findById(meetingId)
                .orElseThrow(() ->
                        new MeetingNotFoundException(meetingId)
                );
    }

    public Meeting createMeeting(Meeting meeting) {
        if (meeting.getStatus() == null ||
                meeting.getStatus().isBlank()) {

            meeting.setStatus("SCHEDULED");
        }

        return meetingRepository.save(meeting);
    }

    public Meeting updateMeeting(
            Long meetingId,
            Meeting updatedMeeting
    ) {
        Meeting existingMeeting = getMeetingById(meetingId);

        existingMeeting.setAppointmentId(
                updatedMeeting.getAppointmentId()
        );

        existingMeeting.setHostEmployeeEmail(
                updatedMeeting.getHostEmployeeEmail()
        );

        existingMeeting.setVisitorName(
                updatedMeeting.getVisitorName()
        );

        existingMeeting.setMeetingDate(
                updatedMeeting.getMeetingDate()
        );

        existingMeeting.setStartTime(
                updatedMeeting.getStartTime()
        );

        existingMeeting.setEndTime(
                updatedMeeting.getEndTime()
        );

        existingMeeting.setMeetingLocation(
                updatedMeeting.getMeetingLocation()
        );

        existingMeeting.setStatus(
                updatedMeeting.getStatus()
        );

        existingMeeting.setNotes(
                updatedMeeting.getNotes()
        );

        return meetingRepository.save(existingMeeting);
    }

    public void deleteMeeting(Long meetingId) {
        Meeting meeting = getMeetingById(meetingId);
        meetingRepository.delete(meeting);
    }
}
