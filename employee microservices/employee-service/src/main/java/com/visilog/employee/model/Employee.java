package com.visilog.employee.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

@Entity
@Table(name = "employees")
public class Employee {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long employeeId;

   @NotBlank(message = "First name is required")
private String firstName;

@NotBlank(message = "Last name is required")
private String lastName;

@NotBlank(message = "Email is required")
@Email(message = "Email must be valid")
@Column(unique = true)
private String email;

@Pattern(
    regexp = "^[0-9]{10}$",
    message = "Phone number must contain exactly 10 digits"
)
private String phoneNumber;

@NotBlank(message = "Department is required")
private String department;

@NotBlank(message = "Staff role is required")
private String staffRole;

private String officeLocation;

private boolean active;


    public Employee() {
    }

    public Employee(Long employeeId, String firstName, String lastName,
                    String email, String phoneNumber,
                    String department, String staffRole,
                    String officeLocation, boolean active) {

        this.employeeId = employeeId;
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.department = department;
        this.staffRole = staffRole;
        this.officeLocation = officeLocation;
        this.active = active;
    }

    public Long getEmployeeId() {
        return employeeId;
    }

    public void setEmployeeId(Long employeeId) {
        this.employeeId = employeeId;
    }

    public String getFirstName() {
    return firstName;
}

public void setFirstName(String firstName) {
    this.firstName = firstName;
}

public String getLastName() {
    return lastName;
}

public void setLastName(String lastName) {
    this.lastName = lastName;
}

public String getEmail() {
    return email;
}

public void setEmail(String email) {
    this.email = email;
}

public String getPhoneNumber() {
    return phoneNumber;
}

public void setPhoneNumber(String phoneNumber) {
    this.phoneNumber = phoneNumber;
}

public String getDepartment() {
    return department;
}

public void setDepartment(String department) {
    this.department = department;
}

public String getStaffRole() {
    return staffRole;
}

public void setStaffRole(String staffRole) {
    this.staffRole = staffRole;
}

public String getOfficeLocation() {
    return officeLocation;
}

public void setOfficeLocation(String officeLocation) {
    this.officeLocation = officeLocation;
}

public boolean isActive() {
    return active;
}

public void setActive(boolean active) {
    this.active = active;
}

}  