package com.visilog.api.controller;

import com.visilog.api.dto.WifiNetworkDto;
import com.visilog.api.dto.WifiNetworkRequest;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.WifiNetworkService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/wifi-networks")
public class WifiNetworkController {

    private final WifiNetworkService wifiNetworkService;

    public WifiNetworkController(WifiNetworkService wifiNetworkService) {
        this.wifiNetworkService = wifiNetworkService;
    }

    // Every role can read the list -- shown to staff as a reminder of
    // which network to join before clocking in, not just managers.
    @GetMapping
    public ResponseEntity<List<WifiNetworkDto>> list(@CurrentUser AuthPrincipal me) {
        return ResponseEntity.ok(wifiNetworkService.list(me.organizationId()));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @PostMapping
    public ResponseEntity<WifiNetworkDto> create(
            @CurrentUser AuthPrincipal me, @Valid @RequestBody WifiNetworkRequest request) {
        return ResponseEntity.ok(wifiNetworkService.create(me.organizationId(), request));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @PatchMapping("/{id}")
    public ResponseEntity<WifiNetworkDto> update(
            @CurrentUser AuthPrincipal me, @PathVariable UUID id,
            @Valid @RequestBody WifiNetworkRequest request) {
        return ResponseEntity.ok(wifiNetworkService.update(me.organizationId(), id, request));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@CurrentUser AuthPrincipal me, @PathVariable UUID id) {
        wifiNetworkService.delete(me.organizationId(), id);
        return ResponseEntity.noContent().build();
    }
}
