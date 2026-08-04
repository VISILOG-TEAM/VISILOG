package com.visilog.api.controller;

import com.visilog.api.dto.RegisterPushTokenRequest;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.PushTokenService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

// Called once the app has permission and an Expo push token in hand
// (see src/data/pushNotifications.ts) -- on login and on app foreground,
// so a token survives a reinstall or a new device without the user
// having to do anything for it.
@RestController
@RequestMapping("/api/v1/push-tokens")
public class PushTokenController {

    private final PushTokenService pushTokenService;

    public PushTokenController(PushTokenService pushTokenService) {
        this.pushTokenService = pushTokenService;
    }

    @PostMapping
    public ResponseEntity<Void> register(@CurrentUser AuthPrincipal me, @RequestBody RegisterPushTokenRequest req) {
        String visitorEmail = me.employeeId() == null ? me.email() : null;
        pushTokenService.register(me.organizationId(), me.employeeId(), visitorEmail, req.token());
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{token}")
    public ResponseEntity<Void> unregister(@PathVariable String token) {
        pushTokenService.unregister(token);
        return ResponseEntity.noContent().build();
    }
}
