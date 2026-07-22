package com.visilog.api.service;

import com.visilog.api.dto.BookRoomRequest;
import com.visilog.api.dto.MarkAbsentRequest;
import com.visilog.api.dto.RespondToMeetingRequest;
import com.visilog.api.dto.RoomBookingDto;
import com.visilog.api.dto.RoomBookingResponseDto;
import com.visilog.api.entity.Appointment;
import com.visilog.api.entity.AppointmentStatus;
import com.visilog.api.entity.Employee;
import com.visilog.api.entity.ExternalGuest;
import com.visilog.api.entity.MeetingPriority;
import com.visilog.api.entity.MeetingRoom;
import com.visilog.api.entity.Organization;
import com.visilog.api.entity.RoomBooking;
import com.visilog.api.entity.RoomBookingResponse;
import com.visilog.api.entity.RoomBookingResponseStatus;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.AppointmentRepository;
import com.visilog.api.repository.EmployeeRepository;
import com.visilog.api.repository.MeetingRoomRepository;
import com.visilog.api.repository.OrganizationRepository;
import com.visilog.api.repository.RoomBookingRepository;
import com.visilog.api.repository.RoomBookingResponseRepository;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RoomBookingService {

    // Appointments only carry a single scheduledAt instant, no
    // duration -- a visit is assumed to occupy this much of the host's
    // time when checking it against a new meeting invite.
    private static final Duration ASSUMED_APPOINTMENT_DURATION = Duration.ofMinutes(30);
    private static final DateTimeFormatter WHEN_FORMAT =
            DateTimeFormatter.ofPattern("EEE d MMM, HH:mm 'UTC'").withZone(ZoneOffset.UTC);

    private final RoomBookingRepository roomBookingRepository;
    private final RoomBookingResponseRepository roomBookingResponseRepository;
    private final MeetingRoomRepository meetingRoomRepository;
    private final EmployeeRepository employeeRepository;
    private final AppointmentRepository appointmentRepository;
    private final OrganizationRepository organizationRepository;
    private final NotificationService notificationService;
    private final MailService mailService;

    public RoomBookingService(
            RoomBookingRepository roomBookingRepository, RoomBookingResponseRepository roomBookingResponseRepository,
            MeetingRoomRepository meetingRoomRepository, EmployeeRepository employeeRepository,
            AppointmentRepository appointmentRepository, OrganizationRepository organizationRepository,
            NotificationService notificationService, MailService mailService) {
        this.roomBookingRepository = roomBookingRepository;
        this.roomBookingResponseRepository = roomBookingResponseRepository;
        this.meetingRoomRepository = meetingRoomRepository;
        this.employeeRepository = employeeRepository;
        this.appointmentRepository = appointmentRepository;
        this.organizationRepository = organizationRepository;
        this.notificationService = notificationService;
        this.mailService = mailService;
    }

    // readOnly: RoomBookingDto.from reads the lazy participantIds
    // element collection -- needs an open session for the whole mapping,
    // not just the initial query.
    @Transactional(readOnly = true)
    public List<RoomBookingDto> list(UUID organizationId) {
        return roomBookingRepository.findByOrganizationIdOrderByStartTimeDesc(organizationId).stream()
                .map(b -> RoomBookingDto.from(b, responsesFor(b.getId())))
                .toList();
    }

    @Transactional
    public RoomBookingDto book(UUID organizationId, UUID organiserId, BookRoomRequest req) {
        if (organiserId == null) {
            throw ApiException.badRequest("Only staff accounts can book a meeting.");
        }
        if ((req.roomId() == null) == (req.location() == null || req.location().isBlank())) {
            throw ApiException.badRequest("Pick a meeting room or enter an outside location -- not both.");
        }
        if (req.endTime() != null && req.startTime() != null && !req.endTime().isAfter(req.startTime())) {
            throw ApiException.badRequest("End time must be after the start time.");
        }

        // Person-level clash check: neither the organiser nor anyone
        // they're inviting may already be in another meeting, or
        // already hosting a visitor appointment, at an overlapping
        // time -- regardless of which room or location this new one
        // uses.
        Set<UUID> people = new LinkedHashSet<>();
        people.add(organiserId);
        if (req.participantIds() != null) {
            people.addAll(req.participantIds());
        }
        for (UUID personId : people) {
            checkPersonAvailability(organizationId, personId, req.startTime(), req.endTime());
        }

        String roomName = null;
        if (req.roomId() != null) {
            MeetingRoom room = meetingRoomRepository.findByOrganizationIdAndId(organizationId, req.roomId())
                    .orElse(null);
            roomName = room != null ? room.getName() : "This room";
            List<RoomBooking> clashes = roomBookingRepository.findOverlapping(
                    organizationId, req.roomId(), req.startTime(), req.endTime());
            if (!clashes.isEmpty()) {
                throw ApiException.conflict(
                        roomName + " is already booked for that time -- pick a different time or room.");
            }
        }

        RoomBooking b = new RoomBooking();
        b.setOrganizationId(organizationId);
        b.setRoomId(req.roomId());
        b.setLocation(req.roomId() == null ? req.location().trim() : null);
        b.setOrganiserId(organiserId);
        b.setTitle(req.title().trim());
        b.setStartTime(req.startTime());
        b.setEndTime(req.endTime());
        if (req.participantIds() != null) {
            b.getParticipantIds().addAll(req.participantIds());
        }
        if (req.externalGuests() != null) {
            for (BookRoomRequest.ExternalGuestRequest g : req.externalGuests()) {
                if (g.name() == null && g.email() == null && g.phone() == null) {
                    continue;
                }
                ExternalGuest guest = new ExternalGuest();
                guest.setName(g.name());
                guest.setEmail(g.email());
                guest.setPhone(g.phone());
                b.getExternalGuests().add(guest);
            }
        }
        b.setPriority(parsePriority(req.priority()));
        RoomBooking saved = roomBookingRepository.save(b);

        String organiserName = employeeRepository.findByOrganizationIdAndId(organizationId, organiserId)
                .map(Employee::getName).orElse("A colleague");
        String placeLabel = roomName != null ? roomName : saved.getLocation();
        notificationService.notifyMeetingInvite(saved, organiserName, placeLabel);

        Organization org = organizationRepository.findById(organizationId).orElse(null);
        if (org != null) {
            String when = WHEN_FORMAT.format(saved.getStartTime());
            for (ExternalGuest guest : saved.getExternalGuests()) {
                if (guest.getEmail() != null && !guest.getEmail().isBlank()) {
                    mailService.sendMeetingInvite(
                            guest.getEmail(), guest.getName(), organiserName, org.getName(), org.getCode(),
                            saved.getTitle(), when, placeLabel);
                }
            }
        }

        // A pending response row per invited participant -- the surface
        // for "seen it" (acknowledge) / "can't make it" (decline + why).
        for (UUID participantId : saved.getParticipantIds()) {
            if (participantId.equals(organiserId)) {
                continue;
            }
            RoomBookingResponse r = new RoomBookingResponse();
            r.setOrganizationId(organizationId);
            r.setRoomBookingId(saved.getId());
            r.setEmployeeId(participantId);
            roomBookingResponseRepository.save(r);
        }

        return RoomBookingDto.from(saved, responsesFor(saved.getId()));
    }

    // A participant acknowledging ("seen it") or declining (with a
    // reason, so the organiser knows why) their invite. Only someone
    // actually invited to this meeting has a response row to update.
    @Transactional
    public RoomBookingDto respond(UUID organizationId, UUID roomBookingId, UUID employeeId, RespondToMeetingRequest req) {
        RoomBooking booking = roomBookingRepository.findById(roomBookingId)
                .filter(b -> b.getOrganizationId().equals(organizationId))
                .orElseThrow(() -> ApiException.notFound("Meeting not found."));
        RoomBookingResponse response = roomBookingResponseRepository
                .findByRoomBookingIdAndEmployeeId(roomBookingId, employeeId)
                .orElseThrow(() -> ApiException.forbidden("You weren't invited to this meeting."));

        RoomBookingResponseStatus status;
        try {
            status = RoomBookingResponseStatus.valueOf(req.status().trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException ex) {
            throw ApiException.badRequest("status must be either acknowledged or declined.");
        }
        if (status == RoomBookingResponseStatus.PENDING) {
            throw ApiException.badRequest("status must be either acknowledged or declined.");
        }
        if (status == RoomBookingResponseStatus.DECLINED && (req.reason() == null || req.reason().isBlank())) {
            throw ApiException.badRequest("Let the organiser know why you can't make it.");
        }

        response.setStatus(status);
        response.setDeclineReason(status == RoomBookingResponseStatus.DECLINED ? req.reason().trim() : null);
        response.setRespondedAt(Instant.now());
        roomBookingResponseRepository.save(response);

        if (status == RoomBookingResponseStatus.DECLINED) {
            String declinerName = employeeRepository.findByOrganizationIdAndId(organizationId, employeeId)
                    .map(Employee::getName).orElse("A colleague");
            notificationService.notifyDecline(booking, declinerName, response.getDeclineReason());
        }

        return RoomBookingDto.from(booking, responsesFor(roomBookingId));
    }

    // Marking who actually showed up -- organiser only, and independent
    // of whether that person acknowledged or declined beforehand
    // (acknowledging an invite doesn't guarantee they attended).
    @Transactional
    public RoomBookingDto markAbsent(
            UUID organizationId, UUID callerId, UUID roomBookingId, UUID employeeId, MarkAbsentRequest req) {
        RoomBooking booking = roomBookingRepository.findById(roomBookingId)
                .filter(b -> b.getOrganizationId().equals(organizationId))
                .orElseThrow(() -> ApiException.notFound("Meeting not found."));
        if (!booking.getOrganiserId().equals(callerId)) {
            throw ApiException.forbidden("Only the organiser can mark attendance for this meeting.");
        }
        RoomBookingResponse response = roomBookingResponseRepository
                .findByRoomBookingIdAndEmployeeId(roomBookingId, employeeId)
                .orElseThrow(() -> ApiException.notFound("That person wasn't invited to this meeting."));

        response.setAbsent(req.absent());
        roomBookingResponseRepository.save(response);

        return RoomBookingDto.from(booking, responsesFor(roomBookingId));
    }

    private List<RoomBookingResponseDto> responsesFor(UUID roomBookingId) {
        return roomBookingResponseRepository.findByRoomBookingId(roomBookingId).stream()
                .map(RoomBookingResponseDto::from)
                .toList();
    }

    private MeetingPriority parsePriority(String raw) {
        if (raw == null || raw.isBlank()) {
            return MeetingPriority.NORMAL;
        }
        try {
            return MeetingPriority.valueOf(raw.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException ex) {
            throw ApiException.badRequest("priority must be one of: normal, important, urgent.");
        }
    }

    private void checkPersonAvailability(UUID organizationId, UUID employeeId, Instant startTime, Instant endTime) {
        List<RoomBooking> meetingClashes = roomBookingRepository.findOverlappingForPerson(
                organizationId, employeeId, startTime, endTime);
        if (!meetingClashes.isEmpty()) {
            throw ApiException.conflict(employeeName(organizationId, employeeId)
                    + " already has another meeting at that time.");
        }

        List<Appointment> appointmentClashes = appointmentRepository
                .findByOrganizationIdAndHostIdAndScheduledAtBetweenAndStatusNot(
                        organizationId, employeeId, startTime.minus(ASSUMED_APPOINTMENT_DURATION), endTime,
                        AppointmentStatus.REJECTED);
        if (!appointmentClashes.isEmpty()) {
            throw ApiException.conflict(employeeName(organizationId, employeeId)
                    + " already has a visitor appointment around that time.");
        }
    }

    private String employeeName(UUID organizationId, UUID employeeId) {
        return employeeRepository.findByOrganizationIdAndId(organizationId, employeeId)
                .map(Employee::getName)
                .orElse("This person");
    }
}