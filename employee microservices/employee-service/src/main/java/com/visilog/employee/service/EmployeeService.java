package com.visilog.employee.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.visilog.employee.exception.EmployeeNotFoundException;
import com.visilog.employee.model.Employee;
import com.visilog.employee.repository.EmployeeRepository;

@Service
public class EmployeeService {

    private final EmployeeRepository employeeRepository;

    public EmployeeService(EmployeeRepository employeeRepository) {
        this.employeeRepository = employeeRepository;
    }

    public List<Employee> getAllEmployees() {
        return employeeRepository.findAll();
    }

   public Employee getEmployeeById(Long employeeId) {
    return employeeRepository.findById(employeeId)
            .orElseThrow(() ->
                    new EmployeeNotFoundException(employeeId)
            );
}

    public Employee createEmployee(Employee employee) {
        if (employeeRepository.existsByEmail(employee.getEmail())) {
            throw new RuntimeException(
                    "An employee with this email already exists."
            );
        }

        return employeeRepository.save(employee);
    }

    public Employee updateEmployee(
        Long employeeId,
        Employee updatedEmployee
) {
    Employee existingEmployee = getEmployeeById(employeeId);

    boolean emailChanged =
            !existingEmployee.getEmail()
                    .equalsIgnoreCase(updatedEmployee.getEmail());

    if (emailChanged &&
            employeeRepository.existsByEmail(updatedEmployee.getEmail())) {

        throw new RuntimeException(
             "An employee with this email already exists."
        );
    }

    existingEmployee.setFirstName(updatedEmployee.getFirstName());
    existingEmployee.setLastName(updatedEmployee.getLastName());
    existingEmployee.setEmail(updatedEmployee.getEmail());
    existingEmployee.setPhoneNumber(updatedEmployee.getPhoneNumber());
    existingEmployee.setDepartment(updatedEmployee.getDepartment());
    existingEmployee.setStaffRole(updatedEmployee.getStaffRole());
    existingEmployee.setOfficeLocation(updatedEmployee.getOfficeLocation());
    existingEmployee.setActive(updatedEmployee.isActive());

    return employeeRepository.save(existingEmployee);
}
    public void deleteEmployee(Long employeeId) {
        Employee employee = getEmployeeById(employeeId);
        employeeRepository.delete(employee);
    }
}

