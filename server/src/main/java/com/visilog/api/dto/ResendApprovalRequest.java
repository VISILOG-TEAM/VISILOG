package com.visilog.api.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record ResendApprovalRequest(@NotNull UUID userId) {}
