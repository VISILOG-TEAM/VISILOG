package com.visilog.api.controller;

import com.visilog.api.dto.OrganizationDto;
import com.visilog.api.dto.UpdateOrgRequest;
import com.visilog.api.security.AuthPrincipal;
import com.visilog.api.security.CurrentUser;
import com.visilog.api.service.OrgService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/org")
public class OrgController {

    private final OrgService orgService;

    public OrgController(OrgService orgService) {
        this.orgService = orgService;
    }

    @GetMapping
    public ResponseEntity<OrganizationDto> get(@CurrentUser AuthPrincipal me) {
        return ResponseEntity.ok(orgService.get(me.organizationId()));
    }

    @PreAuthorize("hasRole('MANAGER')")
    @PatchMapping
    public ResponseEntity<OrganizationDto> update(@CurrentUser AuthPrincipal me, @RequestBody UpdateOrgRequest request) {
        return ResponseEntity.ok(orgService.update(me.organizationId(), request));
    }
}
