package com.visilog.api.controller;

import com.visilog.api.dto.NotificationDto;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.NotificationService;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    public ResponseEntity<List<NotificationDto>> list(@CurrentUser AuthPrincipal me) {
        return ResponseEntity.ok(notificationService.list(me.organizationId(), me.employeeId(), me.email()));
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<NotificationDto> markRead(@CurrentUser AuthPrincipal me, @PathVariable UUID id) {
        return ResponseEntity.ok(notificationService.markRead(me.organizationId(), id, me.employeeId(), me.email()));
    }
}
