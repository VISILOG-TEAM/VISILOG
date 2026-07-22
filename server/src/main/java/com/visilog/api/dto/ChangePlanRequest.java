package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;

public record ChangePlanRequest(@NotBlank(message = "is required") String planId) {
}
