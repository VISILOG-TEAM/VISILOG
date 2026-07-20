package com.visilog.employee.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.visilog.employee.model.Employee;
import com.visilog.employee.service.EmployeeService;

@RestController
@RequestMapping("/api/employees")
public class EmployeeController {

    private final EmployeeService employeeService;

    public EmployeeController(EmployeeService employeeService) {
        this.employeeService = employeeService;
    }

    @GetMapping
    public ResponseEntity<List<Employee>> getAllEmployees() {
        return ResponseEntity.ok(employeeService.getAllEmployees());
    }

    @GetMapping("/{employeeId}")
    public ResponseEntity<Employee> getEmployeeById(
            @PathVariable Long employeeId
    ) {
        return ResponseEntity.ok(
                employeeService.getEmployeeById(employeeId)
        );
    }

    @PostMapping
    public ResponseEntity<Employee> createEmployee(
            @RequestBody Employee employee
    ) {
        Employee createdEmployee =
                employeeService.createEmployee(employee);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(createdEmployee);
    }

    @PutMapping("/{employeeId}")
    public ResponseEntity<Employee> updateEmployee(
            @PathVariable Long employeeId,
            @RequestBody Employee employee
    ) {
        return ResponseEntity.ok(
                employeeService.updateEmployee(employeeId, employee)
        );
    }

    @DeleteMapping("/{employeeId}")
    public ResponseEntity<Void> deleteEmployee(
            @PathVariable Long employeeId
    ) {
        employeeService.deleteEmployee(employeeId);
        return ResponseEntity.noContent().build();
    }
}
