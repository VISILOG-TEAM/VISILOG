package com.visilog.api.service;

import com.visilog.api.dto.ClockActionRequest;
import com.visilog.api.dto.ClockRecordDto;
import com.visilog.api.dto.ClockStatusDto;
import com.visilog.api.entity.ClockRecord;
import com.visilog.api.entity.ClockType;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.ClockRecordRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Work attendance. WiFi and GPS-geofence checks happen client-side
// (src/data/wifiCheck.js, src/data/locationCheck.js) before the app
// ever calls clockIn — an HTTP request alone can't verify a caller's
// WiFi network or GPS position, so the backend's job is just the rule
// an HTTP API *can* enforce reliably: one clock-in per employee per
// calendar day (UTC).
@Service
public class ClockRecordService {

    private final ClockRecordRepository clockRecordRepository;

    public ClockRecordService(ClockRecordRepository clockRecordRepository) {
        this.clockRecordRepository = clockRecordRepository;
    }

    public List<ClockRecordDto> list(UUID organizationId) {
        return clockRecordRepository.findByOrganizationIdOrderByTimestampDesc(organizationId).stream()
                .map(ClockRecordDto::from)
                .toList();
    }

    public ClockStatusDto status(UUID organizationId, UUID employeeId) {
        var last = clockRecordRepository.findFirstByOrganizationIdAndEmployeeIdOrderByTimestampDesc(organizationId, employeeId);
        boolean clockedIn = last.isPresent() && last.get().getType() == ClockType.IN;
        boolean today = hasClockedInToday(organizationId, employeeId);
        return new ClockStatusDto(clockedIn, today, last.map(ClockRecordDto::from).orElse(null));
    }

    @Transactional
    public ClockRecordDto clockIn(UUID organizationId, ClockActionRequest req) {
        if (hasClockedInToday(organizationId, req.employeeId())) {
            throw ApiException.conflict("You can only clock in once per day — see you tomorrow.");
        }
        return save(organizationId, req, ClockType.IN);
    }

    @Transactional
    public ClockRecordDto clockOut(UUID organizationId, ClockActionRequest req) {
        return save(organizationId, req, ClockType.OUT);
    }

    private boolean hasClockedInToday(UUID organizationId, UUID employeeId) {
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        Instant startOfDay = today.atStartOfDay(ZoneOffset.UTC).toInstant();
        Instant startOfNextDay = today.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();
        return clockRecordRepository.existsByOrganizationIdAndEmployeeIdAndTypeAndTimestampBetween(
                organizationId, employeeId, ClockType.IN, startOfDay, startOfNextDay);
    }

    private ClockRecordDto save(UUID organizationId, ClockActionRequest req, ClockType type) {
        ClockRecord r = new ClockRecord();
        r.setOrganizationId(organizationId);
        r.setEmployeeId(req.employeeId());
        r.setEmployeeName(req.employeeName());
        r.setType(type);
        r.setTimestamp(Instant.now());
        return ClockRecordDto.from(clockRecordRepository.save(r));
    }
}
