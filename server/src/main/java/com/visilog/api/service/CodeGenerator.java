package com.visilog.api.service;

import java.security.SecureRandom;
import java.time.Year;

// Badge/NFC code formats matching the original frontend mock data
// generators (nextBadgeId / generateVisitorCode in mockData.js) —
// kept as simple random/sequential codes since there's no need for
// anything more sophisticated at this scale.
public final class CodeGenerator {

    private static final SecureRandom RANDOM = new SecureRandom();

    private CodeGenerator() {
    }

    // "VIS-2026-001" style, numbered per-org by the caller passing in
    // how many visitors this org already has.
    public static String nextBadgeId(long existingCountForOrg) {
        int year = Year.now().getValue();
        return "VIS-%d-%03d".formatted(year, existingCountForOrg + 1);
    }

    // "VC-1234-5678" style — random, not sequential, since it's meant
    // to be unguessable (shown to a visitor as their access code).
    public static String generateVisitorCode() {
        return "VC-%04d-%04d".formatted(1000 + RANDOM.nextInt(9000), 1000 + RANDOM.nextInt(9000));
    }
}
