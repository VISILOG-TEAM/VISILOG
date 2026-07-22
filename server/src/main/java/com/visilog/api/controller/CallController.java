package com.visilog.api.controller;

import com.visilog.api.dto.CallDto;
import com.visilog.api.dto.LogCallRequest;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.CallService;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/calls")
public class CallController {

    private final CallService callService;

    public CallController(CallService callService) {
        this.callService = callService;
    }

    @GetMapping
    public ResponseEntity<List<CallDto>> list(@CurrentUser AuthPrincipal me) {
        return ResponseEntity.ok(callService.list(me.organizationId()));
    }

    @PostMapping
    public ResponseEntity<CallDto> log(@CurrentUser AuthPrincipal me, @RequestBody LogCallRequest request) {
        return ResponseEntity.ok(callService.log(me.organizationId(), request));
    }
}
