package com.visilog.api.service;

import com.visilog.api.dto.AppointmentDto;
import com.visilog.api.dto.BookAppointmentRequest;
import com.visilog.api.dto.RescheduleRequest;
import com.visilog.api.dto.UpdateAppointmentStatusRequest;
import com.visilog.api.entity.Appointment;
import com.visilog.api.entity.AppointmentStatus;
import com.visilog.api.entity.Employee;
import com.visilog.api.entity.RoomBooking;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.AppointmentRepository;
import com.visilog.api.repository.EmployeeRepository;
import com.visilog.api.repository.RoomBookingRepository;
import com.visilog.api.security.AuthPrincipal;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AppointmentService {

    // Same assumed-visit-length window RoomBookingService uses for the
    // reverse check -- a visit has no stored duration, only a scheduledAt
    // instant, so this is how long it's assumed to occupy the host.
    private static final Duration ASSUMED_APPOINTMENT_DURATION = Duration.ofMinutes(30);

    private final AppointmentRepository appointmentRepository;
    private final VisitorService visitorService;
    private final RoomBookingRepository roomBookingRepository;
    private final EmployeeRepository employeeRepository;
    private final NotificationService notificationService;
    private final WorkingHoursService workingHoursService;

    public AppointmentService(
            AppointmentRepository appointmentRepository, VisitorService visitorService,
            RoomBookingRepository roomBookingRepository, EmployeeRepository employeeRepository,
            NotificationService notificationService, WorkingHoursService workingHoursService) {
        this.appointmentRepository = appointmentRepository;
        this.visitorService = visitorService;
        this.roomBookingRepository = roomBookingRepository;
        this.employeeRepository = employeeRepository;
        this.notificationService = notificationService;
        this.workingHoursService = workingHoursService;
    }

    // Reception sees every appointment in the org -- that's the front-desk
    // job, greeting whoever walks in regardless of host. Employees and
    // Managers only see appointments where *they* are the host: an
    // Administrator is staff too, and neither role should be able to see,
    // let alone admit or reject, a visit that isn't theirs to answer for.
    // Receptionists and Managers see every appointment in the org;
    // Employees see only the ones they're hosting.
    //
    // Managers used to be filtered down to their own hosted visits like
    // an Employee, which meant the person responsible for the whole
    // organization couldn't see what anyone else had booked. They're
    // the Administrator role (same one that owns Company Setup, the
    // staff roster and billing), so org-wide visibility is the point.
    public List<AppointmentDto> list(UUID organizationId, AuthPrincipal me) {
        List<Appointment> all = appointmentRepository.findByOrganizationIdOrderByScheduledAtDesc(organizationId);
        if ("EMPLOYEE".equals(me.role()) && me.employeeId() != null) {
            all = all.stream().filter(a -> me.employeeId().equals(a.getHostId())).toList();
        }
        return all.stream().map(AppointmentDto::from).toList();
    }

    public List<AppointmentDto> listForVisitor(UUID organizationId, String email) {
        return appointmentRepository
                .findByOrganizationIdAndBookedByEmailIgnoreCaseOrderByScheduledAtDesc(organizationId, email).stream()
                .map(AppointmentDto::from)
                .toList();
    }

    public AppointmentDto findByCode(UUID organizationId, String code) {
        Appointment a = appointmentRepository.findByOrganizationIdAndNfcCodeIgnoreCase(organizationId, code)
                .orElseThrow(() -> ApiException.notFound("No booking matches that code."));
        return AppointmentDto.from(a);
    }

    @Transactional
    public AppointmentDto book(UUID organizationId, BookAppointmentRequest req, String bookedByEmail) {
        Instant scheduledAt = req.scheduledAt() != null ? req.scheduledAt() : Instant.now();
        workingHoursService.requireWithinHours(organizationId, scheduledAt, "Booking a visit");
        checkHostAvailability(organizationId, req.hostId(), scheduledAt);

        Appointment a = new Appointment();
        a.setOrganizationId(organizationId);
        a.setVisitorName(req.visitorName().trim());
        a.setVisitorPhone(req.visitorPhone().trim());
        a.setVisitorEmail(req.visitorEmail());
        a.setVisitorCompany(req.visitorCompany());
        a.setPurpose(req.purpose());
        a.setHostId(req.hostId());
        a.setScheduledAt(scheduledAt);
        a.setStatus(AppointmentStatus.PENDING);
        a.setBookedByEmail(bookedByEmail);
        Appointment saved = appointmentRepository.save(a);
        notificationService.notifyAppointmentRequested(saved);
        return AppointmentDto.from(saved);
    }

    // The reverse of RoomBookingService's clash check: booking a visit
    // with a host who's already in a meeting, or already has another
    // visit, around that time went through silently before -- this is
    // what the user hit when a visitor booked with someone mid-meeting.
    private void checkHostAvailability(UUID organizationId, UUID hostId, Instant scheduledAt) {
        Instant windowStart = scheduledAt.minus(ASSUMED_APPOINTMENT_DURATION);
        Instant windowEnd = scheduledAt.plus(ASSUMED_APPOINTMENT_DURATION);

        List<RoomBooking> meetingClashes = roomBookingRepository.findOverlappingForPerson(
                organizationId, hostId, scheduledAt, windowEnd);
        if (!meetingClashes.isEmpty()) {
            throw ApiException.conflict(hostName(organizationId, hostId)
                    + " is in a meeting around that time -- try a different time.");
        }

        List<Appointment> appointmentClashes = appointmentRepository
                .findByOrganizationIdAndHostIdAndScheduledAtBetweenAndStatusNot(
                        organizationId, hostId, windowStart, windowEnd, AppointmentStatus.REJECTED);
        if (!appointmentClashes.isEmpty()) {
            throw ApiException.conflict(hostName(organizationId, hostId)
                    + " already has another visit booked around that time.");
        }
    }

    private String hostName(UUID organizationId, UUID hostId) {
        return employeeRepository.findByOrganizationIdAndId(organizationId, hostId)
                .map(Employee::getName)
                .orElse("This host");
    }

    @Transactional
    public AppointmentDto updateStatus(UUID organizationId, UUID appointmentId, UpdateAppointmentStatusRequest req, AuthPrincipal me) {
        Appointment a = findOrThrow(organizationId, appointmentId);
        requireHost(a, me);
        AppointmentStatus status = parseStatus(req.status());
        if (status == AppointmentStatus.REJECTED) {
            if (req.reason() == null || req.reason().trim().isEmpty()) {
                throw ApiException.badRequest("Please give a reason for rejecting this visit.");
            }
            a.setRejectReason(req.reason().trim());
        }
        a.setStatus(status);
        Appointment saved = appointmentRepository.save(a);
        if (status == AppointmentStatus.REJECTED) {
            notificationService.notifyAppointmentDecision(saved, false);
        }
        return AppointmentDto.from(saved);
    }

    // Admitting = approve the pending request. The visitor is not yet
    // on-site; reception still has to physically check them in when they
    // arrive (see checkIn below). Only valid from PENDING -- without this
    // guard, a double-tap created duplicate records.
    @Transactional
    public AppointmentDto admit(UUID organizationId, UUID appointmentId, AuthPrincipal me) {
        Appointment a = findOrThrow(organizationId, appointmentId);
        requireHost(a, me);
        if (a.getStatus() != AppointmentStatus.PENDING) {
            throw ApiException.conflict("This appointment has already been " + a.getStatus().name().toLowerCase(Locale.ROOT) + ".");
        }
        a.setStatus(AppointmentStatus.ADMITTED);
        a.setNfcCode(uniqueNfcCode(organizationId));
        appointmentRepository.save(a);
        notificationService.notifyAppointmentDecision(a, true);
        return AppointmentDto.from(a);
    }

    // Check-in = visitor physically arrives at reception. Creates the
    // Visitor on-site record. Only valid for an already-admitted appointment
    // that hasn't been checked in yet.
    @Transactional
    public AppointmentDto checkIn(UUID organizationId, UUID appointmentId) {
        Appointment a = findOrThrow(organizationId, appointmentId);
        if (a.getStatus() != AppointmentStatus.ADMITTED) {
            throw ApiException.conflict("This appointment must be admitted before checking in.");
        }
        if (a.isCheckedIn()) {
            throw ApiException.conflict("This visitor has already been checked in.");
        }
        a.setCheckedIn(true);
        Appointment saved = appointmentRepository.save(a);

        String[] parts = (a.getVisitorName() == null ? "" : a.getVisitorName()).trim().split(" ", 2);
        String firstName = parts.length > 0 ? parts[0] : "";
        String lastName = parts.length > 1 ? parts[1] : "";
        visitorService.registerAndCheckInInternal(
                organizationId, firstName, lastName, a.getVisitorPhone(), a.getVisitorEmail(), a.getVisitorCompany(),
                a.getPurpose(), a.getHostId());

        return AppointmentDto.from(saved);
    }

    @Transactional
    public AppointmentDto reschedule(UUID organizationId, UUID appointmentId, RescheduleRequest req) {
        Appointment a = findOrThrow(organizationId, appointmentId);
        workingHoursService.requireWithinHours(organizationId, req.newScheduledAt(), "Rescheduling a visit");
        a.setScheduledAt(req.newScheduledAt());
        a.setRescheduleReason(req.reason());
        a.setRescheduledAt(Instant.now());
        Appointment saved = appointmentRepository.save(a);
        notificationService.notifyAppointmentRescheduled(saved);
        return AppointmentDto.from(saved);
    }

    // No role is exempt: reception can see every appointment (for status
    // tracking -- "has this been admitted or rejected yet") but, like
    // everyone else, may only admit or reject one where they are the
    // actual host. Nobody acts on a visit that isn't theirs to answer for.
    private void requireHost(Appointment a, AuthPrincipal me) {
        if (me.employeeId() == null || !me.employeeId().equals(a.getHostId())) {
            throw ApiException.forbidden("Only the host this visit is for can admit or reject it.");
        }
    }

    private Appointment findOrThrow(UUID organizationId, UUID appointmentId) {
        return appointmentRepository.findByOrganizationIdAndId(organizationId, appointmentId)
                .orElseThrow(() -> ApiException.notFound("Appointment not found."));
    }

    private AppointmentStatus parseStatus(String raw) {
        try {
            return AppointmentStatus.valueOf(raw.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException ex) {
            throw ApiException.badRequest("status must be one of: pending, admitted, rejected.");
        }
    }

    private String uniqueNfcCode(UUID organizationId) {
        String code;
        do {
            code = CodeGenerator.generateVisitorCode();
        } while (appointmentRepository.findByOrganizationIdAndNfcCodeIgnoreCase(organizationId, code).isPresent());
        return code;
    }
}
