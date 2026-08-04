package com.visilog.api.repository;

import com.visilog.api.entity.Appointment;
import com.visilog.api.entity.AppointmentStatus;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AppointmentRepository extends JpaRepository<Appointment, UUID> {
    List<Appointment> findByOrganizationIdOrderByScheduledAtDesc(UUID organizationId);
    Optional<Appointment> findByOrganizationIdAndId(UUID organizationId, UUID id);
    Optional<Appointment> findByOrganizationIdAndNfcCodeIgnoreCase(UUID organizationId, String nfcCode);
    List<Appointment> findByOrganizationIdAndBookedByEmailIgnoreCaseOrderByScheduledAtDesc(UUID organizationId, String email);

    // Appointments only carry a single scheduledAt instant (no
    // duration), so callers pass an already-widened [from, to) window
    // (see RoomBookingService.ASSUMED_APPOINTMENT_DURATION) to
    // approximate "is this host busy with a visitor around this time".
    List<Appointment> findByOrganizationIdAndHostIdAndScheduledAtBetweenAndStatusNot(
            UUID organizationId, UUID hostId, Instant from, Instant to, AppointmentStatus excludedStatus);

    // ReminderService's 30-min-before push job -- only confirmed
    // (ADMITTED) visits get reminded, and reminderSent stops a repeat
    // send on the next tick once one has gone out.
    List<Appointment> findByStatusAndReminderSentFalseAndScheduledAtBetween(
            AppointmentStatus status, Instant from, Instant to);
}
