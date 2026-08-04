package com.visilog.api.dto;

import com.visilog.api.entity.WifiNetwork;
import java.util.UUID;

public record WifiNetworkDto(UUID id, String name) {
    public static WifiNetworkDto from(WifiNetwork network) {
        return new WifiNetworkDto(network.getId(), network.getName());
    }
}
