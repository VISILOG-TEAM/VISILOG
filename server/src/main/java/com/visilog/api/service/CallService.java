package com.visilog.api.service;

import com.visilog.api.dto.CallDto;
import com.visilog.api.dto.LogCallRequest;
import com.visilog.api.entity.Call;
import com.visilog.api.entity.CallType;
import com.visilog.api.repository.CallRepository;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CallService {

    private final CallRepository callRepository;

    public CallService(CallRepository callRepository) {
        this.callRepository = callRepository;
    }

    public List<CallDto> list(UUID organizationId) {
        return callRepository.findByOrganizationIdOrderByTimestampDesc(organizationId).stream()
                .map(CallDto::from)
                .toList();
    }

    @Transactional
    public CallDto log(UUID organizationId, LogCallRequest req) {
        Call c = new Call();
        c.setOrganizationId(organizationId);
        c.setCallerName(req.callerName() == null || req.callerName().isBlank() ? "Unknown" : req.callerName());
        c.setCallerPhone(req.callerPhone());
        c.setHostId(req.hostId());
        c.setCallType(parseType(req.callType()));
        c.setPurpose(req.purpose());
        c.setDurationMinutes(req.durationMinutes() == null ? 0 : req.durationMinutes());
        c.setNotes(req.notes());
        c.setTimestamp(Instant.now());
        return CallDto.from(callRepository.save(c));
    }

    private CallType parseType(String raw) {
        if (raw == null || raw.isBlank()) {
            return CallType.INCOMING;
        }
        try {
            return CallType.valueOf(raw.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException ex) {
            return CallType.INCOMING;
        }
    }
}
