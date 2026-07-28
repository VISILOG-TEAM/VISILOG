import React, { useRef, useState } from 'react';
import { View, Pressable, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Card from './Card';
import Button from './Button';
import Input from './Input';
import Select from './Select';
import MultiSelect from './MultiSelect';
import Segmented from './Segmented';
import Text from './Text';
import { DatePicker, TimePicker } from './QuickDateTime';
import { StepProgress, StepNav } from './FormSteps';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { ApiError } from '../api/client';
import type { ExternalGuest } from '../types';

type LocationType = 'room' | 'outside';
type Priority = 'normal' | 'important' | 'urgent';

interface BookMeetingFormProps {
  onDone?: () => void;
}

// BookMeetingForm -- self-service internal meeting booking. Shared by
// Employee, Manager (EmployeeBookScreen) and Receptionist (the
// "Internal meeting" pane on VisitorBookingScreen), so an
// Administrator or anyone else can invite whoever they need -- not
// just their own direct reports -- and can book either one of the
// company's meeting rooms or an outside location (a client's office,
// a restaurant, etc.) for meetings that don't happen on-site. The
// organiser is derived server-side from the signed-in user's own
// employee record -- see RoomBookingController.
//
// Split across four steps rather than one very long scroll: on a phone
// the single-page version ran well past two screenfuls, so the Book
// button was invisible from the top and it was genuinely unclear
// whether anything was still required. Order follows what has to be
// decided first -- you can't invite people to a meeting that doesn't
// have a subject or a place yet -- and the last step is a plain
// summary, because the one thing worth double-checking before
// committing is the details, not re-editing them.
const STEPS = ['Details', 'People', 'When', 'Review'];

export default function BookMeetingForm({ onDone }: BookMeetingFormProps) {
  const { colors } = useTheme();
  const { employees, meetingRooms, bookRoom } = useData();

  const [title, setTitle] = useState('');
  const [locationType, setLocationType] = useState<LocationType>('room');
  const [roomId, setRoomId] = useState<string | null>(null);
  const [outsideLocation, setOutsideLocation] = useState('');
  const [attendeeIds, setAttendeeIds] = useState<string[]>([]);
  const [externalGuests, setExternalGuests] = useState<ExternalGuest[]>([]);
  const [guestName, setGuestName] = useState('');
  const [guestEmail, setGuestEmail] = useState('');
  const [guestPhone, setGuestPhone] = useState('');
  const [priority, setPriority] = useState<Priority>('normal');
  const [date, setDate] = useState(formatDate(new Date()));
  const [startTime, setStartTime] = useState('10:00');
  const [endTime, setEndTime] = useState('11:00');
  const [submitting, setSubmitting] = useState(false);
  const submittingRef = useRef(false);
  const [step, setStep] = useState(0);

  const onAddGuest = () => {
    if (!guestName.trim()) {
      Alert.alert('Almost there', "Give the guest's name.");
      return;
    }
    if (!guestEmail.trim() && !guestPhone.trim()) {
      Alert.alert(
        'Almost there',
        'Add an email or phone number so the guest can actually be reached.',
      );
      return;
    }
    setExternalGuests((gs) => [
      ...gs,
      {
        name: guestName.trim(),
        email: guestEmail.trim() || null,
        phone: guestPhone.trim() || null,
      },
    ]);
    setGuestName('');
    setGuestEmail('');
    setGuestPhone('');
  };

  const onRemoveGuest = (index: number) => {
    setExternalGuests((gs) => gs.filter((_, i) => i !== index));
  };

  // Step 1 is the only one with anything mandatory: a meeting needs a
  // subject and somewhere to happen. Attendees are optional (a solo
  // room booking is legitimate) and the times always have a value.
  const detailsProblem = (): string | null => {
    if (!title.trim()) return 'Give the meeting a title.';
    if (locationType === 'room' && !roomId) return 'Pick a meeting room.';
    if (locationType === 'outside' && !outsideLocation.trim()) return 'Enter a location.';
    return null;
  };

  const onNext = () => {
    if (step === 0) {
      const problem = detailsProblem();
      if (problem) {
        Alert.alert('Almost there', problem);
        return;
      }
    }
    if (step === STEPS.length - 1) {
      onSubmit();
      return;
    }
    setStep((s) => s + 1);
  };

  const onSubmit = async () => {
    if (submittingRef.current) return;
    // Re-checked here rather than trusting that step 1 was passed --
    // this is what actually guards the API call.
    const problem = detailsProblem();
    if (problem) {
      Alert.alert('Almost there', problem);
      setStep(0);
      return;
    }
    submittingRef.current = true;
    setSubmitting(true);
    try {
      await bookRoom({
        title: title.trim(),
        roomId: locationType === 'room' ? roomId : null,
        location: locationType === 'outside' ? outsideLocation.trim() : '',
        startTime: toInstant(date, startTime),
        endTime: toInstant(date, endTime),
        participantIds: attendeeIds,
        externalGuests,
        priority,
      });
      Alert.alert('Booked', `${title} is on the calendar.`, [{ text: 'Done', onPress: onDone }]);
    } catch (err) {
      Alert.alert(
        'Could not book meeting',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
    } finally {
      submittingRef.current = false;
      setSubmitting(false);
    }
  };

  const placeLabel =
    locationType === 'room'
      ? meetingRooms.find((r) => r.id === roomId)?.name || 'No room picked'
      : outsideLocation.trim() || 'No location entered';
  const peopleCount = attendeeIds.length + externalGuests.length;

  return (
    <>
      <Card>
        <StepProgress steps={STEPS} current={step} />

        {step === 0 ? (
          <>
        <Input
          label="Meeting title"
          value={title}
          onChangeText={setTitle}
          placeholder="e.g. Candidate interview"
          icon="briefcase-outline"
        />

        <Segmented
          value={locationType}
          onChange={(v) => {
            setLocationType(v);
            setRoomId(null);
            setOutsideLocation('');
          }}
          options={[
            { label: 'Meeting room', value: 'room' },
            { label: 'Outside location', value: 'outside' },
          ]}
          style={{ marginBottom: spacing.md }}
        />

        <Segmented
          value={priority}
          onChange={setPriority}
          options={[
            { label: 'Normal', value: 'normal' },
            { label: 'Important', value: 'important' },
            { label: 'Urgent', value: 'urgent' },
          ]}
          style={{ marginBottom: spacing.md }}
        />

        {locationType === 'room' ? (
          <Select
            label="Room"
            placeholder="Pick a room..."
            value={roomId}
            onChange={setRoomId}
            icon="business-outline"
            options={meetingRooms.map((r) => ({
              label: r.name,
              value: r.id,
              sublabel: `${r.floor} - Capacity ${r.capacity}`,
            }))}
            emptyMessage={
              'No meeting rooms have been set up yet.\n\n' +
              'Ask your Administrator to add one in Company Setup > Meeting rooms, ' +
              'or switch to "Outside location" above to book somewhere else.'
            }
          />
        ) : (
          <Input
            label="Location"
            value={outsideLocation}
            onChangeText={setOutsideLocation}
            placeholder="e.g. Client's office, Accra Mall"
            icon="location-outline"
          />
        )}
          </>
        ) : null}

        {step === 1 ? (
          <>
        <MultiSelect
          label="Invite staff (optional)"
          placeholder="Anyone from the staff directory..."
          values={attendeeIds}
          onChange={setAttendeeIds}
          icon="people-outline"
          options={employees.map((e) => ({
            label: e.name,
            value: e.id,
            sublabel: e.department,
          }))}
          emptyMessage={
            'No staff have been added to the directory yet.\n\n' +
            'Ask your Administrator to add them in Company Setup > Staff roster. ' +
            'You can still invite outside guests below.'
          }
        />

        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>
          Outside guests (optional)
        </Text>
        {externalGuests.map((g, i) => (
          <View key={i} style={[styles.guestRow, { borderColor: colors.border }]}>
            <View style={{ flex: 1 }}>
              <Text variant="bodySemibold">{g.name}</Text>
              <Text variant="caption" color={colors.textSecondary}>
                {[g.email, g.phone].filter(Boolean).join(' - ')}
              </Text>
            </View>
            <Pressable onPress={() => onRemoveGuest(i)} hitSlop={8}>
              <Ionicons name="close-circle" size={20} color={colors.textMuted} />
            </Pressable>
          </View>
        ))}
        <Input
          label="Guest name"
          value={guestName}
          onChangeText={setGuestName}
          placeholder="e.g. Kwame Mensah (client)"
          icon="person-add-outline"
        />
        <View style={styles.guestContactRow}>
          <View style={{ flex: 1 }}>
            <Input
              label="Email"
              value={guestEmail}
              onChangeText={setGuestEmail}
              placeholder="them@example.com"
              icon="mail-outline"
              autoCapitalize="none"
              keyboardType="email-address"
            />
          </View>
          <View style={{ width: spacing.sm }} />
          <View style={{ flex: 1 }}>
            <Input
              label="Phone"
              value={guestPhone}
              onChangeText={setGuestPhone}
              placeholder="Optional"
              icon="call-outline"
              keyboardType="phone-pad"
            />
          </View>
        </View>
        <Pressable
          onPress={onAddGuest}
          style={[styles.addGuestBtn, { borderColor: colors.primary }]}
        >
          <Ionicons name="add-circle-outline" size={18} color={colors.primary} />
          <Text variant="bodySemibold" color={colors.primary} style={{ marginLeft: 6 }}>
            Add guest
          </Text>
        </Pressable>
          </>
        ) : null}

        {step === 2 ? (
          <>
        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>
          Date
        </Text>
        <DatePicker value={date} onChange={setDate} />
        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>
          Start time
        </Text>
        <TimePicker value={startTime} onChange={setStartTime} />
        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>
          End time
        </Text>
        <TimePicker value={endTime} onChange={setEndTime} />
          </>
        ) : null}

        {step === 3 ? (
          <>
            <Text variant="h3" style={{ marginBottom: spacing.sm }}>
              {title.trim() || 'Untitled meeting'}
            </Text>
            <SummaryRow icon="location-outline" label="Where" value={placeLabel} />
            <SummaryRow icon="calendar-outline" label="Date" value={date} />
            <SummaryRow icon="time-outline" label="Time" value={`${startTime} - ${endTime}`} />
            <SummaryRow
              icon="people-outline"
              label="People"
              value={
                peopleCount === 0
                  ? 'Just you'
                  : `${peopleCount} invited` +
                    (externalGuests.length ? ` (${externalGuests.length} outside)` : '')
              }
            />
            <SummaryRow
              icon="flag-outline"
              label="Priority"
              value={priority.charAt(0).toUpperCase() + priority.slice(1)}
            />
            <Text variant="caption" color={colors.textSecondary} style={{ marginTop: spacing.sm }}>
              Tap Back to change anything. Everyone invited gets a notification, and outside
              guests are emailed an invitation.
            </Text>
          </>
        ) : null}
      </Card>

      <StepNav
        current={step}
        total={STEPS.length}
        onBack={() => setStep((s) => Math.max(0, s - 1))}
        onNext={onNext}
        finishLabel="Book meeting"
        finishIcon="checkmark-circle-outline"
        loading={submitting}
      />
    </>
  );
}

function SummaryRow({
  icon,
  label,
  value,
}: {
  icon: React.ComponentProps<typeof Ionicons>['name'];
  label: string;
  value: string;
}) {
  const { colors } = useTheme();
  return (
    <View style={styles.summaryRow}>
      <Ionicons name={icon} size={16} color={colors.textMuted} />
      <Text variant="caption" color={colors.textSecondary} style={styles.summaryLabel}>
        {label}
      </Text>
      <Text variant="bodyMd" style={{ flex: 1, textAlign: 'right' }} numberOfLines={2}>
        {value}
      </Text>
    </View>
  );
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

// The backend expects a full ISO instant (with seconds + timezone);
// "YYYY-MM-DDTHH:MM" alone isn't parseable as one and was silently
// failing every booking with a generic "Something went wrong" error.
// Routing through a real Date and toISOString() also correctly
// converts from the device's local time to UTC.
function toInstant(dateStr: string, timeStr: string): string {
  return new Date(`${dateStr}T${timeStr}:00`).toISOString();
}

const styles = StyleSheet.create({
  chipsLabel: { marginBottom: spacing.xs },
  summaryRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 6 },
  summaryLabel: { marginLeft: 8, width: 68 },
  guestRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.sm,
    marginBottom: spacing.sm,
  },
  guestContactRow: { flexDirection: 'row' },
  addGuestBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderRadius: radius.md,
    borderStyle: 'dashed',
    height: 44,
    marginBottom: spacing.md,
  },
});
