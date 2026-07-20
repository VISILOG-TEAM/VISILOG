package com.visilog.employee.meeting.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.visilog.employee.meeting.model.Meeting;

public interface MeetingRepository
        extends JpaRepository<Meeting, Long> {

    List<Meeting> findByHostEmployeeEmail(String hostEmployeeEmail);

    List<Meeting> findByStatus(String status);

    List<Meeting> findByAppointmentId(Long appointmentId);
}