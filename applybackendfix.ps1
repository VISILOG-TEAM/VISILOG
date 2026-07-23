$ErrorActionPreference = "Stop"

@'
package com.visilog.api.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// A pre-booked visit, made either by the visitor themselves (self-
// service, carries bookedByEmail) or by reception on a visitor's
// behalf. Admitting one creates a matching Visitor check-in record --
// see AppointmentService.admit.
@Entity
@Table(name = "appointments", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"organization_id", "nfc_code"})
})
@Getter
@Setter
@NoArgsConstructor
public class Appointment {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    private String visitorName;
    private String visitorPhone;
    private String visitorEmail;
    private String visitorCompany;
    private String purpose;
    private UUID hostId;

    @Column(nullable = false)
    private Instant scheduledAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private AppointmentStatus status;

    @Column(nullable = false)
    private String nfcCode;

    private String bookedByEmail;

    @Column(length = 1000)
    private String rescheduleReason;
    private Instant rescheduledAt;

    @Column(name = "reject_reason", length = 1000)
    private String rejectReason;
}
'@ | Set-Content -Path "server\src\main\java\com\visilog\api\entity\Appointment.java" -Encoding utf8

@'
package com.visilog.api.dto;

import com.visilog.api.entity.Appointment;
import java.time.Instant;
import java.util.UUID;

public record AppointmentDto(
        UUID id, String visitorName, String visitorPhone, String visitorEmail, String visitorCompany,
        String purpose, UUID hostId, Instant scheduledAt, String status, String nfcCode, String bookedByEmail,
        String rescheduleReason, Instant rescheduledAt, String rejectReason
) {
    public static AppointmentDto from(Appointment a) {
        return new AppointmentDto(
                a.getId(), a.getVisitorName(), a.getVisitorPhone(), a.getVisitorEmail(), a.getVisitorCompany(),
                a.getPurpose(), a.getHostId(), a.getScheduledAt(), a.getStatus().name(), a.getNfcCode(),
                a.getBookedByEmail(), a.getRescheduleReason(), a.getRescheduledAt(), a.getRejectReason());
    }
}
'@ | Set-Content -Path "server\src\main\java\com\visilog\api\dto\AppointmentDto.java" -Encoding utf8

@'
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

    public AppointmentService(
            AppointmentRepository appointmentRepository, VisitorService visitorService,
            RoomBookingRepository roomBookingRepository, EmployeeRepository employeeRepository) {
        this.appointmentRepository = appointmentRepository;
        this.visitorService = visitorService;
        this.roomBookingRepository = roomBookingRepository;
        this.employeeRepository = employeeRepository;
    }

    // Reception sees every appointment in the org -- that's the front-desk
    // job, greeting whoever walks in regardless of host. Employees and
    // Managers only see appointments where *they* are the host: an
    // Administrator is staff too, and neither role should be able to see,
    // let alone admit or reject, a visit that isn't theirs to answer for.
    public List<AppointmentDto> list(UUID organizationId, AuthPrincipal me) {
        List<Appointment> all = appointmentRepository.findByOrganizationIdOrderByScheduledAtDesc(organizationId);
        if (("EMPLOYEE".equals(me.role()) || "MANAGER".equals(me.role())) && me.employeeId() != null) {
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
        a.setNfcCode(uniqueNfcCode(organizationId));
        a.setBookedByEmail(bookedByEmail);
        return AppointmentDto.from(appointmentRepository.save(a));
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
        return AppointmentDto.from(appointmentRepository.save(a));
    }

    // Admitting = approve the pending request AND check the visitor in,
    // in one step, so reception doesn't repeat the visitor's details.
    // Only valid from PENDING -- without this guard, a double-tap (or a
    // retry after a slow response) created a brand new Visitor check-in
    // record every single time it was called, with no limit.
    @Transactional
    public AppointmentDto admit(UUID organizationId, UUID appointmentId, AuthPrincipal me) {
        Appointment a = findOrThrow(organizationId, appointmentId);
        requireHost(a, me);
        if (a.getStatus() != AppointmentStatus.PENDING) {
            throw ApiException.conflict("This appointment has already been " + a.getStatus().name().toLowerCase(Locale.ROOT) + ".");
        }
        a.setStatus(AppointmentStatus.ADMITTED);
        appointmentRepository.save(a);

        String[] parts = (a.getVisitorName() == null ? "" : a.getVisitorName()).trim().split(" ", 2);
        String firstName = parts.length > 0 ? parts[0] : "";
        String lastName = parts.length > 1 ? parts[1] : "";
        visitorService.registerAndCheckInInternal(
                organizationId, firstName, lastName, a.getVisitorPhone(), a.getVisitorEmail(), a.getVisitorCompany(),
                a.getPurpose(), a.getHostId());

        return AppointmentDto.from(a);
    }

    @Transactional
    public AppointmentDto reschedule(UUID organizationId, UUID appointmentId, RescheduleRequest req) {
        Appointment a = findOrThrow(organizationId, appointmentId);
        a.setScheduledAt(req.newScheduledAt());
        a.setRescheduleReason(req.reason());
        a.setRescheduledAt(Instant.now());
        return AppointmentDto.from(appointmentRepository.save(a));
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
'@ | Set-Content -Path "server\src\main\java\com\visilog\api\service\AppointmentService.java" -Encoding utf8

@'
package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;

public record UpdateAppointmentStatusRequest(@NotBlank(message = "is required") String status, String reason) {
}
'@ | Set-Content -Path "server\src\main\java\com\visilog\api\dto\UpdateAppointmentStatusRequest.java" -Encoding utf8

@'
package com.visilog.api.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// Admin-managed in Company Setup -- the rooms selectable in
// BookMeetingForm on the frontend and shown on the visitor map tour.
@Entity
@Table(name = "meeting_rooms")
@Getter
@Setter
@NoArgsConstructor
public class MeetingRoom {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    @Column(nullable = false)
    private String name;

    private Integer capacity;
    private String floor;

    // A real photo of the room, shown on the visitor map instead of the
    // stylized floor-plan icon -- base64 data URI or a pasted link, same
    // pattern as Organization.logoUrl.
    @Column(columnDefinition = "TEXT")
    private String photoUrl;

    // Free-text directions/notes for finding the room -- shown on the
    // visitor map alongside the auto-generated step directions.
    @Column(columnDefinition = "TEXT")
    private String description;
}
'@ | Set-Content -Path "server\src\main\java\com\visilog\api\entity\MeetingRoom.java" -Encoding utf8

@'
package com.visilog.api.dto;

import com.visilog.api.entity.MeetingRoom;
import java.util.UUID;

public record MeetingRoomDto(UUID id, String name, Integer capacity, String floor, String photoUrl, String description) {
    public static MeetingRoomDto from(MeetingRoom r) {
        return new MeetingRoomDto(
                r.getId(), r.getName(), r.getCapacity(), r.getFloor(), r.getPhotoUrl(), r.getDescription());
    }
}
'@ | Set-Content -Path "server\src\main\java\com\visilog\api\dto\MeetingRoomDto.java" -Encoding utf8

@'
package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;

public record MeetingRoomRequest(
        @NotBlank(message = "is required") String name,
        Integer capacity,
        String floor,
        String photoUrl,
        String description
) {
}
'@ | Set-Content -Path "server\src\main\java\com\visilog\api\dto\MeetingRoomRequest.java" -Encoding utf8

@'
package com.visilog.api.service;

import com.visilog.api.dto.BulkImportResult;
import com.visilog.api.dto.MeetingRoomDto;
import com.visilog.api.dto.MeetingRoomRequest;
import com.visilog.api.entity.MeetingRoom;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.MeetingRoomRepository;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MeetingRoomService {

    private final MeetingRoomRepository meetingRoomRepository;

    public MeetingRoomService(MeetingRoomRepository meetingRoomRepository) {
        this.meetingRoomRepository = meetingRoomRepository;
    }

    public List<MeetingRoomDto> list(UUID organizationId) {
        return meetingRoomRepository.findByOrganizationId(organizationId).stream()
                .map(MeetingRoomDto::from)
                .toList();
    }

    @Transactional
    public MeetingRoomDto create(UUID organizationId, MeetingRoomRequest req) {
        MeetingRoom r = new MeetingRoom();
        r.setOrganizationId(organizationId);
        applyRequest(r, req);
        return MeetingRoomDto.from(meetingRoomRepository.save(r));
    }

    @Transactional
    public MeetingRoomDto update(UUID organizationId, UUID roomId, MeetingRoomRequest req) {
        MeetingRoom r = meetingRoomRepository.findByOrganizationIdAndId(organizationId, roomId)
                .orElseThrow(() -> ApiException.notFound("Meeting room not found."));
        applyRequest(r, req);
        return MeetingRoomDto.from(meetingRoomRepository.save(r));
    }

    // CSV bulk import from Company Setup -- see EmployeeService.bulkCreate
    // for why this stays row-by-row and un-@Transactional.
    public BulkImportResult<MeetingRoomDto> bulkCreate(UUID organizationId, List<MeetingRoomRequest> rows) {
        List<MeetingRoomDto> created = new ArrayList<>();
        List<BulkImportResult.RowError> errors = new ArrayList<>();
        for (int i = 0; i < rows.size(); i++) {
            int rowNumber = i + 1;
            try {
                if (rows.get(i).name() == null || rows.get(i).name().isBlank()) {
                    throw ApiException.badRequest("Room name is required.");
                }
                created.add(create(organizationId, rows.get(i)));
            } catch (ApiException ex) {
                errors.add(new BulkImportResult.RowError(rowNumber, ex.getMessage()));
            }
        }
        return new BulkImportResult<>(created, errors);
    }

    @Transactional
    public void delete(UUID organizationId, UUID roomId) {
        MeetingRoom r = meetingRoomRepository.findByOrganizationIdAndId(organizationId, roomId)
                .orElseThrow(() -> ApiException.notFound("Meeting room not found."));
        meetingRoomRepository.delete(r);
    }

    private void applyRequest(MeetingRoom r, MeetingRoomRequest req) {
        r.setName(req.name().trim());
        r.setCapacity(req.capacity());
        r.setFloor(req.floor());
        r.setPhotoUrl(req.photoUrl());
        r.setDescription(req.description());
    }
}
'@ | Set-Content -Path "server\src\main\java\com\visilog\api\service\MeetingRoomService.java" -Encoding utf8

@'
ALTER TABLE appointments ADD COLUMN reject_reason VARCHAR(1000);
'@ | Set-Content -Path "server\src\main\resources\db\migration\V9__appointment_reject_reason.sql" -Encoding utf8

@'
ALTER TABLE meeting_rooms ADD COLUMN description TEXT;
'@ | Set-Content -Path "server\src\main\resources\db\migration\V10__meeting_room_description.sql" -Encoding utf8

Write-Host "Done. All 8 files updated and 2 new migration files created."
