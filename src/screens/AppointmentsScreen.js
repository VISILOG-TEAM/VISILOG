import React, { useMemo, useState } from 'react';
import { View, FlatList, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, Button, Segmented, EmptyState, Avatar, RescheduleModal,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime, fmtDate } from '../data/format';

// AppointmentsScreen
// Pre-scheduled visits with three statuses from the spec:
//   - Pending  (needs receptionist action)
//   - Admitted (already approved + checked in)
//   - Rejected (denied entry)
// Each pending row has one-tap Admit / Reject buttons. A top-level
// slider also switches over to a Meeting Rooms view (available /
// booked / in-use), since reception manages both from one screen.
export default function AppointmentsScreen({ navigation }) {
  const [view, setView] = useState('appointments');

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title={view === 'appointments' ? 'Appointments' : 'Meeting Rooms'}
          subtitle={view === 'appointments' ? 'Pre-booked visits & approvals' : 'Availability & NFC access'}
        />
        <Segmented
          value={view}
          onChange={setView}
          options={[
            { label: 'Appointments', value: 'appointments' },
            { label: 'Meeting Rooms', value: 'rooms' },
          ]}
          style={{ marginBottom: spacing.sm }}
        />
      </View>

      {view === 'appointments' ? <AppointmentsList /> : <RoomsList />}
    </Screen>
  );
}

function AppointmentsList() {
  const { user } = useAuth();
  const { appointments, updateAppointmentStatus, admitAppointment } = useData();
  const [filter, setFilter] = useState('pending');
  const [rescheduling, setRescheduling] = useState(null);
  // Only Employees (and Visitors, on their own Visits screen) can edit
  // an appointment's time — Receptionist/Manager use Admit/Reject instead.
  const canReschedule = user?.role === 'employee';

  const filtered = useMemo(
    () => appointments
      .filter((a) => filter === 'all' || a.status === filter)
      .sort((a, b) => new Date(a.scheduledAt) - new Date(b.scheduledAt)),
    [appointments, filter]
  );

  const onAdmit = (appt) => {
    Alert.alert(
      'Admit visitor?',
      `${appt.visitorName} will be registered and checked in.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Admit',
          onPress: async () => {
            try {
              const v = await admitAppointment(appt);
              Alert.alert('Admitted', `${v.fullName} - ${v.badgeId}`);
            } catch (err) {
              Alert.alert('Could not admit visitor', err.message);
            }
          },
        },
      ]
    );
  };

  const onReject = (appt) => {
    Alert.alert(
      'Reject visitor?',
      `${appt.visitorName} will be denied entry.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Reject',
          style: 'destructive',
          onPress: () => updateAppointmentStatus(appt.id, 'rejected').catch((err) => Alert.alert('Could not reject', err.message)),
        },
      ]
    );
  };

  return (
    <>
      <View style={styles.subHead}>
        <Segmented
          value={filter}
          onChange={setFilter}
          options={[
            { label: 'Pending', value: 'pending' },
            { label: 'Admitted', value: 'admitted' },
            { label: 'Rejected', value: 'rejected' },
            { label: 'All', value: 'all' },
          ]}
        />
      </View>

      <FlatList
        data={filtered}
        keyExtractor={(a) => a.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="calendar-outline"
            title="No appointments here"
            message={
              filter === 'pending'
                ? 'You’re all caught up - no visitors waiting for approval.'
                : 'Try a different filter to see appointments in other states.'
            }
          />
        }
        renderItem={({ item }) => (
          <AppointmentRow
            appointment={item}
            onAdmit={() => onAdmit(item)}
            onReject={() => onReject(item)}
            onReschedule={canReschedule ? () => setRescheduling(item) : null}
          />
        )}
      />

      <RescheduleModal
        appointment={rescheduling}
        visible={!!rescheduling}
        onClose={() => setRescheduling(null)}
      />
    </>
  );
}

function AppointmentRow({ appointment, onAdmit, onReject, onReschedule }) {
  const { employeeById } = useData();
  const host = employeeById(appointment.hostId);
  const accent =
    appointment.status === 'admitted' ? 'success' :
    appointment.status === 'rejected' ? 'rejected' :
    'pending';
  const badgeStatus =
    appointment.status === 'admitted' ? 'success' :
    appointment.status === 'rejected' ? 'rejected' :
    'pending';

  return (
    <Card accent={accent} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.headRow}>
        <Avatar name={appointment.visitorName} size={44} />
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold">{appointment.visitorName}</Text>
          <Text variant="caption" color={colors.textSecondary}>
            {appointment.visitorCompany || 'Visitor'}
          </Text>
        </View>
        <Badge label={appointment.status} status={badgeStatus} size="sm" />
      </View>

      <View style={styles.metaList}>
        <MetaRow icon="people-outline" text={`Host: ${host?.name || 'Unassigned'}`} />
        <MetaRow icon="briefcase-outline" text={appointment.purpose} />
        <MetaRow
          icon="time-outline"
          text={`${fmtDate(appointment.scheduledAt)} - ${fmtTime(appointment.scheduledAt)}`}
        />
        {/* NFC code, visible so reception can read it aloud if a card fails */}
        <MetaRow icon="card-outline" text={`Code: ${appointment.nfcCode || '—'}`} />
        {appointment.rescheduleReason ? (
          <MetaRow icon="swap-horizontal-outline" text={`Rescheduled: ${appointment.rescheduleReason}`} />
        ) : null}
      </View>

      {onReschedule && (
        <Button
          label="Reschedule"
          variant="secondary"
          icon="calendar-outline"
          onPress={onReschedule}
          style={{ marginBottom: spacing.xs }}
        />
      )}

      {appointment.status === 'pending' && (
        <View style={styles.actionRow}>
          <Button
            label="Reject"
            variant="secondary"
            icon="close-circle-outline"
            onPress={onReject}
            style={{ flex: 1, marginRight: spacing.xs }}
          />
          <Button
            label="Admit"
            icon="checkmark-circle-outline"
            onPress={onAdmit}
            style={{ flex: 1, marginLeft: spacing.xs }}
          />
        </View>
      )}
    </Card>
  );
}

function MetaRow({ icon, text }) {
  return (
    <View style={styles.metaRow}>
      <Ionicons name={icon} size={14} color={colors.textMuted} />
      <Text variant="caption" color={colors.textSecondary} style={{ marginLeft: 6 }}>
        {text}
      </Text>
    </View>
  );
}

// ---- Meeting Rooms view: available / booked / in-use ----

function roomStatus(room, roomBookings) {
  const now = Date.now();
  const forRoom = roomBookings.filter((b) => b.roomId === room.id);
  const live = forRoom.find(
    (b) => new Date(b.startTime).getTime() <= now && new Date(b.endTime).getTime() > now
  );
  if (live) return { status: 'inuse', booking: live };
  const upcoming = forRoom
    .filter((b) => new Date(b.startTime).getTime() > now)
    .sort((a, b) => new Date(a.startTime) - new Date(b.startTime))[0];
  if (upcoming) return { status: 'booked', booking: upcoming };
  return { status: 'available', booking: null };
}

const ROOM_STATUS_META = {
  available: { label: 'Available', badge: 'success' },
  booked: { label: 'Booked', badge: 'pending' },
  inuse: { label: 'In use', badge: 'onsite' },
};

function RoomsList() {
  const { colors: themeColors } = useTheme();
  const { roomBookings, meetingRooms, employeeById } = useData();
  const rooms = useMemo(
    () => meetingRooms.map((r) => ({ room: r, ...roomStatus(r, roomBookings) })),
    [roomBookings, meetingRooms]
  );

  return (
    <FlatList
      data={rooms}
      keyExtractor={(r) => r.room.id}
      contentContainerStyle={styles.list}
      ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
      renderItem={({ item }) => {
        const meta = ROOM_STATUS_META[item.status];
        const organiser = item.booking ? employeeById(item.booking.organiserId) : null;
        return (
          <Card style={{ marginHorizontal: spacing.md }}>
            <View style={styles.headRow}>
              <View style={[styles.roomIcon, { backgroundColor: themeColors.primarySurface }]}>
                <Ionicons name="business" size={20} color={themeColors.primary} />
              </View>
              <View style={{ flex: 1, marginLeft: spacing.sm }}>
                <Text variant="bodySemibold">{item.room.name}</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {item.room.floor} · Capacity {item.room.capacity}
                </Text>
              </View>
              <Badge label={meta.label} status={meta.badge} size="sm" />
            </View>
            {item.booking && (
              <View style={styles.metaList}>
                <MetaRow icon="document-text-outline" text={item.booking.title} />
                <MetaRow
                  icon="time-outline"
                  text={`${fmtTime(item.booking.startTime)} → ${fmtTime(item.booking.endTime)}`}
                />
                <MetaRow icon="person-outline" text={`Organiser: ${organiser?.name || '—'}`} />
              </View>
            )}
          </Card>
        );
      }}
    />
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  subHead: { paddingHorizontal: spacing.md },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  headRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.sm },
  metaList: { gap: 6, marginBottom: spacing.sm },
  metaRow: { flexDirection: 'row', alignItems: 'center' },
  actionRow: { flexDirection: 'row', marginTop: spacing.xs },
  roomIcon: {
    width: 44, height: 44, borderRadius: 12,
    alignItems: 'center', justifyContent: 'center',
  },
});
