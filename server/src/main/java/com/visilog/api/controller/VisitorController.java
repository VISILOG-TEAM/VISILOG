package com.visilog.api.controller;

import com.visilog.api.dto.CheckOutRequest;
import com.visilog.api.dto.RegisterVisitorRequest;
import com.visilog.api.dto.VisitorDto;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.VisitorService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/visitors")
public class VisitorController {

    private final VisitorService visitorService;

    public VisitorController(VisitorService visitorService) {
        this.visitorService = visitorService;
    }

    @GetMapping
    public ResponseEntity<List<VisitorDto>> list(@CurrentUser AuthPrincipal me) {
        return ResponseEntity.ok(visitorService.list(me.organizationId()));
    }

    @PostMapping
    public ResponseEntity<VisitorDto> register(@CurrentUser AuthPrincipal me, @Valid @RequestBody RegisterVisitorRequest request) {
        return ResponseEntity.ok(visitorService.registerAndCheckIn(me.organizationId(), request));
    }

    @PatchMapping("/{id}/check-out")
    public ResponseEntity<VisitorDto> checkOut(
            @CurrentUser AuthPrincipal me, @PathVariable UUID id, @RequestBody(required = false) CheckOutRequest request) {
        return ResponseEntity.ok(visitorService.checkOut(me.organizationId(), id, request == null ? new CheckOutRequest(null) : request));
    }
}
