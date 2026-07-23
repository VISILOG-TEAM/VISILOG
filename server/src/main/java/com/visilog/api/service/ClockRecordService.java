package com.visilog.api.service;

import com.visilog.api.dto.ClockActionRequest;
import com.visilog.api.dto.ClockRecordDto;
import com.visilog.api.dto.ClockStatusDto;
import com.visilog.api.entity.ClockRecord;
import com.visilog.api.entity.ClockType;
import com.visilog.api.entity.Employee;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.ClockRecordRepository;
import com.visilog.api.repository.EmployeeRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Work attendance. WiFi and GPS-geofence checks happen client-side
// (src/data/wifiCheck.js, src/data/locationCheck.js) before the app
// ever calls clockIn -- an HTTP request alone can't verify a caller's
// WiFi network or GPS position, so the backend's job is the two rules
// an HTTP API *can* enforce reliably: one clock-in per employee per
// calendar day (UTC), and clock-in device binding (see
// checkDeviceBinding) -- stops "give a coworker my password so they can
// clock in for me," since it doesn't matter whose login was used, only
// whose phone it is.
@Service
public class ClockRecordService {

    private final ClockRecordRepository clockRecordRepository;
    private final EmployeeRepository employeeRepository;

    public ClockRecordService(ClockRecordRepository clockRecordRepository, EmployeeRepository employeeRepository) {
        this.clockRecordRepository = clockRecordRepository;
        this.employeeRepository = employeeRepository;
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
            throw ApiException.conflict("You can only clock in once per day -- see you tomorrow.");
        }
        checkDeviceBinding(organizationId, req.employeeId(), req.deviceId());
        return save(organizationId, req, ClockType.IN);
    }

    @Transactional
    public ClockRecordDto clockOut(UUID organizationId, ClockActionRequest req) {
        return save(organizationId, req, ClockType.OUT);
    }

    // First clock-in from a device links it to that employee going
    // forward; a later clock-in attempt from a different device is
    // rejected outright, regardless of which account's credentials were
    // used to sign in -- see the class comment. Missing deviceId (an
    // older app build, or the platform couldn't report one) skips this
    // check entirely rather than blocking the clock-in.
    private void checkDeviceBinding(UUID organizationId, UUID employeeId, String deviceId) {
        if (deviceId == null || deviceId.isBlank()) {
            return;
        }
        Employee employee = employeeRepository.findByOrganizationIdAndId(organizationId, employeeId).orElse(null);
        if (employee == null) {
            return;
        }
        if (employee.getBoundDeviceId() == null) {
            employee.setBoundDeviceId(deviceId);
            employeeRepository.save(employee);
            return;
        }
        if (!employee.getBoundDeviceId().equals(deviceId)) {
            throw ApiException.conflict(
                    "This account is registered to a different phone. If you've switched devices, "
                    + "ask your Administrator to reset it in Company Setup.");
        }
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
