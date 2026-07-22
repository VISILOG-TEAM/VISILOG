package com.visilog.api.security;

import java.util.UUID;

// What ends up as the Authentication's principal after JwtAuthFilter
// validates a token — everything a controller/service needs to know
// about the caller without hitting the DB again.
public record AuthPrincipal(UUID userId, UUID organizationId, String role, String email, UUID employeeId) {
}
