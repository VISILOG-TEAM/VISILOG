package com.visilog.api.service;

import com.visilog.api.dto.CheckOutRequest;
import com.visilog.api.dto.RegisterVisitorRequest;
import com.visilog.api.dto.VisitorDto;
import com.visilog.api.entity.Visitor;
import com.visilog.api.entity.VisitorStatus;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.VisitorRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class VisitorService {

    private final VisitorRepository visitorRepository;
    private final NotificationService notificationService;

    public VisitorService(VisitorRepository visitorRepository, NotificationService notificationService) {
        this.visitorRepository = visitorRepository;
        this.notificationService = notificationService;
    }

    public List<VisitorDto> list(UUID organizationId) {
        return visitorRepository.findByOrganizationIdOrderByCheckInAtDesc(organizationId).stream()
                .map(VisitorDto::from)
                .toList();
    }

    @Transactional
    public VisitorDto registerAndCheckIn(UUID organizationId, RegisterVisitorRequest req) {
        Visitor v = new Visitor();
        v.setOrganizationId(organizationId);
        v.setBadgeId(CodeGenerator.nextBadgeId(visitorRepository.countByOrganizationId(organizationId)));
        v.setFirstName(req.firstName().trim());
        v.setLastName(req.lastName().trim());
        v.setPhone(req.phone().trim());
        v.setEmail(req.email());
        v.setCompany(req.company());
        v.setPurpose(req.purpose() == null || req.purpose().isBlank() ? "Official Business" : req.purpose());
        v.setHostId(req.hostId());
        v.setCheckInAt(Instant.now());
        v.setStatus(VisitorStatus.ONSITE);
        v.setNotes(req.notes());
        return VisitorDto.from(visitorRepository.save(v));
    }

    @Transactional
    public VisitorDto checkOut(UUID organizationId, UUID visitorId, CheckOutRequest req) {
        Visitor v = visitorRepository.findByOrganizationIdAndId(organizationId, visitorId)
                .orElseThrow(() -> ApiException.notFound("Visitor not found."));
        v.setStatus(VisitorStatus.COMPLETED);
        v.setCheckOutAt(Instant.now());
        if (req.notes() != null && !req.notes().isBlank()) {
            v.setNotes(req.notes());
        }
        Visitor saved = visitorRepository.save(v);
        notificationService.notifyVisitorCheckedOut(saved);
        return VisitorDto.from(saved);
    }

    // Used by AppointmentService when admitting a pending appointment --
    // registers + checks in the visitor from the appointment's details,
    // so reception doesn't repeat data entry.
    @Transactional
    public Visitor registerAndCheckInInternal(UUID organizationId, String firstName, String lastName,
            String phone, String email, String company, String purpose, UUID hostId) {
        Visitor v = new Visitor();
        v.setOrganizationId(organizationId);
        v.setBadgeId(CodeGenerator.nextBadgeId(visitorRepository.countByOrganizationId(organizationId)));
        v.setFirstName(firstName);
        v.setLastName(lastName);
        v.setPhone(phone);
        v.setEmail(email);
        v.setCompany(company);
        v.setPurpose(purpose);
        v.setHostId(hostId);
        v.setCheckInAt(Instant.now());
        v.setStatus(VisitorStatus.ONSITE);
        return visitorRepository.save(v);
    }
}