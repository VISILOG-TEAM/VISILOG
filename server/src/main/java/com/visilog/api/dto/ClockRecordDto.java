package com.visilog.api.dto;

import com.visilog.api.entity.ClockRecord;
import java.time.Instant;
import java.util.UUID;

public record ClockRecordDto(UUID id, UUID employeeId, String employeeName, String type, Instant timestamp) {
    public static ClockRecordDto from(ClockRecord r) {
        return new ClockRecordDto(r.getId(), r.getEmployeeId(), r.getEmployeeName(), r.getType().name(), r.getTimestamp());
    }
}
