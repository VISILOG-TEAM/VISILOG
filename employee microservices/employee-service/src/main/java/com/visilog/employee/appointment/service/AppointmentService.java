package com.visilog.employee.appointment.service;
import java.util.List;

import org.springframework.stereotype.Service;

import com.visilog.employee.appointment.exception.AppointmentNotFoundException;
import com.visilog.employee.appointment.model.Appointment;
import com.visilog.employee.appointment.repository.AppointmentRepository;

@Service
public class AppointmentService {

    private final AppointmentRepository appointmentRepository;

    public AppointmentService(AppointmentRepository appointmentRepository) {
        this.appointmentRepository = appointmentRepository;
    }

    public List<Appointment> getAllAppointments() {
        return appointmentRepository.findAll();
    }

    public Appointment getAppointmentById(Long appointmentId) {
        return appointmentRepository.findById(appointmentId)
                .orElseThrow(() ->
                        new AppointmentNotFoundException(appointmentId)
                );
    }

    public Appointment createAppointment(Appointment appointment) {
        return appointmentRepository.save(appointment);
    }

    public Appointment updateAppointment(
            Long appointmentId,
            Appointment updatedAppointment
    ) {
        Appointment existingAppointment =
                getAppointmentById(appointmentId);

        /*
         * We will add the setter methods here after checking
         * the exact fields inside Appointment.java.
         */

        return appointmentRepository.save(existingAppointment);
    }

public Appointment updateAppointmentStatus(
        Long appointmentId,
        String status
) {
    Appointment appointment = getAppointmentById(appointmentId);

    appointment.setStatus(status.toUpperCase());

    return appointmentRepository.save(appointment);
}

    public void deleteAppointment(Long appointmentId) {
        Appointment appointment =
                getAppointmentById(appointmentId);

        appointmentRepository.delete(appointment);
    }
}