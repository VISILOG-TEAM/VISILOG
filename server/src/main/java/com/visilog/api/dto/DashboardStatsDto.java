package com.visilog.api.dto;

public record DashboardStatsDto(
        long visitorsToday, long onsite, long callsToday, long visitorsThisMonth, long pendingApprovals
) {
}
