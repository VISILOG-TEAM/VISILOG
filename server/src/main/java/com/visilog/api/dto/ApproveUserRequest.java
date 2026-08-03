package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

// The 6-digit code from the owner-approval email, plus which pending
// account it approves -- unlike VerifyEmailRequest, the caller here
// (the Manager) isn't the account being unlocked, so the target has to
// be named explicitly.
public record ApproveUserRequest(
        @NotNull UUID userId,
        @NotBlank @Size(max = 10) String code
) {}
