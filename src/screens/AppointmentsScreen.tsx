import React, { useCallback, useMemo, useRef, useState } from 'react';
import {
  View, FlatList, StyleSheet, Alert, Modal, TextInput, Pressable, KeyboardAvoidingView,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, Button, Segmented, EmptyState, Avatar, RescheduleModal,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime, fmtDate } from '../data/format';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type {
  Appointment, AppointmentStatus, IoniconName, MeetingRoom, RoomBooking, StatusKey,
} from '../types';

interface AppointmentsScreenProps {
  navigation: RootStackNavigation;
}

type AppointmentsView = 'appointments' | 'rooms';

// AppointmentsScreen
// Pre-scheduled visits with three statuses from the spec:
//   - Pending  (needs receptionist action)
//   - Admitted (already approved + checked in)
//   - Rejected (denied entry)
// Each pending row has one-tap Admit / Reject buttons. A top-level
// slider also switches over to a Meeting Rooms view (available /
// booked / in-use), since reception manages both from one screen.
export default function AppointmentsScreen({ navigation }: AppointmentsScreenProps) {
  const [view, setView] = useState<AppointmentsView>('appointments');

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title={view === 'appointments' ? 'Appointments' : 'Meetings'}
          subtitle={view === 'appointments' ? 'Pre-booked visits & approvals' : 'Everything booked, on-site or outside'}
        />
        <Segmented
          value={view}
          onChange={setView}
          options={[
            { label: 'Appointments', value: 'appointments' },
            { label: 'Meetings', value: 'rooms' },
          ]}
          style={{ marginBottom: spacing.sm }}
        />
      </View>

      {view === 'appointments' ? <AppointmentsList /> : <MeetingsView />}
    </Screen>
  );
}

type AppointmentFilter = AppointmentStatus | 'all';

function AppointmentsList() {
  const { user } = useAuth();
  const { appointments, updateAppointmentStatus, admitAppointment } = useData();
  const [filter, setFilter] = useState<AppointmentFilter>('pending');
  const [rescheduling, setRescheduling] = useState<Appointment | null>(null);
  const [rejecting, setRejecting] = useState<Appointment | null>(null);
  // Only Employees (and Visitors, on their own Visits screen) can edit
  // an appointment's time -- Receptionist/Manager use Admit/Reject instead.
  const canReschedule = user?.role === 'employee';
  // Tapping "Admit" twice before the first request finishes used to
  // check the same visitor in twice -- the row doesn't leave the
  // pending list until the response comes back, so a second tap in
  // that window fired a second, real admit. Track in-flight ids
  // synchronously (a ref, not state) so the second tap is ignored.
  const admittingRef = useRef(new Set<string>());

  const filtered = useMemo(
    () => appointments
      .filter((a) => filter === 'all' || a.status === filter)
      .sort((a, b) => new Date(a.scheduledAt).getTime() - new Date(b.scheduledAt).getTime()),
    [appointments, filter]
  );

  const onAdmit = (appt: Appointment) => {
    if (admittingRef.current.has(appt.id)) return;
    Alert.alert(
      'Admit visitor?',
      `${appt.visitorName} will be registered and checked in.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Admit',
          onPress: async () => {
            if (admittingRef.current.has(appt.id)) return;
            admittingRef.current.add(appt.id);
            try {
              const v = await admitAppointment(appt);
              Alert.alert('Admitted', `${v.fullName} - ${v.badgeId}`);
            } catch (err) {
              Alert.alert('Could not admit visitor', err instanceof ApiError ? err.message : 'Something went wrong.');
            } finally {
              admittingRef.current.delete(appt.id);
            }
          },
        },
      ]
    );
  };

  const onReject = (appt: Appointment) => setRejecting(appt);

  const onConfirmReject = async (reason: string) => {
    if (!rejecting) return;
    try {
      await updateAppointmentStatus(rejecting.id, 'rejected', reason);
      setRejecting(null);
    } catch (err) {
      Alert.alert('Could not reject', err instanceof ApiError ? err.message : 'Something went wrong.');
    }
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
                ? "You're all caught up - no visitors waiting for approval."
                : 'Try a different filter to see appointments in other states.'
            }
          />
        }
        renderItem={({ item }) => (
          <AppointmentRow
            appointment={item}
            canAct={!!user?.employeeId && user.employeeId === item.hostId}
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

      <RejectReasonModal
        visible={!!rejecting}
        visitorName={rejecting?.visitorName || ''}
        canReschedule={canReschedule}
        onCancel={() => setRejecting(null)}
        onConfirm={onConfirmReject}
        onRescheduleInstead={() => {
          const appt = rejecting;
          setRejecting(null);
          if (appt) setRescheduling(appt);
        }}
      />
    </>
  );
}

interface AppointmentRowProps {
  appointment: Appointment;
  canAct: boolean;
  onAdmit: () => void;
  onReject: () => void;
  onReschedule: (() => void) | null;
}

function AppointmentRow({ appointment, canAct, onAdmit, onReject, onReschedule }: AppointmentRowProps) {
  const { employeeById } = useData();
  const host = employeeById(appointment.hostId);
  const accent: StatusKey =
    appointment.status === 'admitted' ? 'success' :
    appointment.status === 'rejected' ? 'rejected' :
    'pending';
  const badgeStatus: StatusKey =
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
        {/* NFC code, visible so reception can read it aloud if a card fails --
            only assigned once admitted, see AppointmentService.admit */}
        <MetaRow icon="card-outline" text={`Code: ${appointment.nfcCode || 'Not yet issued'}`} />
        {appointment.rescheduleReason ? (
          <MetaRow icon="swap-horizontal-outline" text={`Rescheduled: ${appointment.rescheduleReason}`} />
        ) : null}
        {appointment.rejectReason ? (
          <MetaRow icon="close-circle-outline" text={`Rejected: ${appointment.rejectReason}`} />
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

      {appointment.status === 'pending' && canAct && (
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

interface RejectReasonModalProps {
  visible: boolean;
  visitorName: string;
  canReschedule: boolean;
  onCancel: () => void;
  onConfirm: (reason: string) => void;
  onRescheduleInstead: () => void;
}

// A reason is now required to reject a visit (per the backend guard in
// AppointmentService.updateStatus) so the host always has a record of
// why -- and if the real issue is just bad timing, "Reschedule instead"
// routes to RescheduleModal rather than turning the visitor away.
function RejectReasonModal({
  visible, visitorName, canReschedule, onCancel, onConfirm, onRescheduleInstead,
}: RejectReasonModalProps) {
  const { colors: themeColors } = useTheme();
  const [reason, setReason] = useState('');

  const onSubmit = () => {
    if (!reason.trim()) {
      Alert.alert('Almost there', 'Please give a reason for rejecting this visit.');
      return;
    }
    onConfirm(reason.trim());
    setReason('');
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onCancel}>
      <KeyboardAvoidingView style={rejectStyles.wrap} behavior="padding">
        <View style={rejectStyles.card}>
          <Text variant="h3">Reject visitor?</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            {visitorName} will be denied entry. Let them know why.
          </Text>
          <TextInput
            value={reason}
            onChangeText={setReason}
            placeholder="e.g. No availability that day"
            placeholderTextColor={colors.textMuted}
            style={rejectStyles.input}
            multiline
          />
          {canReschedule ? (
            <Pressable onPress={onRescheduleInstead} style={rejectStyles.rescheduleLink}>
              <Ionicons name="calendar-outline" size={16} color={themeColors.primary} />
              <Text variant="caption" color={themeColors.primary} style={{ marginLeft: 6 }}>
                Just a scheduling conflict? Reschedule instead
              </Text>
            </Pressable>
          ) : null}
          <View style={rejectStyles.row}>
            <Pressable onPress={onCancel} style={[rejectStyles.btn, rejectStyles.btnGhost]}>
              <Text variant="bodySemibold" color={colors.textSecondary}>Cancel</Text>
            </Pressable>
            <Pressable onPress={onSubmit} style={[rejectStyles.btn, { backgroundColor: themeColors.brand }]}>
              <Text variant="bodySemibold" color={themeColors.textInverse}>Reject</Text>
            </Pressable>
          </View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

function MetaRow({ icon, text }: { icon: IoniconName; text: string }) {
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

type RoomStatus = 'available' | 'booked' | 'inuse';

function roomStatus(
  room: MeetingRoom, roomBookings: RoomBooking[]
): { status: RoomStatus; booking: RoomBooking | null } {
  const now = Date.now();
  const forRoom = roomBookings.filter((b) => b.roomId === room.id);
  const live = forRoom.find(
    (b) => new Date(b.startTime).getTime() <= now && new Date(b.endTime).getTime() > now
  );
  if (live) return { status: 'inuse', booking: live };
  const upcoming = forRoom
    .filter((b) => new Date(b.startTime).getTime() > now)
    .sort((a, b) => new Date(a.startTime).getTime() - new Date(b.startTime).getTime())[0];
  if (upcoming) return { status: 'booked', booking: upcoming };
  return { status: 'available', booking: null };
}

const ROOM_STATUS_META: Record<RoomStatus, { label: string; badge: StatusKey }> = {
  available: { label: 'Available', badge: 'success' },
  booked: { label: 'Booked', badge: 'pending' },
  inuse: { label: 'In use', badge: 'onsite' },
};

// A single FlatList drives the whole screen (every upcoming meeting,
// room-based or an outside location -- previously an outside-location
// booking never showed up *anywhere* after you made it, and a room
// with several bookings only ever showed the single soonest one). The
// per-room availability cards sit in the header as a plain, short,
// non-virtualized list -- nesting a second FlatList in there would
// trigger RN's "VirtualizedLists should never be nested" warning.
// Lets the organiser tell at a glance who's seen the invite and who's
// declined (and see the reason via the row itself is enough detail for
// now -- a full per-person breakdown wasn't asked for).
function responseSummary(responses: RoomBooking['responses']): string {
  const acknowledged = responses.filter((r) => r.status === 'acknowledged').length;
  const declined = responses.filter((r) => r.status === 'declined').length;
  const pending = responses.length - acknowledged - declined;
  const parts: string[] = [];
  if (acknowledged) parts.push(`${acknowledged} seen`);
  if (declined) parts.push(`${declined} declined`);
  if (pending) parts.push(`${pending} pending`);
  return parts.join(' · ') || 'No responses yet';
}

function MeetingsView() {
  const { colors: themeColors } = useTheme();
  const { roomBookings, meetingRooms, employeeById, roomById, refreshRoomBookings } = useData();

  useFocusEffect(
    useCallback(() => {
      refreshRoomBookings().catch(() => {});
    }, [])
  );

  const rooms = useMemo(
    () => meetingRooms.map((r) => ({ room: r, ...roomStatus(r, roomBookings) })),
    [roomBookings, meetingRooms]
  );

  // Not filtered by time at all -- BookMeetingForm defaults to today's
  // date with a fixed 10:00-11:00 window, so a meeting booked later in
  // the day is technically "in the past" the instant it's created; an
  // "upcoming only" filter made it vanish immediately with no way to
  // find it. Newest-booked first, so whatever you just booked is right
  // at the top regardless of what time you picked.
  const sortedMeetings = useMemo(
    () => [...roomBookings].sort((a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime()),
    [roomBookings]
  );

  return (
    <FlatList
      data={sortedMeetings}
      keyExtractor={(b) => b.id}
      contentContainerStyle={styles.list}
      ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
      ListHeaderComponent={
        <>
          {rooms.length > 0 ? (
            <>
              <Text variant="eyebrow" color={colors.textMuted} style={styles.sectionLabel}>
                Rooms
              </Text>
              {rooms.map(({ room, status, booking }) => {
                const meta = ROOM_STATUS_META[status];
                return (
                  <Card key={room.id} style={{ marginBottom: spacing.sm }}>
                    <View style={styles.headRow}>
                      <View style={[styles.roomIcon, { backgroundColor: themeColors.primarySurface }]}>
                        <Ionicons name="business" size={20} color={themeColors.primary} />
                      </View>
                      <View style={{ flex: 1, marginLeft: spacing.sm }}>
                        <Text variant="bodySemibold">{room.name}</Text>
                        <Text variant="caption" color={colors.textSecondary}>
                          {room.floor} · Capacity {room.capacity}
                        </Text>
                      </View>
                      <Badge label={meta.label} status={meta.badge} size="sm" />
                    </View>
                    {booking && status !== 'available' ? (
                      <MetaRow icon="time-outline"
                        text={`Next: ${fmtTime(booking.startTime)} → ${fmtTime(booking.endTime)}`} />
                    ) : null}
                  </Card>
                );
              })}
            </>
          ) : null}
          <Text variant="eyebrow" color={colors.textMuted} style={styles.sectionLabel}>
            All meetings
          </Text>
        </>
      }
      ListEmptyComponent={
        <EmptyState
          icon="calendar-outline"
          title="No meetings booked"
          message="Meetings booked from Book a meeting will show up here, whether they're in a room or an outside location."
        />
      }
      renderItem={({ item }) => {
        const organiser = employeeById(item.organiserId);
        const room = item.roomId ? roomById(item.roomId) : null;
        return (
          <Card style={{ marginHorizontal: spacing.md }}>
            <View style={styles.headRow}>
              <View style={{ flex: 1 }}>
                <Text variant="bodySemibold">{item.title}</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {room ? room.name : item.location || 'Outside location'}
                </Text>
              </View>
              {item.priority !== 'normal' ? (
                <Badge
                  label={item.priority === 'urgent' ? 'Urgent' : 'Important'}
                  status={item.priority === 'urgent' ? 'rejected' : 'pending'}
                  size="sm"
                  dot={false}
                />
              ) : null}
            </View>
            <View style={styles.metaList}>
              <MetaRow icon="time-outline"
                text={`${fmtDate(item.startTime)} · ${fmtTime(item.startTime)} → ${fmtTime(item.endTime)}`} />
              <MetaRow icon="person-outline" text={`Organiser: ${organiser?.name || '--'}`} />
              {item.participantIds?.length ? (
                <MetaRow icon="people-outline" text={`${item.participantIds.length} staff invited`} />
              ) : null}
              {item.externalGuests?.length ? (
                <MetaRow icon="person-add-outline"
                  text={`Guests: ${item.externalGuests.map((g) => g.name).filter(Boolean).join(', ')}`} />
              ) : null}
              {item.responses?.length ? (
                <MetaRow icon="checkmark-done-outline" text={responseSummary(item.responses)} />
              ) : null}
            </View>
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
  sectionLabel: { marginBottom: spacing.sm, marginTop: spacing.xs },
});

const rejectStyles = StyleSheet.create({
  wrap: {
    flex: 1, backgroundColor: 'rgba(10,42,29,0.55)',
    alignItems: 'center', justifyContent: 'center', padding: spacing.lg,
  },
  card: {
    width: '100%', maxWidth: 360,
    backgroundColor: colors.surface,
    borderRadius: radius.lg,
    padding: spacing.lg,
  },
  input: {
    borderWidth: 1, borderColor: colors.border, borderRadius: radius.md,
    paddingHorizontal: spacing.sm, paddingVertical: 10, minHeight: 44,
    fontFamily: fonts.regular, fontSize: 14, color: colors.textPrimary,
  },
  rescheduleLink: { flexDirection: 'row', alignItems: 'center', marginTop: spacing.sm },
  row: { flexDirection: 'row', marginTop: spacing.md, gap: spacing.sm },
  btn: { flex: 1, height: 44, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center' },
  btnGhost: { backgroundColor: colors.surfaceAlt },
});