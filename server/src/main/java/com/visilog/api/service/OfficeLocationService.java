package com.visilog.api.service;

import com.visilog.api.dto.OfficeLocationDto;
import com.visilog.api.dto.OfficeLocationRequest;
import com.visilog.api.entity.OfficeLocation;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.OfficeLocationRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Company Setup > office locations -- every org gets one free; a
// second (or more) requires the enterprise plan. Replaced Organization's
// single office_latitude/longitude/radius (see V21 migration) so an org
// with multiple sites can have the clock-in/visitor-check-in geofence
// check (client-side, see locationCheck.ts) pass at any one of them.
@Service
public class OfficeLocationService {

    private final OfficeLocationRepository officeLocationRepository;
    private final PlanFeatureService planFeatureService;

    public OfficeLocationService(
            OfficeLocationRepository officeLocationRepository, PlanFeatureService planFeatureService) {
        this.officeLocationRepository = officeLocationRepository;
        this.planFeatureService = planFeatureService;
    }

    public List<OfficeLocationDto> list(UUID organizationId) {
        return officeLocationRepository.findByOrganizationId(organizationId).stream()
                .map(OfficeLocationDto::from)
                .toList();
    }

    @Transactional
    public OfficeLocationDto create(UUID organizationId, OfficeLocationRequest req) {
        if (officeLocationRepository.countByOrganizationId(organizationId) >= 1) {
            planFeatureService.requirePlan(organizationId, "enterprise", "A second office location");
        }
        OfficeLocation loc = new OfficeLocation();
        loc.setOrganizationId(organizationId);
        applyRequest(loc, req);
        return OfficeLocationDto.from(officeLocationRepository.save(loc));
    }

    @Transactional
    public OfficeLocationDto update(UUID organizationId, UUID id, OfficeLocationRequest req) {
        OfficeLocation loc = findOrThrow(organizationId, id);
        applyRequest(loc, req);
        return OfficeLocationDto.from(officeLocationRepository.save(loc));
    }

    @Transactional
    public void delete(UUID organizationId, UUID id) {
        OfficeLocation loc = findOrThrow(organizationId, id);
        officeLocationRepository.delete(loc);
    }

    private void applyRequest(OfficeLocation loc, OfficeLocationRequest req) {
        loc.setName(req.name().trim());
        loc.setLatitude(req.latitude());
        loc.setLongitude(req.longitude());
        loc.setRadiusMeters(req.radiusMeters());
    }

    private OfficeLocation findOrThrow(UUID organizationId, UUID id) {
        return officeLocationRepository.findByOrganizationIdAndId(organizationId, id)
                .orElseThrow(() -> ApiException.notFound("Office location not found."));
    }
}
