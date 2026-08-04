package com.visilog.api.service;

import com.visilog.api.entity.Organization;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.OrganizationRepository;
import java.time.Instant;
import java.time.LocalTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.UUID;
import org.springframework.stereotype.Service;

// Company Setup > working hours. An org that hasn't set both an opening
// and a closing time has no time-of-day restriction at all (see
// Organization.openingTime/closingTime and V25 migration) -- this is an
// opt-in gate, not a default. Every check runs in UTC, same as the rest
// of the app's day-boundary logic (see ClockRecordService), since
// organizations don't carry a timezone of their own.
@Service
public class WorkingHoursService {

    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm");

    private final OrganizationRepository organizationRepository;

    public WorkingHoursService(OrganizationRepository organizationRepository) {
        this.organizationRepository = organizationRepository;
    }

    public void requireWithinHours(UUID organizationId, Instant instant, String activity) {
        if (instant == null) {
            return;
        }
        Organization org = organizationRepository.findById(organizationId).orElse(null);
        LocalTime opening = org == null ? null : org.getOpeningTime();
        LocalTime closing = org == null ? null : org.getClosingTime();
        if (opening == null || closing == null) {
            return;
        }
        LocalTime time = instant.atZone(ZoneOffset.UTC).toLocalTime();
        boolean withinHours = opening.isBefore(closing)
                ? !time.isBefore(opening) && !time.isAfter(closing)
                // closing <= opening means the window wraps past midnight (e.g. 22:00-06:00)
                : !time.isBefore(opening) || !time.isAfter(closing);
        if (!withinHours) {
            throw ApiException.badRequest(
                    activity + " is only allowed between " + TIME_FORMAT.format(opening) + " and "
                    + TIME_FORMAT.format(closing) + " (company working hours).");
        }
    }
}
