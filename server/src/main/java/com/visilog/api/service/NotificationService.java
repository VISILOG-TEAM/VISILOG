package com.visilog.api.service;

import com.visilog.api.dto.NotificationDto;
import com.visilog.api.entity.Appointment;
import com.visilog.api.entity.Call;
import com.visilog.api.entity.Notification;
import com.visilog.api.entity.NotificationType;
import com.visilog.api.entity.RoomBooking;
import com.visilog.api.entity.Visitor;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.NotificationRepository;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NotificationService {

    private static final DateTimeFormatter WHEN_FORMAT =
            DateTimeFormatter.ofPattern("EEE d MMM, HH:mm 'UTC'").withZone(ZoneOffset.UTC);

    private final NotificationRepository notificationRepository;

    public NotificationService(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    // Staff are addressed by employee id; visitors (no employee record)
    // by their account email -- exactly one of the two is non-null for
    // any given caller.
    @Transactional(readOnly = true)
    public List<NotificationDto> list(UUID organizationId, UUID recipientEmployeeId, String recipientEmail) {
        List<Notification> found = recipientEmployeeId != null
                ? notificationRepository.findByOrganizationIdAndRecipientEmployeeIdOrderByCreatedAtDesc(
                        organizationId, recipientEmployeeId)
                : notificationRepository.findByOrganizationIdAndRecipientEmailIgnoreCaseOrderByCreatedAtDesc(
                        organizationId, recipientEmail);
        return found.stream().map(NotificationDto::from).toList();
    }

    @Transactional
    public NotificationDto markRead(UUID organizationId, UUID id, UUID recipientEmployeeId, String recipientEmail) {
        Notification n = notificationRepository.findByOrganizationIdAndId(organizationId, id)
                .orElseThrow(() -> ApiException.notFound("Notification not found."));
        boolean isMine = recipientEmployeeId != null
                ? recipientEmployeeId.equals(n.getRecipientEmployeeId())
                : recipientEmail != null && recipientEmail.equalsIgnoreCase(n.getRecipientEmail());
        if (!isMine) {
            throw ApiException.forbidden("This notification isn't yours.");
        }
        n.setRead(true);
        return NotificationDto.from(notificationRepository.save(n));
    }

    // One notification per invited participant -- the organiser doesn't
    // need telling about their own meeting.
    @Transactional
    public void notifyMeetingInvite(RoomBooking booking, String organiserName, String placeLabel) {
        String when = WHEN_FORMAT.format(booking.getStartTime());
        String body = organiserName + " invited you to \"" + booking.getTitle() + "\" - " + when
                + (placeLabel != null && !placeLabel.isBlank() ? " - " + placeLabel : "");
        for (UUID participantId : booking.getParticipantIds()) {
            if (participantId.equals(booking.getOrganiserId())) {
                continue;
            }
            Notification n = new Notification();
            n.setOrganizationId(booking.getOrganizationId());
            n.setRecipientEmployeeId(participantId);
            n.setType(NotificationType.MEETING_INVITE);
            n.setTitle("Meeting invite");
            n.setBody(body);
            n.setRelatedId(booking.getId());
            n.setCreatedAt(Instant.now());
            notificationRepository.save(n);
        }
    }

    // Tells the organiser someone they invited isn't coming, and why.
    @Transactional
    public void notifyDecline(RoomBooking booking, String declinerName, String reason) {
        Notification n = new Notification();
        n.setOrganizationId(booking.getOrganizationId());
        n.setRecipientEmployeeId(booking.getOrganiserId());
        n.setType(NotificationType.MEETING_DECLINED);
        n.setTitle("Meeting declined");
        n.setBody(declinerName + " can't make \"" + booking.getTitle() + "\" - " + reason);
        n.setRelatedId(booking.getId());
        n.setCreatedAt(Instant.now());
        notificationRepository.save(n);
    }

    // Told to the organiser when someone they invited acknowledges
    // ("seen it") their invite -- the reverse of notifyDecline, so the
    // organiser learns who's seen the invite and when without checking
    // each participant's response one by one.
    @Transactional
    public void notifyAcknowledge(RoomBooking booking, String acknowledgerName, Instant when) {
        Notification n = new Notification();
        n.setOrganizationId(booking.getOrganizationId());
        n.setRecipientEmployeeId(booking.getOrganiserId());
        n.setType(NotificationType.MEETING_ACKNOWLEDGED);
        n.setTitle("Meeting invite seen");
        n.setBody(acknowledgerName + " has seen your invite to \"" + booking.getTitle() + "\" - "
                + WHEN_FORMAT.format(when));
        n.setRelatedId(booking.getId());
        n.setCreatedAt(Instant.now());
        notificationRepository.save(n);
    }

    // Only visitors who booked their own visit have an app account to
    // notify (bookedByEmail is null for a walk-in reception booked on
    // someone's behalf) -- silently a no-op otherwise.
    @Transactional
    public void notifyAppointmentDecision(Appointment appointment, boolean admitted) {
        if (appointment.getBookedByEmail() == null || appointment.getBookedByEmail().isBlank()) {
            return;
        }
        Notification n = new Notification();
        n.setOrganizationId(appointment.getOrganizationId());
        n.setRecipientEmail(appointment.getBookedByEmail());
        n.setType(admitted ? NotificationType.VISIT_ADMITTED : NotificationType.VISIT_REJECTED);
        n.setTitle(admitted ? "Your visit is confirmed" : "Your visit request was declined");
        n.setBody(admitted
                ? "You're all set - your visitor pass code is " + appointment.getNfcCode() + ". Show it at reception."
                : (appointment.getRejectReason() != null && !appointment.getRejectReason().isBlank()
                        ? "Reason: " + appointment.getRejectReason()
                        : "Your host wasn't able to confirm this visit."));
        n.setRelatedId(appointment.getId());
        n.setCreatedAt(Instant.now());
        notificationRepository.save(n);
    }

    // Told to the host when their visitor leaves, so they know without
    // having to check the Visitors log themselves.
    @Transactional
    public void notifyVisitorCheckedOut(Visitor visitor) {
        if (visitor.getHostId() == null) {
            return;
        }
        Notification n = new Notification();
        n.setOrganizationId(visitor.getOrganizationId());
        n.setRecipientEmployeeId(visitor.getHostId());
        n.setType(NotificationType.VISIT_CHECKED_OUT);
        n.setTitle("Visitor checked out");
        n.setBody(visitor.getFullName() + " has checked out.");
        n.setRelatedId(visitor.getId());
        n.setCreatedAt(Instant.now());
        notificationRepository.save(n);
    }

    // Told to the host as soon as someone requests a visit with them,
    // so a pending appointment doesn't sit unnoticed until they happen
    // to open the Appointments tab.
    @Transactional
    public void notifyAppointmentRequested(Appointment appointment) {
        if (appointment.getHostId() == null) {
            return;
        }
        Notification n = new Notification();
        n.setOrganizationId(appointment.getOrganizationId());
        n.setRecipientEmployeeId(appointment.getHostId());
        n.setType(NotificationType.APPOINTMENT_REQUESTED);
        n.setTitle("New visit request");
        n.setBody(appointment.getVisitorName() + " wants to visit - " + appointment.getPurpose());
        n.setRelatedId(appointment.getId());
        n.setCreatedAt(Instant.now());
        notificationRepository.save(n);
    }

    // Only a visitor who booked their own visit has an app account to
    // notify (bookedByEmail is null for a walk-in reception booked on
    // someone's behalf) -- silently a no-op otherwise, same as
    // notifyAppointmentDecision.
    @Transactional
    public void notifyAppointmentRescheduled(Appointment appointment) {
        if (appointment.getBookedByEmail() == null || appointment.getBookedByEmail().isBlank()) {
            return;
        }
        Notification n = new Notification();
        n.setOrganizationId(appointment.getOrganizationId());
        n.setRecipientEmail(appointment.getBookedByEmail());
        n.setType(NotificationType.APPOINTMENT_RESCHEDULED);
        n.setTitle("Your visit was rescheduled");
        n.setBody("New time: " + WHEN_FORMAT.format(appointment.getScheduledAt())
                + (appointment.getRescheduleReason() != null && !appointment.getRescheduleReason().isBlank()
                        ? " - " + appointment.getRescheduleReason() : ""));
        n.setRelatedId(appointment.getId());
        n.setCreatedAt(Instant.now());
        notificationRepository.save(n);
    }

    // Told to whoever a call was for, so a missed call doesn't sit
    // unseen until they happen to open the Call log.
    @Transactional
    public void notifyCallLogged(Call call) {
        if (call.getHostId() == null) {
            return;
        }
        Notification n = new Notification();
        n.setOrganizationId(call.getOrganizationId());
        n.setRecipientEmployeeId(call.getHostId());
        n.setType(NotificationType.CALL_LOGGED);
        n.setTitle("New call logged for you");
        n.setBody(call.getCallerName() + " - " + call.getCallType().name().toLowerCase(Locale.ROOT)
                + (call.getPurpose() != null && !call.getPurpose().isBlank() ? " - " + call.getPurpose() : ""));
        n.setRelatedId(call.getId());
        n.setCreatedAt(Instant.now());
        notificationRepository.save(n);
    }

    // Told to the participant themselves when the organiser marks them
    // absent after the fact -- not sent when un-marking (toggling back
    // to present isn't something they need pinged about).
    @Transactional
    public void notifyParticipantAbsent(RoomBooking booking, UUID employeeId) {
        Notification n = new Notification();
        n.setOrganizationId(booking.getOrganizationId());
        n.setRecipientEmployeeId(employeeId);
        n.setType(NotificationType.PARTICIPANT_ABSENT);
        n.setTitle("Marked absent");
        n.setBody("You were marked absent from \"" + booking.getTitle() + "\".");
        n.setRelatedId(booking.getId());
        n.setCreatedAt(Instant.now());
        notificationRepository.save(n);
    }
}