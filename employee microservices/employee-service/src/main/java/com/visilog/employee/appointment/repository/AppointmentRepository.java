package com.visilog.employee.appointment.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.visilog.employee.appointment.model.Appointment;

public interface AppointmentRepository extends JpaRepository<Appointment, Long> {

    List<Appointment> findByHostEmployeeEmail(String hostEmployeeEmail);

    List<Appointment> findByStatus(String status);

}