package com.visilog.api.controller;

import com.visilog.api.dto.ClockActionRequest;
import com.visilog.api.dto.ClockRecordDto;
import com.visilog.api.dto.ClockStatusDto;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.ClockRecordService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/clock-records")
public class ClockRecordController {

    private final ClockRecordService clockRecordService;

    public ClockRecordController(ClockRecordService clockRecordService) {
        this.clockRecordService = clockRecordService;
    }

    @GetMapping
    public ResponseEntity<List<ClockRecordDto>> list(@CurrentUser AuthPrincipal me) {
        return ResponseEntity.ok(clockRecordService.list(me.organizationId()));
    }

    @GetMapping("/status")
    public ResponseEntity<ClockStatusDto> status(@CurrentUser AuthPrincipal me, @RequestParam UUID employeeId) {
        return ResponseEntity.ok(clockRecordService.status(me.organizationId(), employeeId));
    }

    @PostMapping("/in")
    public ResponseEntity<ClockRecordDto> clockIn(@CurrentUser AuthPrincipal me, @Valid @RequestBody ClockActionRequest request) {
        return ResponseEntity.ok(clockRecordService.clockIn(me.organizationId(), request));
    }

    @PostMapping("/out")
    public ResponseEntity<ClockRecordDto> clockOut(@CurrentUser AuthPrincipal me, @Valid @RequestBody ClockActionRequest request) {
        return ResponseEntity.ok(clockRecordService.clockOut(me.organizationId(), request));
    }
}
