package com.visilog.api.dto;

public record ClockStatusDto(boolean clockedIn, boolean hasClockedInToday, ClockRecordDto lastRecord) {
}
