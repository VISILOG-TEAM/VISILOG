package com.visilog.api.repository;

import com.visilog.api.entity.Employee;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EmployeeRepository extends JpaRepository<Employee, UUID> {
    List<Employee> findByOrganizationId(UUID organizationId);
    Optional<Employee> findByOrganizationIdAndId(UUID organizationId, UUID id);
    Optional<Employee> findByOrganizationIdAndEmailIgnoreCase(UUID organizationId, String email);
    boolean existsByOrganizationIdAndEmployeeCodeIgnoreCase(UUID organizationId, String employeeCode);
    long countByOrganizationId(UUID organizationId);
}
