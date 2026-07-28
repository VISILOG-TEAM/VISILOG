package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// The 6-digit code from the verification email. Which account it
// belongs to comes from the caller's own token, never the body.
public record VerifyEmailRequest(
        @NotBlank @Size(max = 10) String code
) {}
