package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;

public record WifiNetworkRequest(@NotBlank String name) {
}
