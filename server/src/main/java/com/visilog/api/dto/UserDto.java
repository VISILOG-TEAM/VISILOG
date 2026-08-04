package com.visilog.api.dto;

import com.visilog.api.entity.AppUser;
import com.visilog.api.entity.Organization;
import java.util.UUID;

public record UserDto(
        UUID id,
        String email,
        String name,
        String role,
        UUID employeeId,
        UUID organizationId,
        String organizationName,
        boolean emailVerified
) {
    public static UserDto from(AppUser user, Organization org) {
        return new UserDto(
                user.getId(), user.getEmail(), user.getName(), user.getRole().name(),
                user.getEmployeeId(), org.getId(), org.getName(), user.isEmailVerified());
    }
}
