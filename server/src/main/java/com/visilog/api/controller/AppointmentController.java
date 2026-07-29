package com.visilog.api.controller;

import com.visilog.api.dto.AppointmentDto;
import com.visilog.api.dto.BookAppointmentRequest;
import com.visilog.api.dto.RescheduleRequest;
import com.visilog.api.dto.UpdateAppointmentStatusRequest;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.AppointmentService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/appointments")
public class AppointmentController {

    private final AppointmentService appointmentService;

    public AppointmentController(AppointmentService appointmentService) {
        this.appointmentService = appointmentService;
    }

    // Reception/Manager: every appointment in the org. Visitor callers
    // get just their own (via ?mine=true) — see VisitorHomeScreen /
    // VisitorVisitsScreen on the frontend, which only ever show "my"
    // bookings for that role.
    @GetMapping
    public ResponseEntity<List<AppointmentDto>> list(
            @CurrentUser AuthPrincipal me, @RequestParam(required = false) Boolean mine) {
        if (Boolean.TRUE.equals(mine)) {
            return ResponseEntity.ok(appointmentService.listForVisitor(me.organizationId(), me.email()));
        }
        return ResponseEntity.ok(appointmentService.list(me.organizationId(), me));
    }

    @GetMapping("/by-code/{code}")
    public ResponseEntity<AppointmentDto> findByCode(@CurrentUser AuthPrincipal me, @PathVariable String code) {
        return ResponseEntity.ok(appointmentService.findByCode(me.organizationId(), code));
    }

    // A Visitor booking their own visit gets bookedByEmail set to their
    // own account automatically; reception booking on someone's behalf
    // (VisitorBookingScreen) does not set it — matches the original
    // frontend behaviour exactly.
    @PostMapping
    public ResponseEntity<AppointmentDto> book(@CurrentUser AuthPrincipal me, @Valid @RequestBody BookAppointmentRequest request) {
        String bookedByEmail = "VISITOR".equals(me.role()) ? me.email() : null;
        return ResponseEntity.ok(appointmentService.book(me.organizationId(), request, bookedByEmail));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<AppointmentDto> updateStatus(
            @CurrentUser AuthPrincipal me, @PathVariable UUID id, @Valid @RequestBody UpdateAppointmentStatusRequest request) {
        return ResponseEntity.ok(appointmentService.updateStatus(me.organizationId(), id, request, me));
    }

    @PostMapping("/{id}/admit")
    public ResponseEntity<AppointmentDto> admit(@CurrentUser AuthPrincipal me, @PathVariable UUID id) {
        return ResponseEntity.ok(appointmentService.admit(me.organizationId(), id, me));
    }

    @PostMapping("/{id}/check-in")
    public ResponseEntity<AppointmentDto> checkIn(@CurrentUser AuthPrincipal me, @PathVariable UUID id) {
        return ResponseEntity.ok(appointmentService.checkIn(me.organizationId(), id));
    }

    @PatchMapping("/{id}/reschedule")
    public ResponseEntity<AppointmentDto> reschedule(
            @CurrentUser AuthPrincipal me, @PathVariable UUID id, @Valid @RequestBody RescheduleRequest request) {
        return ResponseEntity.ok(appointmentService.reschedule(me.organizationId(), id, request));
    }
}
