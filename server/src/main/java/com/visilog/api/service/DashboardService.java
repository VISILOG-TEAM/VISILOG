package com.visilog.api.service;

import com.visilog.api.dto.DashboardStatsDto;
import com.visilog.api.entity.AppointmentStatus;
import com.visilog.api.entity.VisitorStatus;
import com.visilog.api.repository.AppointmentRepository;
import com.visilog.api.repository.CallRepository;
import com.visilog.api.repository.VisitorRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.util.UUID;
import org.springframework.stereotype.Service;

// What DataContext.js's `stats` useMemo used to compute client-side —
// moved server-side so every role's dashboard reads the same numbers
// from one source of truth instead of each device recomputing them
// from a full local copy of the data.
@Service
public class DashboardService {

    private final VisitorRepository visitorRepository;
    private final CallRepository callRepository;
    private final AppointmentRepository appointmentRepository;

    public DashboardService(
            VisitorRepository visitorRepository,
            CallRepository callRepository,
            AppointmentRepository appointmentRepository) {
        this.visitorRepository = visitorRepository;
        this.callRepository = callRepository;
        this.appointmentRepository = appointmentRepository;
    }

    public DashboardStatsDto stats(UUID organizationId) {
        Instant startOfDay = LocalDate.now(ZoneOffset.UTC).atStartOfDay(ZoneOffset.UTC).toInstant();
        Instant startOfMonth = YearMonth.now(ZoneOffset.UTC).atDay(1).atStartOfDay(ZoneOffset.UTC).toInstant();

        var visitors = visitorRepository.findByOrganizationIdOrderByCheckInAtDesc(organizationId);
        var calls = callRepository.findByOrganizationIdOrderByTimestampDesc(organizationId);
        var appointments = appointmentRepository.findByOrganizationIdOrderByScheduledAtDesc(organizationId);

        long visitorsToday = visitors.stream().filter(v -> !v.getCheckInAt().isBefore(startOfDay)).count();
        long onsite = visitors.stream().filter(v -> v.getStatus() == VisitorStatus.ONSITE).count();
        long callsToday = calls.stream().filter(c -> !c.getTimestamp().isBefore(startOfDay)).count();
        long visitorsThisMonth = visitors.stream().filter(v -> !v.getCheckInAt().isBefore(startOfMonth)).count();
        long pendingApprovals = appointments.stream().filter(a -> a.getStatus() == AppointmentStatus.PENDING).count();

        return new DashboardStatsDto(visitorsToday, onsite, callsToday, visitorsThisMonth, pendingApprovals);
    }
}
