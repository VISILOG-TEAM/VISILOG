package com.visilog.api.repository;

import com.visilog.api.entity.AppUser;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AppUserRepository extends JpaRepository<AppUser, UUID> {
    Optional<AppUser> findByOrganizationIdAndEmailIgnoreCase(UUID organizationId, String email);
    boolean existsByOrganizationIdAndEmailIgnoreCase(UUID organizationId, String email);
}
