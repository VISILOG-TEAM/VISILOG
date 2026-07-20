package com.visilog.employee.appointment.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.visilog.employee.appointment.model.Appointment;
import com.visilog.employee.appointment.service.AppointmentService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/appointments")
public class AppointmentController {

    private final AppointmentService appointmentService;

    public AppointmentController(
            AppointmentService appointmentService
    ) {
        this.appointmentService = appointmentService;
    }

    @GetMapping
    public ResponseEntity<List<Appointment>> getAllAppointments() {
        return ResponseEntity.ok(
                appointmentService.getAllAppointments()
        );
    }

    @GetMapping("/{appointmentId}")
    public ResponseEntity<Appointment> getAppointmentById(
            @PathVariable Long appointmentId
    ) {
        return ResponseEntity.ok(
                appointmentService.getAppointmentById(appointmentId)
        );
    }

    @PostMapping
    public ResponseEntity<Appointment> createAppointment(
            @Valid @RequestBody Appointment appointment
    ) {
        Appointment createdAppointment =
                appointmentService.createAppointment(appointment);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(createdAppointment);
    }

    @PutMapping("/{appointmentId}")
    public ResponseEntity<Appointment> updateAppointment(
            @PathVariable Long appointmentId,
            @Valid @RequestBody Appointment appointment
    ) {
        return ResponseEntity.ok(
                appointmentService.updateAppointment(
                        appointmentId,
                        appointment
                )
        );
    }

    @PatchMapping("/{appointmentId}/status")
public ResponseEntity<Appointment> updateAppointmentStatus(
        @PathVariable Long appointmentId,
        @RequestParam String status
) {
    return ResponseEntity.ok(
            appointmentService.updateAppointmentStatus(
                    appointmentId,
                    status
            )
    );
}

    @DeleteMapping("/{appointmentId}")
    public ResponseEntity<Void> deleteAppointment(
            @PathVariable Long appointmentId
    ) {
        appointmentService.deleteAppointment(appointmentId);

        return ResponseEntity.noContent().build();
    }
}