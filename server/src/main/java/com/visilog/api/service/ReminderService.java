package com.visilog.api.service;

import com.visilog.api.entity.Appointment;
import com.visilog.api.entity.AppointmentStatus;
import com.visilog.api.entity.RoomBooking;
import com.visilog.api.entity.RoomBookingResponse;
import com.visilog.api.entity.RoomBookingResponseStatus;
import com.visilog.api.repository.AppointmentRepository;
import com.visilog.api.repository.RoomBookingRepository;
import com.visilog.api.repository.RoomBookingResponseRepository;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Ticks every minute looking for anything starting 25-35 minutes out
// that hasn't been reminded yet. The window is wider than exactly 30
// minutes on purpose -- it's slack for scheduler jitter or the app
// having been briefly down, not a precision target; reminderSent (not
// the window) is what actually stops a repeat send once one has gone
// out. See PushNotificationService for why nothing arrives on a phone
// still running this app through Expo Go rather than a dev build.
@Service
public class ReminderService {

    private static final DateTimeFormatter WHEN_FORMAT =
            DateTimeFormatter.ofPattern("EEE d MMM, HH:mm 'UTC'").withZone(ZoneOffset.UTC);

    private final AppointmentRepository appointmentRepository;
    private final RoomBookingRepository roomBookingRepository;
    private final RoomBookingResponseRepository roomBookingResponseRepository;
    private final PushTokenService pushTokenService;
    private final PushNotificationService pushNotificationService;

    public ReminderService(
            AppointmentRepository appointmentRepository, RoomBookingRepository roomBookingRepository,
            RoomBookingResponseRepository roomBookingResponseRepository,
            PushTokenService pushTokenService, PushNotificationService pushNotificationService) {
        this.appointmentRepository = appointmentRepository;
        this.roomBookingRepository = roomBookingRepository;
        this.roomBookingResponseRepository = roomBookingResponseRepository;
        this.pushTokenService = pushTokenService;
        this.pushNotificationService = pushNotificationService;
    }

    @Scheduled(fixedRate = 60000)
    @Transactional
    public void sendDueReminders() {
        Instant from = Instant.now().plus(Duration.ofMinutes(25));
        Instant to = Instant.now().plus(Duration.ofMinutes(35));
        remindAppointments(from, to);
        remindMeetings(from, to);
    }

    // Only confirmed (ADMITTED) visits get reminded -- a still-pending
    // request isn't guaranteed to happen. Hosts always get a push if
    // they have a token; the visitor only does if they booked their own
    // visit and have a linked account (bookedByEmail), same condition
    // NotificationService uses for in-app visitor notifications.
    private void remindAppointments(Instant from, Instant to) {
        List<Appointment> due = appointmentRepository
                .findByStatusAndReminderSentFalseAndScheduledAtBetween(AppointmentStatus.ADMITTED, from, to);
        for (Appointment a : due) {
            String when = WHEN_FORMAT.format(a.getScheduledAt());
            List<String> tokens = new ArrayList<>();
            if (a.getHostId() != null) {
                tokens.addAll(pushTokenService.tokensFor(a.getOrganizationId(), a.getHostId()));
            }
            tokens.addAll(pushTokenService.tokensForVisitor(a.getOrganizationId(), a.getBookedByEmail()));
            pushNotificationService.send(tokens, "Upcoming visit", a.getVisitorName() + " - " + when);
            a.setReminderSent(true);
            appointmentRepository.save(a);
        }
    }

    // Organiser plus every participant who hasn't already declined --
    // no point reminding someone who's already said they can't make it.
    private void remindMeetings(Instant from, Instant to) {
        List<RoomBooking> due = roomBookingRepository.findByReminderSentFalseAndStartTimeBetween(from, to);
        for (RoomBooking b : due) {
            String when = WHEN_FORMAT.format(b.getStartTime());
            List<UUID> declined = roomBookingResponseRepository.findByRoomBookingId(b.getId()).stream()
                    .filter(r -> r.getStatus() == RoomBookingResponseStatus.DECLINED)
                    .map(RoomBookingResponse::getEmployeeId)
                    .toList();

            List<UUID> attendees = new ArrayList<>();
            attendees.add(b.getOrganiserId());
            for (UUID participantId : b.getParticipantIds()) {
                if (!declined.contains(participantId)) {
                    attendees.add(participantId);
                }
            }
            List<String> tokens = new ArrayList<>();
            for (UUID employeeId : attendees) {
                tokens.addAll(pushTokenService.tokensFor(b.getOrganizationId(), employeeId));
            }
            pushNotificationService.send(tokens, "Upcoming meeting", b.getTitle() + " - " + when);
            b.setReminderSent(true);
            roomBookingRepository.save(b);
        }
    }
}
