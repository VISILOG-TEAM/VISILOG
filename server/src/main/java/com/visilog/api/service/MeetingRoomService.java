package com.visilog.api.service;

import com.visilog.api.dto.BulkImportResult;
import com.visilog.api.dto.MeetingRoomDto;
import com.visilog.api.dto.MeetingRoomRequest;
import com.visilog.api.entity.MeetingRoom;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.MeetingRoomRepository;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MeetingRoomService {

    private final MeetingRoomRepository meetingRoomRepository;

    public MeetingRoomService(MeetingRoomRepository meetingRoomRepository) {
        this.meetingRoomRepository = meetingRoomRepository;
    }

    public List<MeetingRoomDto> list(UUID organizationId) {
        return meetingRoomRepository.findByOrganizationId(organizationId).stream()
                .map(MeetingRoomDto::from)
                .toList();
    }

    @Transactional
    public MeetingRoomDto create(UUID organizationId, MeetingRoomRequest req) {
        MeetingRoom r = new MeetingRoom();
        r.setOrganizationId(organizationId);
        applyRequest(r, req);
        return MeetingRoomDto.from(meetingRoomRepository.save(r));
    }

    @Transactional
    public MeetingRoomDto update(UUID organizationId, UUID roomId, MeetingRoomRequest req) {
        MeetingRoom r = meetingRoomRepository.findByOrganizationIdAndId(organizationId, roomId)
                .orElseThrow(() -> ApiException.notFound("Meeting room not found."));
        applyRequest(r, req);
        return MeetingRoomDto.from(meetingRoomRepository.save(r));
    }

    // CSV bulk import from Company Setup -- see EmployeeService.bulkCreate
    // for why this stays row-by-row and un-@Transactional.
    public BulkImportResult<MeetingRoomDto> bulkCreate(UUID organizationId, List<MeetingRoomRequest> rows) {
        List<MeetingRoomDto> created = new ArrayList<>();
        List<BulkImportResult.RowError> errors = new ArrayList<>();
        for (int i = 0; i < rows.size(); i++) {
            int rowNumber = i + 1;
            try {
                if (rows.get(i).name() == null || rows.get(i).name().isBlank()) {
                    throw ApiException.badRequest("Room name is required.");
                }
                created.add(create(organizationId, rows.get(i)));
            } catch (ApiException ex) {
                errors.add(new BulkImportResult.RowError(rowNumber, ex.getMessage()));
            }
        }
        return new BulkImportResult<>(created, errors);
    }

    @Transactional
    public void delete(UUID organizationId, UUID roomId) {
        MeetingRoom r = meetingRoomRepository.findByOrganizationIdAndId(organizationId, roomId)
                .orElseThrow(() -> ApiException.notFound("Meeting room not found."));
        meetingRoomRepository.delete(r);
    }

    private void applyRequest(MeetingRoom r, MeetingRoomRequest req) {
        r.setName(req.name().trim());
        r.setCapacity(req.capacity());
        r.setFloor(req.floor());
        r.setPhotoUrl(req.photoUrl());
        r.setDescription(req.description());
    }
}
