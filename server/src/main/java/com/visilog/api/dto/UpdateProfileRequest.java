package com.visilog.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// Settings > "Your profile": the signed-in user editing their own
// display name. Deliberately does NOT carry email or role -- email is
// the login identity and role is fixed at signup from the staff roster
// (see AuthService.signup), so neither is user-editable here.
public record UpdateProfileRequest(
        @NotBlank @Size(max = 120) String name
) {
}
