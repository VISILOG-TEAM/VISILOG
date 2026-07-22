package com.visilog.api.dto;

public record AuthResponse(String token, UserDto user, OrganizationDto organization) {
}
