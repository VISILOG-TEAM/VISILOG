package com.visilog.api.controller;

import com.visilog.api.dto.OfficeLocationDto;
import com.visilog.api.dto.OfficeLocationRequest;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.OfficeLocationService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/office-locations")
public class OfficeLocationController {

    private final OfficeLocationService officeLocationService;

    public OfficeLocationController(OfficeLocationService officeLocationService) {
        this.officeLocationService = officeLocationService;
    }

    // Every role can read the list -- the clock-in/visitor-check-in
    // geofence check (client-side, see locationCheck.ts) needs it
    // regardless of who's signed in, not just managers.
    @GetMapping
    public ResponseEntity<List<OfficeLocationDto>> list(@CurrentUser AuthPrincipal me) {
        return ResponseEntity.ok(officeLocationService.list(me.organizationId()));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @PostMapping
    public ResponseEntity<OfficeLocationDto> create(
            @CurrentUser AuthPrincipal me, @Valid @RequestBody OfficeLocationRequest request) {
        return ResponseEntity.ok(officeLocationService.create(me.organizationId(), request));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @PatchMapping("/{id}")
    public ResponseEntity<OfficeLocationDto> update(
            @CurrentUser AuthPrincipal me, @PathVariable UUID id,
            @Valid @RequestBody OfficeLocationRequest request) {
        return ResponseEntity.ok(officeLocationService.update(me.organizationId(), id, request));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@CurrentUser AuthPrincipal me, @PathVariable UUID id) {
        officeLocationService.delete(me.organizationId(), id);
        return ResponseEntity.noContent().build();
    }
}
