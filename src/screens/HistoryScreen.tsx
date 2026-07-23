import React, { useMemo, useState } from 'react';
import { View, SectionList, StyleSheet, RefreshControl } from 'react-native';
import {
  Screen, Header, Text, Card, Badge, EmptyState, Avatar, Segmented,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtDate, fmtTime, fmtRelative, splitRecentOlder } from '../data/format';
import type { RootStackScreenProps } from '../types/navigation';
import type { Appointment, RoomBooking, ClockRecord, StatusKey } from '../types';

type HistoryTab = 'appointments' | 'meetings' | 'clock';

// HistoryScreen -- a single place to look back at everything that's
// already happened, split into Recent (last 7 days) and Older like the
// Visitors log. The live/actionable views of each of these already
// exist elsewhere (Appointments/Meetings tab, Attendance screen) --
// this is purely the read-only "what happened" record.
export default function HistoryScreen({ route, navigation }: RootStackScreenProps<'History'>) {
  const [tab, setTab] = useState<HistoryTab>(route.params?.tab || 'appointments');

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="History"
          subtitle="Past appointments, meetings & clock records"
          onBackPress={() => navigation.goBack()}
        />
        <Segmented
          value={tab}
          onChange={setTab}
          options={[
            { label: 'Appointments', value: 'appointments' },
            { label: 'Meetings', value: 'meetings' },
            { label: 'Clock-ins', value: 'clock' },
          ]}
          style={{ marginBottom: spacing.sm }}
        />
      </View>

      {tab === 'appointments' ? (
        <AppointmentsHistory />
      ) : tab === 'meetings' ? (
        <MeetingsHistory />
      ) : (
        <ClockHistory />
      )}
    </Screen>
  );
}

function AppointmentsHistory() {
  const { colors } = useTheme();
  const { appointments, employeeById, refreshAll } = useData();
  const [refreshing, setRefreshing] = useState(false);
  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshAll();
    } finally {
      setRefreshing(false);
    }
  };

  // Only resolved appointments belong in history -- pending ones are
  // still "live" and live on the Appointments tab.
  const past = useMemo(
    () => appointments
      .filter((a) => a.status !== 'pending')
      .sort((a, b) => new Date(b.scheduledAt).getTime() - new Date(a.scheduledAt).getTime()),
    [appointments]
  );
  const sections = useMemo(() => splitRecentOlder(past, (a) => a.scheduledAt), [past]);

  return (
    <SectionList
      sections={sections}
      keyExtractor={(a) => a.id}
      contentContainerStyle={styles.list}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
      renderSectionHeader={({ section }) => (
        <Text variant="eyebrow" color={colors.textMuted} style={[styles.sectionHeader, { backgroundColor: colors.background }]}>
          {section.title}
        </Text>
      )}
      ListEmptyComponent={
        <EmptyState
          icon="calendar-outline"
          title="No history yet"
          message="Admitted and rejected appointments will show up here."
        />
      }
      renderItem={({ item }) => (
        <AppointmentHistoryRow appointment={item} hostName={employeeById(item.hostId)?.name} />
      )}
    />
  );
}

function AppointmentHistoryRow({ appointment, hostName }: { appointment: Appointment; hostName?: string }) {
  const { colors } = useTheme();
  const badgeStatus: StatusKey = appointment.status === 'admitted' ? 'success' : 'rejected';
  return (
    <Card padded={false} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <Avatar name={appointment.visitorName} size={44} />
        <View style={styles.middle}>
          <View style={styles.titleRow}>
            <Text variant="bodySemibold" numberOfLines={1}>{appointment.visitorName}</Text>
            <Badge label={appointment.status} status={badgeStatus} size="sm" />
          </View>
          <Text variant="caption" color={colors.textSecondary} numberOfLines={1}>
            {appointment.purpose} - {hostName || 'No host'}
          </Text>
          <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
            {fmtDate(appointment.scheduledAt)} - {fmtTime(appointment.scheduledAt)}
          </Text>
          {appointment.rejectReason ? (
            <Text variant="caption" color={colors.textMuted} numberOfLines={1}>
              Reason: {appointment.rejectReason}
            </Text>
          ) : null}
        </View>
      </View>
    </Card>
  );
}

function MeetingsHistory() {
  const { colors } = useTheme();
  const { roomBookings, employeeById, roomById, refreshRoomBookings } = useData();
  const [refreshing, setRefreshing] = useState(false);
  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshRoomBookings();
    } finally {
      setRefreshing(false);
    }
  };

  const past = useMemo(
    () => roomBookings
      .filter((b) => new Date(b.endTime).getTime() < Date.now())
      .sort((a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime()),
    [roomBookings]
  );
  const sections = useMemo(() => splitRecentOlder(past, (b) => b.startTime), [past]);

  return (
    <SectionList
      sections={sections}
      keyExtractor={(b) => b.id}
      contentContainerStyle={styles.list}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
      renderSectionHeader={({ section }) => (
        <Text variant="eyebrow" color={colors.textMuted} style={[styles.sectionHeader, { backgroundColor: colors.background }]}>
          {section.title}
        </Text>
      )}
      ListEmptyComponent={
        <EmptyState
          icon="business-outline"
          title="No past meetings"
          message="Meetings show up here once they've ended."
        />
      }
      renderItem={({ item }) => (
        <MeetingHistoryRow
          booking={item}
          organiserName={employeeById(item.organiserId)?.name}
          roomName={item.roomId ? roomById(item.roomId)?.name : undefined}
        />
      )}
    />
  );
}

function MeetingHistoryRow({
  booking, organiserName, roomName,
}: { booking: RoomBooking; organiserName?: string; roomName?: string }) {
  const { colors } = useTheme();
  const absentCount = booking.responses?.filter((r) => r.absent).length || 0;
  return (
    <Card style={{ marginHorizontal: spacing.md }}>
      <Text variant="bodySemibold">{booking.title}</Text>
      <Text variant="caption" color={colors.textSecondary}>
        {roomName || booking.location || 'Outside location'}
      </Text>
      <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
        {fmtDate(booking.startTime)} - {fmtTime(booking.startTime)} to {fmtTime(booking.endTime)}
      </Text>
      <Text variant="caption" color={colors.textMuted}>
        Organiser: {organiserName || '--'}
      </Text>
      {booking.participantIds?.length ? (
        <Text variant="caption" color={colors.textMuted}>
          {absentCount > 0
            ? `${absentCount} of ${booking.participantIds.length} absent`
            : `${booking.participantIds.length} staff invited`}
        </Text>
      ) : null}
    </Card>
  );
}

function ClockHistory() {
  const { colors } = useTheme();
  const { clockRecords, employeeById, refreshClockRecords } = useData();
  const [refreshing, setRefreshing] = useState(false);
  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshClockRecords();
    } finally {
      setRefreshing(false);
    }
  };

  const sorted = useMemo(
    () => [...clockRecords].sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()),
    [clockRecords]
  );
  const sections = useMemo(() => splitRecentOlder(sorted, (t) => t.timestamp), [sorted]);

  return (
    <SectionList
      sections={sections}
      keyExtractor={(t) => t.id}
      contentContainerStyle={styles.list}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      ItemSeparatorComponent={() => <View style={{ height: spacing.xs }} />}
      renderSectionHeader={({ section }) => (
        <Text variant="eyebrow" color={colors.textMuted} style={[styles.sectionHeader, { backgroundColor: colors.background }]}>
          {section.title}
        </Text>
      )}
      ListEmptyComponent={
        <EmptyState
          icon="card-outline"
          title="No clock records yet"
          message="Clock-in/out activity will appear here as it happens."
        />
      }
      renderItem={({ item }) => (
        <ClockHistoryRow record={item} employeeName={employeeById(item.employeeId)?.name} />
      )}
    />
  );
}

function ClockHistoryRow({ record, employeeName }: { record: ClockRecord; employeeName?: string }) {
  const { colors } = useTheme();
  const isIn = record.type === 'in';
  return (
    <Card padded={false} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <Avatar name={employeeName || record.employeeName || 'Unknown'} size={40} />
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold" numberOfLines={1}>
            {employeeName || record.employeeName || 'Unknown employee'}
          </Text>
          <Text variant="caption" color={colors.textMuted}>
            {fmtDate(record.timestamp)} - {fmtTime(record.timestamp)} - {fmtRelative(record.timestamp)}
          </Text>
        </View>
        <Badge label={isIn ? 'Tap in' : 'Tap out'} status={isIn ? 'success' : 'neutral'} size="sm" />
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  sectionHeader: { paddingVertical: spacing.xs },
  row: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  middle: { flex: 1, marginLeft: spacing.sm },
  titleRow: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: 8,
  },
});