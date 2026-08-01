package com.visilog.api.dto;

import com.visilog.api.entity.Appointment;
import java.time.Instant;
import java.util.UUID;

public record AppointmentDto(
        UUID id, String visitorName, String visitorPhone, String visitorEmail, String visitorCompany,
        String purpose, UUID hostId, Instant scheduledAt, String status, String nfcCode, String bookedByEmail,
        String rescheduleReason, Instant rescheduledAt, String rejectReason, boolean checkedIn
) {
    public static AppointmentDto from(Appointment a) {
        return new AppointmentDto(
                a.getId(), a.getVisitorName(), a.getVisitorPhone(), a.getVisitorEmail(), a.getVisitorCompany(),
                a.getPurpose(), a.getHostId(), a.getScheduledAt(), a.getStatus().name(), a.getNfcCode(),
                a.getBookedByEmail(), a.getRescheduleReason(), a.getRescheduledAt(), a.getRejectReason(),
                a.isCheckedIn());
    }
}
