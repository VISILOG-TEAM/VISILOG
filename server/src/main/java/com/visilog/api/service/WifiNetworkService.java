package com.visilog.api.service;

import com.visilog.api.dto.WifiNetworkDto;
import com.visilog.api.dto.WifiNetworkRequest;
import com.visilog.api.entity.WifiNetwork;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.WifiNetworkRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Company Setup > WiFi networks -- an org can list more than one (e.g.
// separate networks per floor/building), shown to staff as "connect to
// X to clock in". Replaced Organization's single wifiNetworkName field
// (see V28 migration), same restructuring OfficeLocationService did for
// office_latitude/longitude/radius. No plan gating: unlike office
// locations this is purely informational text, not a real check.
@Service
public class WifiNetworkService {

    private final WifiNetworkRepository wifiNetworkRepository;

    public WifiNetworkService(WifiNetworkRepository wifiNetworkRepository) {
        this.wifiNetworkRepository = wifiNetworkRepository;
    }

    public List<WifiNetworkDto> list(UUID organizationId) {
        return wifiNetworkRepository.findByOrganizationId(organizationId).stream()
                .map(WifiNetworkDto::from)
                .toList();
    }

    @Transactional
    public WifiNetworkDto create(UUID organizationId, WifiNetworkRequest req) {
        WifiNetwork network = new WifiNetwork();
        network.setOrganizationId(organizationId);
        network.setName(req.name().trim());
        return WifiNetworkDto.from(wifiNetworkRepository.save(network));
    }

    @Transactional
    public WifiNetworkDto update(UUID organizationId, UUID id, WifiNetworkRequest req) {
        WifiNetwork network = findOrThrow(organizationId, id);
        network.setName(req.name().trim());
        return WifiNetworkDto.from(wifiNetworkRepository.save(network));
    }

    @Transactional
    public void delete(UUID organizationId, UUID id) {
        WifiNetwork network = findOrThrow(organizationId, id);
        wifiNetworkRepository.delete(network);
    }

    private WifiNetwork findOrThrow(UUID organizationId, UUID id) {
        return wifiNetworkRepository.findByOrganizationIdAndId(organizationId, id)
                .orElseThrow(() -> ApiException.notFound("WiFi network not found."));
    }
}
