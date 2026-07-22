package com.visilog.api.repository;

import com.visilog.api.entity.NfcCard;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NfcCardRepository extends JpaRepository<NfcCard, UUID> {
    List<NfcCard> findByOrganizationId(UUID organizationId);
}
