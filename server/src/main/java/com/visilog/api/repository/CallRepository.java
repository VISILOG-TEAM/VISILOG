package com.visilog.api.repository;

import com.visilog.api.entity.Call;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CallRepository extends JpaRepository<Call, UUID> {
    List<Call> findByOrganizationIdOrderByTimestampDesc(UUID organizationId);
}
