package com.visilog.employee.appointment.model;

import java.time.LocalDate;
import java.time.LocalTime;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

@Entity
@Table(name = "appointments")
public class Appointment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long appointmentId;

    @NotBlank(message = "Visitor name is required")
    private String visitorName;

    @NotBlank(message = "Visitor email is required")
    @Email(message = "Visitor email must be valid")
    private String visitorEmail;

    @Pattern(
            regexp = "^[0-9]{10}$",
            message = "Visitor phone number must contain exactly 10 digits"
    )
    private String visitorPhone;

    @NotBlank(message = "Host employee email is required")
    @Email(message = "Host employee email must be valid")
    private String hostEmployeeEmail;

    @NotNull(message = "Appointment date is required")
    private LocalDate appointmentDate;

    @NotNull(message = "Appointment time is required")
    private LocalTime appointmentTime;

    @NotBlank(message = "Purpose is required")
    private String purpose;

    private String status;

    public Appointment() {
        this.status = "PENDING";
    }

    public Appointment(
            Long appointmentId,
            String visitorName,
            String visitorEmail,
            String visitorPhone,
            String hostEmployeeEmail,
            LocalDate appointmentDate,
            LocalTime appointmentTime,
            String purpose,
            String status
    ) {
        this.appointmentId = appointmentId;
        this.visitorName = visitorName;
        this.visitorEmail = visitorEmail;
        this.visitorPhone = visitorPhone;
        this.hostEmployeeEmail = hostEmployeeEmail;
        this.appointmentDate = appointmentDate;
        this.appointmentTime = appointmentTime;
        this.purpose = purpose;
        this.status = status;
    }

    public Long getAppointmentId() {
        return appointmentId;
    }

    public void setAppointmentId(Long appointmentId) {
        this.appointmentId = appointmentId;
    }

    public String getVisitorName() {
        return visitorName;
    }

    public void setVisitorName(String visitorName) {
        this.visitorName = visitorName;
    }

    public String getVisitorEmail() {
        return visitorEmail;
    }

    public void setVisitorEmail(String visitorEmail) {
        this.visitorEmail = visitorEmail;
    }

    public String getVisitorPhone() {
        return visitorPhone;
    }

    public void setVisitorPhone(String visitorPhone) {
        this.visitorPhone = visitorPhone;
    }

    public String getHostEmployeeEmail() {
        return hostEmployeeEmail;
    }

    public void setHostEmployeeEmail(String hostEmployeeEmail) {
        this.hostEmployeeEmail = hostEmployeeEmail;
    }

    public LocalDate getAppointmentDate() {
        return appointmentDate;
    }

    public void setAppointmentDate(LocalDate appointmentDate) {
        this.appointmentDate = appointmentDate;
    }

    public LocalTime getAppointmentTime() {
        return appointmentTime;
    }

    public void setAppointmentTime(LocalTime appointmentTime) {
        this.appointmentTime = appointmentTime;
    }

    public String getPurpose() {
        return purpose;
    }

    public void setPurpose(String purpose) {
        this.purpose = purpose;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}