package com.visilog.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.visilog.api.dto.ClockActionRequest;
import com.visilog.api.entity.ClockRecord;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.ClockRecordRepository;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class ClockRecordServiceTest {

    @Mock private ClockRecordRepository clockRecordRepository;

    private ClockRecordService service;
    private final UUID orgId = UUID.randomUUID();
    private final UUID employeeId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new ClockRecordService(clockRecordRepository);
    }

    @Test
    void firstClockInOfTheDaySucceeds() {
        when(clockRecordRepository.existsByOrganizationIdAndEmployeeIdAndTypeAndTimestampBetween(
                any(), any(), any(), any(), any())).thenReturn(false);
        when(clockRecordRepository.save(any())).thenAnswer(inv -> {
            ClockRecord r = inv.getArgument(0);
            r.setId(UUID.randomUUID());
            return r;
        });

        var result = service.clockIn(orgId, new ClockActionRequest(employeeId, "Wendy Abagna"));

        assertThat(result.type()).isEqualTo("IN");
        assertThat(result.employeeId()).isEqualTo(employeeId);
    }

    @Test
    void secondClockInSameDayIsRejected() {
        when(clockRecordRepository.existsByOrganizationIdAndEmployeeIdAndTypeAndTimestampBetween(
                any(), any(), any(), any(), any())).thenReturn(true);

        assertThatThrownBy(() -> service.clockIn(orgId, new ClockActionRequest(employeeId, "Wendy Abagna")))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("once per day");
    }

    @Test
    void clockOutIsNeverBlockedByTheDailyLimit() {
        when(clockRecordRepository.save(any())).thenAnswer(inv -> {
            ClockRecord r = inv.getArgument(0);
            r.setId(UUID.randomUUID());
            return r;
        });

        var result = service.clockOut(orgId, new ClockActionRequest(employeeId, "Wendy Abagna"));

        assertThat(result.type()).isEqualTo("OUT");
    }
}
