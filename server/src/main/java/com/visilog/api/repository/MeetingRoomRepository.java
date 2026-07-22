package com.visilog.api.repository;

import com.visilog.api.entity.MeetingRoom;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MeetingRoomRepository extends JpaRepository<MeetingRoom, UUID> {
    List<MeetingRoom> findByOrganizationId(UUID organizationId);
    Optional<MeetingRoom> findByOrganizationIdAndId(UUID organizationId, UUID id);
}
