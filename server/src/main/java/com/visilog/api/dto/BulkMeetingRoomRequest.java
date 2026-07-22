package com.visilog.api.dto;

import java.util.List;

public record BulkMeetingRoomRequest(List<MeetingRoomRequest> rooms) {
}
