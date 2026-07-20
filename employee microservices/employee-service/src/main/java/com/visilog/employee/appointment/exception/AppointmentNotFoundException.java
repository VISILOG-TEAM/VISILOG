package com.visilog.employee.appointment.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class AppointmentNotFoundException extends RuntimeException {

    public AppointmentNotFoundException(Long appointmentId) {
        super("Appointment not found with ID: " + appointmentId);
    }
}