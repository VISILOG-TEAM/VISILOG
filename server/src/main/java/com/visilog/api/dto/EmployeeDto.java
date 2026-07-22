package com.visilog.api.dto;

import com.visilog.api.entity.Employee;
import java.util.UUID;

public record EmployeeDto(
        UUID id, String employeeCode, String name, String department,
        String phone, String email, String role
) {
    public static EmployeeDto from(Employee e) {
        return new EmployeeDto(
                e.getId(), e.getEmployeeCode(), e.getName(), e.getDepartment(),
                e.getPhone(), e.getEmail(), e.getRole().name());
    }
}
