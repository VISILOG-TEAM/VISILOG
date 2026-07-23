package com.visilog.api.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.visilog.api.dto.ClockActionRequest;
import com.visilog.api.entity.ClockRecord;
import com.visilog.api.entity.Employee;
import com.visilog.api.exception.ApiException;
import com.visilog.api.repository.ClockRecordRepository;
import com.visilog.api.repository.EmployeeRepository;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class ClockRecordServiceTest {

    @Mock private ClockRecordRepository clockRecordRepository;
    @Mock private EmployeeRepository employeeRepository;

    private ClockRecordService service;
    private final UUID orgId = UUID.randomUUID();
    private final UUID employeeId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new ClockRecordService(clockRecordRepository, employeeRepository);
    }

    private void stubNotClockedInToday() {
        when(clockRecordRepository.existsByOrganizationIdAndEmployeeIdAndTypeAndTimestampBetween(
                any(), any(), any(), any(), any())).thenReturn(false);
    }

    private void stubSaveEchoesRecord() {
        when(clockRecordRepository.save(any())).thenAnswer(inv -> {
            ClockRecord r = inv.getArgument(0);
            r.setId(UUID.randomUUID());
            return r;
        });
    }

    @Test
    void firstClockInOfTheDaySucceeds() {
        stubNotClockedInToday();
        stubSaveEchoesRecord();

        var result = service.clockIn(orgId, new ClockActionRequest(employeeId, "Wendy Abagna", null));

        assertThat(result.type()).isEqualTo("IN");
        assertThat(result.employeeId()).isEqualTo(employeeId);
    }

    @Test
    void secondClockInSameDayIsRejected() {
        when(clockRecordRepository.existsByOrganizationIdAndEmployeeIdAndTypeAndTimestampBetween(
                any(), any(), any(), any(), any())).thenReturn(true);

        assertThatThrownBy(() -> service.clockIn(orgId, new ClockActionRequest(employeeId, "Wendy Abagna", null)))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("once per day");
    }

    @Test
    void clockOutIsNeverBlockedByTheDailyLimit() {
        stubSaveEchoesRecord();

        var result = service.clockOut(orgId, new ClockActionRequest(employeeId, "Wendy Abagna", null));

        assertThat(result.type()).isEqualTo("OUT");
    }

    @Test
    void firstClockInFromAnyDeviceBindsIt() {
        stubNotClockedInToday();
        stubSaveEchoesRecord();
        Employee employee = new Employee();
        when(employeeRepository.findByOrganizationIdAndId(orgId, employeeId)).thenReturn(Optional.of(employee));

        service.clockIn(orgId, new ClockActionRequest(employeeId, "Wendy Abagna", "device-a"));

        assertThat(employee.getBoundDeviceId()).isEqualTo("device-a");
    }

    @Test
    void clockInFromTheSameBoundDeviceSucceeds() {
        stubNotClockedInToday();
        stubSaveEchoesRecord();
        Employee employee = new Employee();
        employee.setBoundDeviceId("device-a");
        when(employeeRepository.findByOrganizationIdAndId(orgId, employeeId)).thenReturn(Optional.of(employee));

        var result = service.clockIn(orgId, new ClockActionRequest(employeeId, "Wendy Abagna", "device-a"));

        assertThat(result.type()).isEqualTo("IN");
    }

    @Test
    void clockInFromADifferentDeviceThanTheBoundOneIsRejected() {
        stubNotClockedInToday();
        Employee employee = new Employee();
        employee.setBoundDeviceId("device-a");
        when(employeeRepository.findByOrganizationIdAndId(orgId, employeeId)).thenReturn(Optional.of(employee));

        assertThatThrownBy(() -> service.clockIn(orgId, new ClockActionRequest(employeeId, "Wendy Abagna", "device-b")))
                .isInstanceOf(ApiException.class)
                .hasMessageContaining("different phone");
    }

    @Test
    void clockInWithNoDeviceIdSkipsTheBindingCheck() {
        stubNotClockedInToday();
        stubSaveEchoesRecord();

        var result = service.clockIn(orgId, new ClockActionRequest(employeeId, "Wendy Abagna", null));

        assertThat(result.type()).isEqualTo("IN");
    }
}
