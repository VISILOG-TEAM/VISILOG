package com.visilog.api.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

// Only name and email are mandatory. employeeCode is generated when
// blank and role defaults to EMPLOYEE (both in EmployeeService) -- a
// staff list exported from an HR or payroll system carries neither of
// VisiLog's own columns, and demanding them here rejected entire files
// at the door, before any of the friendlier handling downstream could
// run.
public record EmployeeRequest(
        String employeeCode,
        @NotBlank(message = "is required") String name,
        String department,
        String phone,
        @NotBlank(message = "is required") @Email(message = "must be a valid email") String email,
        String role // "employee" | "receptionist" | "manager"; defaults to employee
) {
}
