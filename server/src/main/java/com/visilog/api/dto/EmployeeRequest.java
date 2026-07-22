package com.visilog.api.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record EmployeeRequest(
        @NotBlank(message = "is required") String employeeCode,
        @NotBlank(message = "is required") String name,
        String department,
        String phone,
        @NotBlank(message = "is required") @Email(message = "must be a valid email") String email,
        @NotNull(message = "is required") String role // "employee" | "receptionist" | "manager"
) {
}
