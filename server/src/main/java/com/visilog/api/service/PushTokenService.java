package com.visilog.api.service;

import com.visilog.api.entity.PushToken;
import com.visilog.api.repository.PushTokenRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Registers a device's Expo push token against whichever account is
// signed in right now. A token already on file is re-pointed to the
// current caller rather than duplicated, so a shared device (or someone
// switching accounts on their own phone) doesn't end up sending
// reminders to whoever registered it first. See ReminderService, which
// looks tokens up by employee/visitor to actually send.
@Service
public class PushTokenService {

    private final PushTokenRepository pushTokenRepository;

    public PushTokenService(PushTokenRepository pushTokenRepository) {
        this.pushTokenRepository = pushTokenRepository;
    }

    @Transactional
    public void register(UUID organizationId, UUID employeeId, String visitorEmail, String token) {
        if (token == null || token.isBlank()) {
            return;
        }
        PushToken row = pushTokenRepository.findByToken(token.trim()).orElseGet(PushToken::new);
        if (row.getCreatedAt() == null) {
            row.setCreatedAt(Instant.now());
        }
        row.setOrganizationId(organizationId);
        row.setEmployeeId(employeeId);
        row.setVisitorEmail(visitorEmail);
        row.setToken(token.trim());
        pushTokenRepository.save(row);
    }

    @Transactional
    public void unregister(String token) {
        pushTokenRepository.deleteByToken(token);
    }

    List<String> tokensFor(UUID organizationId, UUID employeeId) {
        if (employeeId == null) {
            return List.of();
        }
        return pushTokenRepository.findByOrganizationIdAndEmployeeId(organizationId, employeeId).stream()
                .map(PushToken::getToken).toList();
    }

    List<String> tokensForVisitor(UUID organizationId, String email) {
        if (email == null || email.isBlank()) {
            return List.of();
        }
        return pushTokenRepository.findByOrganizationIdAndVisitorEmailIgnoreCase(organizationId, email).stream()
                .map(PushToken::getToken).toList();
    }
}
