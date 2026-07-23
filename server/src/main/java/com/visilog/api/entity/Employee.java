package com.visilog.api.entity;

import jakarta.persistence.*;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// The Administrator's staff roster -- managed in Company Setup. This is
// the source of truth AuthService checks at signup: an AppUser whose
// email matches an Employee row here inherits that row's role and gets
// linked to it; no match falls back to Role.VISITOR.
@Entity
@Table(name = "employees", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"organization_id", "email"}),
    @UniqueConstraint(columnNames = {"organization_id", "employee_code"})
})
@Getter
@Setter
@NoArgsConstructor
public class Employee {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "organization_id", nullable = false)
    private UUID organizationId;

    // Human-readable badge-style code shown on the roster, e.g. "VRA-1004".
    @Column(name = "employee_code", nullable = false, length = 32)
    private String employeeCode;

    @Column(nullable = false)
    private String name;

    private String department;
    private String phone;

    @Column(nullable = false)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private Role role;

    // The device this employee last clocked in from -- null until their
    // first clock-in. See ClockRecordService.checkDeviceBinding.
    @Column(name = "bound_device_id")
    private String boundDeviceId;
}
