import React, { useCallback, useMemo, useRef, useState } from 'react';
import {
  View,
  FlatList,
  StyleSheet,
  Alert,
  Modal,
  TextInput,
  Pressable,
  KeyboardAvoidingView,
  ScrollView,
  RefreshControl,
  Linking,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen,
  Header,
  Text,
  Card,
  Badge,
  Button,
  Segmented,
  EmptyState,
  Avatar,
  RescheduleModal,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime, fmtDate } from '../data/format';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type {
  Appointment,
  AppointmentStatus,
  IoniconName,
  MeetingRoom,
  RoomBooking,
  StatusKey,
} from '../types';

interface AppointmentsScreenProps {
  navigation: RootStackNavigation;
}

type AppointmentsView = 'appointments' | 'rooms';

// AppointmentsScreen
// Pre-scheduled visits with status tabs:
// - Awaiting: pending approval from the host
// - Upcoming: admitted visits still in the future (ready to check in)
// - Admitted: all admitted visits
// - Rejected: denied entry
// A top-level slider also switches over to a Meeting Rooms view.
export default function AppointmentsScreen({ navigation }: AppointmentsScreenProps) {
  const [view, setView] = useState<AppointmentsView>('appointments');

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title={view === 'appointments' ? 'Appointments' : 'Meetings'}
          subtitle={
            view === 'appointments'
              ? 'Pre-booked visits & approvals'
              : 'Everything booked, on-site or outside'
          }
          rightIcon="time-outline"
          onRightPress={() =>
            navigation.navigate('History', {
              tab: view === 'appointments' ? 'appointments' : 'meetings',
            })
          }
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

type AppointmentFilter = 'awaiting' | 'upcoming' | 'admitted' | 'rejected';

function AppointmentsList() {
  const { user } = useAuth();
  const { appointments, updateAppointmentStatus, admitAppointment, checkInAppointment, refreshAll } = useData();
  const [filter, setFilter] = useState<AppointmentFilter>('awaiting');
  const [rescheduling, setRescheduling] = useState<Appointment | null>(null);
  const [rejecting, setRejecting] = useState<Appointment | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshAll();
    } finally {
      setRefreshing(false);
    }
  };

  // All roles can reschedule a non-rejected appointment.
  const canReschedule = true;

  const admittingRef = useRef(new Set<string>());
  const checkingInRef = useRef(new Set<string>());

  const now = Date.now();

  const filtered = useMemo(() => {
    const sorted = [...appointments].sort(
      (a, b) => new Date(b.scheduledAt).getTime() - new Date(a.scheduledAt).getTime(),
    );
    if (filter === 'awaiting') return sorted.filter((a) => a.status === 'pending');
    if (filter === 'upcoming')
      return sorted.filter(
        (a) => a.status === 'admitted' && new Date(a.scheduledAt).getTime() > now,
      );
    if (filter === 'admitted') return sorted.filter((a) => a.status === 'admitted');
    if (filter === 'rejected') return sorted.filter((a) => a.status === 'rejected');
    return sorted;
  }, [appointments, filter, now]);

  const onAdmit = (appt: Appointment) => {
    if (admittingRef.current.has(appt.id)) return;
    Alert.alert(
      'Admit visitor?',
      `${appt.visitorName} will be approved. Reception can check them in when they arrive.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Admit',
          onPress: async () => {
            if (admittingRef.current.has(appt.id)) return;
            admittingRef.current.add(appt.id);
            try {
              await admitAppointment(appt);
              Alert.alert('Admitted', `${appt.visitorName} has been approved.`);
            } catch (err) {
              Alert.alert(
                'Could not admit visitor',
                err instanceof ApiError ? err.message : 'Something went wrong.',
              );
            } finally {
              admittingRef.current.delete(appt.id);
            }
          },
        },
      ],
    );
  };

  const onCheckIn = (appt: Appointment) => {
    if (checkingInRef.current.has(appt.id)) return;
    Alert.alert(
      'Check in visitor?',
      `${appt.visitorName} will be registered as on-site. Only press this when they have physically arrived.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Check in',
          onPress: async () => {
            if (checkingInRef.current.has(appt.id)) return;
            checkingInRef.current.add(appt.id);
            try {
              await checkInAppointment(appt.id);
              Alert.alert('Checked in', `${appt.visitorName} is now on-site.`);
            } catch (err) {
              Alert.alert(
                'Could not check in',
                err instanceof ApiError ? err.message : 'Something went wrong.',
              );
            } finally {
              checkingInRef.current.delete(appt.id);
            }
          },
        },
      ],
    );
  };

  const onReject = (appt: Appointment) => setRejecting(appt);

  const onConfirmReject = async (reason: string) => {
    if (!rejecting) return;
    try {
      await updateAppointmentStatus(rejecting.id, 'rejected', reason);
      setRejecting(null);
    } catch (err) {
      Alert.alert(
        'Could not reject',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
    }
  };

  return (
    <>
      <View style={styles.subHead}>
        <Segmented
          value={filter}
          onChange={setFilter}
          options={[
            { label: 'Awaiting', value: 'awaiting' },
            { label: 'Upcoming', value: 'upcoming' },
            { label: 'Admitted', value: 'admitted' },
            { label: 'Rejected', value: 'rejected' },
          ]}
        />
      </View>

      <FlatList
        data={filtered}
        keyExtractor={(a) => a.id}
        contentContainerStyle={styles.list}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="calendar-outline"
            title="No appointments here"
            message={
              filter === 'awaiting'
                ? "You're all caught up — no visits waiting for approval."
                : filter === 'upcoming'
                  ? 'No admitted visits coming up. Admit a pending visit first.'
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
            onCheckIn={() => onCheckIn(item)}
            onReschedule={canReschedule && item.status !== 'rejected' ? () => setRescheduling(item) : null}
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
  onCheckIn: () => void;
  onReschedule: (() => void) | null;
}

function AppointmentRow({
  appointment,
  canAct,
  onAdmit,
  onReject,
  onCheckIn,
  onReschedule,
}: AppointmentRowProps) {
  const { colors } = useTheme();
  const { employeeById } = useData();
  const host = employeeById(appointment.hostId);
  const accent: StatusKey =
    appointment.status === 'admitted'
      ? 'success'
      : appointment.status === 'rejected'
        ? 'rejected'
        : 'pending';
  const badgeStatus: StatusKey =
    appointment.status === 'admitted'
      ? 'success'
      : appointment.status === 'rejected'
        ? 'rejected'
        : 'pending';

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
        <MetaRow icon="card-outline" text={`Code: ${appointment.nfcCode || 'Not yet issued'}`} />
        {appointment.rescheduleReason ? (
          <MetaRow
            icon="swap-horizontal-outline"
            text={`Rescheduled: ${appointment.rescheduleReason}`}
          />
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

      {appointment.status === 'admitted' && !appointment.checkedIn && (
        <Button
          label="Check in visitor"
          icon="log-in-outline"
          onPress={onCheckIn}
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

function RejectReasonModal({
  visible,
  visitorName,
  canReschedule,
  onCancel,
  onConfirm,
  onRescheduleInstead,
}: RejectReasonModalProps) {
  const { colors } = useTheme();
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
        <View style={[rejectStyles.card, { backgroundColor: colors.surface }]}>
          <Text variant="h3">Reject visitor?</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            {visitorName} will be denied entry. Let them know why.
          </Text>
          <TextInput
            value={reason}
            onChangeText={setReason}
            placeholder="e.g. No availability that day"
            placeholderTextColor={colors.textMuted}
            style={[rejectStyles.input, { borderColor: colors.border, color: colors.textPrimary }]}
            multiline
          />
          {canReschedule ? (
            <Pressable onPress={onRescheduleInstead} style={rejectStyles.rescheduleLink}>
              <Ionicons name="calendar-outline" size={16} color={colors.primary} />
              <Text variant="caption" color={colors.primary} style={{ marginLeft: 6 }}>
                Just a scheduling conflict? Reschedule instead
              </Text>
            </Pressable>
          ) : null}
          <View style={rejectStyles.row}>
            <Pressable
              onPress={onCancel}
              style={[rejectStyles.btn, { backgroundColor: colors.surfaceAlt }]}
            >
              <Text variant="bodySemibold" color={colors.textSecondary}>
                Cancel
              </Text>
            </Pressable>
            <Pressable
              onPress={onSubmit}
              style={[rejectStyles.btn, { backgroundColor: colors.brand }]}
            >
              <Text variant="bodySemibold" color={colors.textInverse}>
                Reject
              </Text>
            </Pressable>
          </View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

function MetaRow({ icon, text, onPress }: { icon: IoniconName; text: string; onPress?: () => void }) {
  const { colors } = useTheme();
  const content = (
    <View style={styles.metaRow}>
      <Ionicons name={icon} size={14} color={onPress ? colors.primary : colors.textMuted} />
      <Text
        variant="caption"
        color={onPress ? colors.primary : colors.textSecondary}
        style={{ marginLeft: 6 }}
      >
        {text}
      </Text>
    </View>
  );
  if (onPress) {
    return (
      <Pressable onPress={onPress} hitSlop={6}>
        {content}
      </Pressable>
    );
  }
  return content;
}

// ---- Meeting Rooms view: available / booked / in-use ----

type RoomStatus = 'available' | 'booked' | 'inuse';

function roomStatus(
  room: MeetingRoom,
  roomBookings: RoomBooking[],
): { status: RoomStatus; booking: RoomBooking | null } {
  const now = Date.now();
  const forRoom = roomBookings.filter((b) => b.roomId === room.id);
  const live = forRoom.find(
    (b) => new Date(b.startTime).getTime() <= now && new Date(b.endTime).getTime() > now,
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

function responseSummary(responses: RoomBooking['responses']): string {
  const acknowledged = responses.filter((r) => r.status === 'acknowledged').length;
  const declined = responses.filter((r) => r.status === 'declined').length;
  const pending = responses.length - acknowledged - declined;
  const parts: string[] = [];
  if (acknowledged) parts.push(`${acknowledged} seen`);
  if (declined) parts.push(`${declined} declined`);
  if (pending) parts.push(`${pending} pending`);
  return parts.join(' - ') || 'No responses yet';
}

function MeetingsView() {
  const { colors } = useTheme();
  const { user } = useAuth();
  const {
    roomBookings,
    meetingRooms,
    employeeById,
    roomById,
    refreshRoomBookings,
    rescheduleMeeting,
    markParticipantAbsent,
  } = useData();
  const [attendanceForId, setAttendanceForId] = useState<string | null>(null);
  const [reschedulingId, setReschedulingId] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  useFocusEffect(
    useCallback(() => {
      refreshRoomBookings().catch(() => {});
    }, []),
  );

  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshRoomBookings();
    } finally {
      setRefreshing(false);
    }
  };

  const attendanceBooking = roomBookings.find((b) => b.id === attendanceForId) || null;
  const reschedulingBooking = roomBookings.find((b) => b.id === reschedulingId) || null;

  const onToggleAbsent = (employeeId: string, absent: boolean) => {
    if (!attendanceForId) return;
    markParticipantAbsent(attendanceForId, employeeId, absent).catch((err) =>
      Alert.alert(
        'Could not update attendance',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      ),
    );
  };

  const rooms = useMemo(
    () => meetingRooms.map((r) => ({ room: r, ...roomStatus(r, roomBookings) })),
    [roomBookings, meetingRooms],
  );

  const sortedMeetings = useMemo(
    () =>
      [...roomBookings].sort(
        (a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime(),
      ),
    [roomBookings],
  );

  return (
    <>
      <FlatList
        data={sortedMeetings}
        keyExtractor={(b) => b.id}
        contentContainerStyle={styles.list}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
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
                        <View style={[styles.roomIcon, { backgroundColor: colors.primarySurface }]}>
                          <Ionicons name="business" size={20} color={colors.primary} />
                        </View>
                        <View style={{ flex: 1, marginLeft: spacing.sm }}>
                          <Text variant="bodySemibold">{room.name}</Text>
                          <Text variant="caption" color={colors.textSecondary}>
                            {room.floor} - Capacity {room.capacity}
                          </Text>
                        </View>
                        <Badge label={meta.label} status={meta.badge} size="sm" />
                      </View>
                      {booking && status !== 'available' ? (
                        <MetaRow
                          icon="time-outline"
                          text={`Next: ${fmtTime(booking.startTime)} - ${fmtTime(booking.endTime)}`}
                        />
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
          const isOrganiser = item.organiserId === user?.employeeId;
          const locationText = room ? room.name : item.location || 'Outside location';
          const hasGoogleMapsLocation = !item.roomId && !!item.location;
          return (
            <Card style={{ marginHorizontal: spacing.md }}>
              <View style={styles.headRow}>
                <View style={{ flex: 1 }}>
                  <Text variant="bodySemibold">{item.title}</Text>
                  <Text variant="caption" color={colors.textSecondary}>
                    {locationText}
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
                <MetaRow
                  icon="time-outline"
                  text={`${fmtDate(item.startTime)} - ${fmtTime(item.startTime)} - ${fmtTime(item.endTime)}`}
                />
                <MetaRow icon="person-outline" text={`Organiser: ${organiser?.name || '--'}`} />
                {hasGoogleMapsLocation ? (
                  <MetaRow
                    icon="location-outline"
                    text={item.location}
                    onPress={() =>
                      Linking.openURL(
                        `https://maps.google.com/?q=${encodeURIComponent(item.location)}`,
                      )
                    }
                  />
                ) : null}
                {item.participantIds?.length ? (
                  <MetaRow
                    icon="people-outline"
                    text={`${item.participantIds.length} staff invited`}
                  />
                ) : null}
                {item.externalGuests?.length ? (
                  <MetaRow
                    icon="person-add-outline"
                    text={`Guests: ${item.externalGuests
                      .map((g) => g.name)
                      .filter(Boolean)
                      .join(', ')}`}
                  />
                ) : null}
                {item.responses?.length ? (
                  <MetaRow icon="checkmark-done-outline" text={responseSummary(item.responses)} />
                ) : null}
                {item.rescheduleReason ? (
                  <MetaRow
                    icon="swap-horizontal-outline"
                    text={`Rescheduled: ${item.rescheduleReason}`}
                  />
                ) : null}
              </View>
              {isOrganiser && (
                <Button
                  label="Reschedule"
                  variant="secondary"
                  icon="calendar-outline"
                  onPress={() => setReschedulingId(item.id)}
                  style={{ marginBottom: spacing.xs }}
                />
              )}
              {isOrganiser &&
              item.participantIds?.length &&
              new Date(item.endTime).getTime() < Date.now() ? (
                <Button
                  label="Mark attendance"
                  variant="secondary"
                  icon="checkmark-circle-outline"
                  onPress={() => setAttendanceForId(item.id)}
                />
              ) : null}
            </Card>
          );
        }}
      />
      <MarkAttendanceModal
        visible={!!attendanceForId}
        booking={attendanceBooking}
        onClose={() => setAttendanceForId(null)}
        onToggle={onToggleAbsent}
      />
      <RescheduleMeetingModal
        visible={!!reschedulingId}
        booking={reschedulingBooking}
        onClose={() => setReschedulingId(null)}
        onSave={rescheduleMeeting}
      />
    </>
  );
}

interface RescheduleMeetingModalProps {
  visible: boolean;
  booking: RoomBooking | null;
  onClose: () => void;
  onSave: (id: string, newStartTime: string, newEndTime: string, reason?: string) => Promise<RoomBooking>;
}

function RescheduleMeetingModal({ visible, booking, onClose, onSave }: RescheduleMeetingModalProps) {
  const { colors } = useTheme();
  const [date, setDate] = useState('');
  const [startTime, setStartTime] = useState('');
  const [endTime, setEndTime] = useState('');
  const [reason, setReason] = useState('');
  const [saving, setSaving] = useState(false);

  const onSubmit = async () => {
    if (!booking) return;
    if (!date.trim() || !startTime.trim() || !endTime.trim()) {
      Alert.alert('Almost there', 'New date, start time and end time are all required.');
      return;
    }
    setSaving(true);
    try {
      await onSave(
        booking.id,
        new Date(`${date}T${startTime}:00`).toISOString(),
        new Date(`${date}T${endTime}:00`).toISOString(),
        reason.trim() || undefined,
      );
      setDate('');
      setStartTime('');
      setEndTime('');
      setReason('');
      onClose();
    } catch (err) {
      Alert.alert(
        'Could not reschedule',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <KeyboardAvoidingView style={rejectStyles.wrap} behavior="padding">
        <View style={[rejectStyles.card, { backgroundColor: colors.surface }]}>
          <Text variant="h3">Reschedule meeting</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            {booking?.title}
          </Text>
          <ModalField label="New date (YYYY-MM-DD)" value={date} onChangeText={setDate} colors={colors} />
          <ModalField label="Start time (HH:MM)" value={startTime} onChangeText={setStartTime} colors={colors} />
          <ModalField label="End time (HH:MM)" value={endTime} onChangeText={setEndTime} colors={colors} />
          <ModalField label="Reason (optional)" value={reason} onChangeText={setReason} colors={colors} multiline />
          <View style={rejectStyles.row}>
            <Pressable
              onPress={onClose}
              style={[rejectStyles.btn, { backgroundColor: colors.surfaceAlt }]}
            >
              <Text variant="bodySemibold" color={colors.textSecondary}>
                Cancel
              </Text>
            </Pressable>
            <Pressable
              onPress={onSubmit}
              disabled={saving}
              style={[rejectStyles.btn, { backgroundColor: colors.brand, opacity: saving ? 0.6 : 1 }]}
            >
              <Text variant="bodySemibold" color={colors.textInverse}>
                Save
              </Text>
            </Pressable>
          </View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

function ModalField({
  label,
  value,
  onChangeText,
  colors,
  multiline,
}: {
  label: string;
  value: string;
  onChangeText: (v: string) => void;
  colors: ReturnType<typeof useTheme>['colors'];
  multiline?: boolean;
}) {
  return (
    <View style={{ marginBottom: spacing.sm }}>
      <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: 4 }}>
        {label}
      </Text>
      <TextInput
        value={value}
        onChangeText={onChangeText}
        multiline={multiline}
        style={[rejectStyles.input, { borderColor: colors.border, color: colors.textPrimary }]}
        placeholderTextColor={colors.textMuted}
      />
    </View>
  );
}

interface MarkAttendanceModalProps {
  visible: boolean;
  booking: RoomBooking | null;
  onClose: () => void;
  onToggle: (employeeId: string, absent: boolean) => void;
}

function MarkAttendanceModal({ visible, booking, onClose, onToggle }: MarkAttendanceModalProps) {
  const { colors } = useTheme();
  const { employeeById } = useData();

  if (!booking) return null;

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <View style={rejectStyles.wrap}>
        <View style={[rejectStyles.card, { backgroundColor: colors.surface }]}>
          <Text variant="h3">Mark attendance</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            {booking.title}
          </Text>
          <ScrollView style={{ maxHeight: 320 }}>
            {booking.participantIds.map((id) => {
              const employee = employeeById(id);
              const response = booking.responses.find((r) => r.employeeId === id);
              const absent = response?.absent || false;
              return (
                <View key={id} style={[attendanceStyles.row, { borderBottomColor: colors.border }]}>
                  <Text variant="bodySemibold" style={{ flex: 1 }}>
                    {employee?.name || 'Unknown'}
                  </Text>
                  <Pressable
                    onPress={() => onToggle(id, !absent)}
                    style={[
                      attendanceStyles.pill,
                      { backgroundColor: absent ? colors.status.rejected.solid : colors.brand },
                    ]}
                  >
                    <Text variant="caption" color={colors.textInverse}>
                      {absent ? 'Absent' : 'Present'}
                    </Text>
                  </Pressable>
                </View>
              );
            })}
          </ScrollView>
          <Button
            label="Done"
            variant="secondary"
            onPress={onClose}
            style={{ marginTop: spacing.md }}
          />
        </View>
      </View>
    </Modal>
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
    width: 44,
    height: 44,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sectionLabel: { marginBottom: spacing.sm, marginTop: spacing.xs },
});

const rejectStyles = StyleSheet.create({
  wrap: {
    flex: 1,
    backgroundColor: 'rgba(10,42,29,0.55)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.lg,
  },
  card: {
    width: '100%',
    maxWidth: 360,
    borderRadius: radius.lg,
    padding: spacing.lg,
  },
  input: {
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    paddingVertical: 10,
    minHeight: 44,
    fontFamily: fonts.regular,
    fontSize: 14,
  },
  rescheduleLink: { flexDirection: 'row', alignItems: 'center', marginTop: spacing.sm },
  row: { flexDirection: 'row', marginTop: spacing.md, gap: spacing.sm },
  btn: {
    flex: 1,
    height: 44,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

const attendanceStyles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
  },
  pill: {
    paddingHorizontal: spacing.sm,
    paddingVertical: 6,
    borderRadius: radius.md,
  },
});
