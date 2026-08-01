# VisiLog - real calendar on every date field; Add guest button
# Run from the repository root.
$ErrorActionPreference = 'Stop'

$content = @'
import React, { useState } from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';

const pad = (n: number): string => String(n).padStart(2, '0');

interface DatePickerProps {
  value: string;
  onChange: (dateStr: string) => void;
}

// A single "Pick a date" control. This used to also show a scrolling row
// of quick-pick chips (Today / Tomorrow / Thu 30 ...) above the picker,
// which meant two competing ways to set one field and a very tall form
// -- the chips are gone and only the picker remains.
//
// Opens a real month calendar. It used to expand into a text field you
// had to type "YYYY-MM-DD" into by hand, which is a format people get
// wrong and a keyboard nobody wants for picking a day.
//
// The grid is drawn here rather than pulled from a date-picker library
// on purpose: the OS picker needs a native module (so a custom dev
// client instead of stock Expo Go), and every drop-in calendar package
// brings its own styling that would ignore the org's brand colours.
// A month grid is little enough code to own.
export function DatePicker({ value, onChange }: DatePickerProps) {
  const { colors } = useTheme();
  const [open, setOpen] = useState(false);
  const expanded = open || !!value;

  return (
    <View style={styles.wrap}>
      <Pressable
        onPress={() => setOpen((o) => !o)}
        style={[
          styles.toggle,
          { borderColor: colors.border, backgroundColor: colors.surface },
          expanded && { backgroundColor: colors.primary, borderColor: colors.primary },
        ]}
      >
        <Ionicons
          name="calendar-outline"
          size={16}
          color={expanded ? colors.textInverse : colors.textPrimary}
        />
        <Text
          variant="label"
          color={expanded ? colors.textInverse : colors.textPrimary}
          style={{ marginLeft: 6 }}
        >
          {value ? `Date: ${value}` : 'Pick a date'}
        </Text>
      </Pressable>
      {expanded ? <Calendar value={value} onChange={onChange} /> : null}
    </View>
  );
}

const WEEKDAYS = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const toKey = (y: number, m: number, d: number): string => `${y}-${pad(m + 1)}-${pad(d)}`;

// Month grid. Weeks start Monday. Days before today are shown but not
// selectable -- every date field in this app is scheduling something,
// and a visit booked into last Tuesday helps nobody.
export function Calendar({ value, onChange }: DatePickerProps) {
  const { colors } = useTheme();
  const today = new Date();
  const todayKey = toKey(today.getFullYear(), today.getMonth(), today.getDate());

  // Which month the grid is showing -- starts on the selected date's
  // month, or this month when nothing is chosen yet.
  const parsed = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value || '');
  const [cursor, setCursor] = useState(() =>
    parsed
      ? new Date(Number(parsed[1]), Number(parsed[2]) - 1, 1)
      : new Date(today.getFullYear(), today.getMonth(), 1),
  );

  const year = cursor.getFullYear();
  const month = cursor.getMonth();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  // JS getDay() is Sunday-based; shift so Monday is column 0.
  const leading = (new Date(year, month, 1).getDay() + 6) % 7;

  const cells: (number | null)[] = [
    ...Array<null>(leading).fill(null),
    ...Array.from({ length: daysInMonth }, (_, i) => i + 1),
  ];
  while (cells.length % 7 !== 0) cells.push(null);

  const shiftMonth = (delta: number) => setCursor(new Date(year, month + delta, 1));

  return (
    <View style={[calStyles.wrap, { borderColor: colors.border, backgroundColor: colors.surface }]}>
      <View style={calStyles.header}>
        <Pressable onPress={() => shiftMonth(-1)} hitSlop={10} style={calStyles.nav}>
          <Ionicons name="chevron-back" size={18} color={colors.primary} />
        </Pressable>
        <Text variant="bodySemibold">
          {MONTHS[month]} {year}
        </Text>
        <Pressable onPress={() => shiftMonth(1)} hitSlop={10} style={calStyles.nav}>
          <Ionicons name="chevron-forward" size={18} color={colors.primary} />
        </Pressable>
      </View>

      <View style={calStyles.row}>
        {WEEKDAYS.map((d) => (
          <View key={d} style={calStyles.cell}>
            <Text variant="caption" color={colors.textMuted}>
              {d}
            </Text>
          </View>
        ))}
      </View>

      {Array.from({ length: cells.length / 7 }, (_, week) => (
        <View key={week} style={calStyles.row}>
          {cells.slice(week * 7, week * 7 + 7).map((day, i) => {
            if (day === null) return <View key={`blank${i}`} style={calStyles.cell} />;
            const key = toKey(year, month, day);
            const selected = key === value;
            const isToday = key === todayKey;
            const past = key < todayKey;
            return (
              <Pressable
                key={key}
                disabled={past}
                onPress={() => onChange(key)}
                style={[
                  calStyles.cell,
                  calStyles.day,
                  selected && { backgroundColor: colors.primary },
                  !selected && isToday && { borderWidth: 1, borderColor: colors.primary },
                ]}
              >
                <Text
                  variant="bodyMd"
                  color={
                    selected
                      ? colors.textInverse
                      : past
                        ? colors.textMuted
                        : colors.textPrimary
                  }
                >
                  {day}
                </Text>
              </Pressable>
            );
          })}
        </View>
      ))}
    </View>
  );
}

const calStyles = StyleSheet.create({
  wrap: {
    borderWidth: 1,
    borderRadius: radius.md,
    padding: spacing.sm,
    marginTop: spacing.xs,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: spacing.xs,
  },
  nav: { padding: 4 },
  row: { flexDirection: 'row' },
  cell: { flex: 1, alignItems: 'center', justifyContent: 'center', height: 38 },
  day: { borderRadius: radius.sm },
});

interface TimePickerProps {
  value: string;
  onChange: (timeStr: string) => void;
}

// Single "Pick a time" control -- opens an hour/minute stepper. Same
// reasoning as DatePicker: the half-hour quick-pick chip row that used
// to sit above this has been removed.
export function TimePicker({ value, onChange }: TimePickerProps) {
  const { colors } = useTheme();
  const [open, setOpen] = useState(false);
  const expanded = open || !!value;

  return (
    <View style={styles.wrap}>
      <Pressable
        onPress={() => setOpen((o) => !o)}
        style={[
          styles.toggle,
          { borderColor: colors.border, backgroundColor: colors.surface },
          expanded && { backgroundColor: colors.primary, borderColor: colors.primary },
        ]}
      >
        <Ionicons
          name="time-outline"
          size={16}
          color={expanded ? colors.textInverse : colors.textPrimary}
        />
        <Text
          variant="label"
          color={expanded ? colors.textInverse : colors.textPrimary}
          style={{ marginLeft: 6 }}
        >
          {value ? `Time: ${value}` : 'Pick a time'}
        </Text>
      </Pressable>
      {expanded ? <TimeStepper value={value} onChange={onChange} /> : null}
    </View>
  );
}

function TimeStepper({ value, onChange }: { value: string; onChange: (t: string) => void }) {
  const { colors } = useTheme();
  const [hStr, mStr] = (value || '09:00').split(':');
  const h = Number(hStr) || 0;
  const m = Number(mStr) || 0;

  const setHour = (next: number) => onChange(`${pad(((next % 24) + 24) % 24)}:${pad(m)}`);
  const setMinute = (next: number) => onChange(`${pad(h)}:${pad(((next % 60) + 60) % 60)}`);

  return (
    <View style={[stepperStyles.wrap, { borderColor: colors.border }]}>
      <StepperColumn
        value={pad(h)}
        onUp={() => setHour(h + 1)}
        onDown={() => setHour(h - 1)}
        colors={colors}
      />
      <Text variant="h2" style={stepperStyles.colon}>
        :
      </Text>
      <StepperColumn
        value={pad(m)}
        onUp={() => setMinute(m + 5)}
        onDown={() => setMinute(m - 5)}
        colors={colors}
      />
    </View>
  );
}

function StepperColumn({
  value,
  onUp,
  onDown,
  colors,
}: {
  value: string;
  onUp: () => void;
  onDown: () => void;
  colors: { primarySurface: string; primary: string };
}) {
  return (
    <View style={stepperStyles.col}>
      <Pressable
        onPress={onUp}
        style={[stepperStyles.btn, { backgroundColor: colors.primarySurface }]}
      >
        <Ionicons name="chevron-up" size={18} color={colors.primary} />
      </Pressable>
      <Text variant="h2" style={stepperStyles.value}>
        {value}
      </Text>
      <Pressable
        onPress={onDown}
        style={[stepperStyles.btn, { backgroundColor: colors.primarySurface }]}
      >
        <Ionicons name="chevron-down" size={18} color={colors.primary} />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { marginBottom: spacing.md },
  toggle: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.pill,
    borderWidth: 1,
  },
});

const stepperStyles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingVertical: spacing.md,
    marginTop: spacing.xs,
  },
  col: { alignItems: 'center', width: 64 },
  btn: {
    width: 44,
    height: 32,
    borderRadius: radius.sm,
    alignItems: 'center',
    justifyContent: 'center',
  },
  value: { marginVertical: 4 },
  colon: { marginHorizontal: spacing.sm },
});

'@
$path = Join-Path (Get-Location) 'src\components\QuickDateTime.tsx'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/QuickDateTime.tsx'

$content = @'
import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  Modal,
  TextInput,
  Pressable,
  Alert,
  KeyboardAvoidingView,
  type TextInputProps,
} from 'react-native';
import Text from './Text';
import { DatePicker, TimePicker } from './QuickDateTime';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useData } from '../context/DataContext';
import { ApiError } from '../api/client';
import type { Appointment } from '../types';

interface RescheduleModalProps {
  appointment: Appointment | null;
  visible: boolean;
  onClose: () => void;
}

// RescheduleModal -- lets an Employee or Visitor move an appointment's
// time, but only with a reason on record (per spec). Shared between
// AppointmentsScreen (Employee tab) and VisitorVisitsScreen.
export default function RescheduleModal({ appointment, visible, onClose }: RescheduleModalProps) {
  const { colors } = useTheme();
  const { rescheduleAppointment } = useData();
  const [date, setDate] = useState('');
  const [time, setTime] = useState('');
  const [reason, setReason] = useState('');

  const onSave = async () => {
    if (!appointment) return;
    if (!date.trim() || !time.trim() || !reason.trim()) {
      Alert.alert('Almost there', 'New date, time and a reason are all required.');
      return;
    }
    try {
      await rescheduleAppointment(appointment.id, toInstant(date, time), reason.trim());
      setDate('');
      setTime('');
      setReason('');
      onClose();
    } catch (err) {
      Alert.alert(
        'Could not reschedule',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
    }
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <KeyboardAvoidingView style={styles.wrap} behavior="padding">
        <View style={[styles.card, { backgroundColor: colors.surface }]}>
          <Text variant="h3">Reschedule visit</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            {appointment?.visitorName}
          </Text>

          <Text variant="label" color={colors.textSecondary} style={{ marginBottom: 4 }}>
            New date
          </Text>
          <DatePicker value={date} onChange={setDate} />
          <Text variant="label" color={colors.textSecondary} style={{ marginBottom: 4 }}>
            New time
          </Text>
          <TimePicker value={time} onChange={setTime} />
          <Field label="Reason for change" value={reason} onChangeText={setReason} multiline />

          <View style={styles.row}>
            <Pressable
              onPress={onClose}
              style={[styles.btn, { backgroundColor: colors.surfaceAlt }]}
            >
              <Text variant="bodySemibold" color={colors.textSecondary}>
                Cancel
              </Text>
            </Pressable>
            <Pressable onPress={onSave} style={[styles.btn, { backgroundColor: colors.brand }]}>
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

// The backend expects a full ISO instant (with seconds + timezone);
// "YYYY-MM-DDTHH:MM" alone isn't parseable as one.
function toInstant(dateStr: string, timeStr: string): string {
  return new Date(`${dateStr}T${timeStr}:00`).toISOString();
}

function Field({ label, ...inputProps }: TextInputProps & { label: string }) {
  const { colors } = useTheme();
  return (
    <View style={{ marginBottom: spacing.sm }}>
      <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: 4 }}>
        {label}
      </Text>
      <TextInput
        {...inputProps}
        style={[styles.input, { borderColor: colors.border, color: colors.textPrimary }]}
        placeholderTextColor={colors.textMuted}
      />
    </View>
  );
}

const styles = StyleSheet.create({
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
    fontFamily: fonts.regular,
    fontSize: 14,
  },
  row: { flexDirection: 'row', marginTop: spacing.sm, gap: spacing.sm },
  btn: {
    flex: 1,
    height: 44,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

'@
$path = Join-Path (Get-Location) 'src\components\RescheduleModal.tsx'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/RescheduleModal.tsx'

$content = @'
import React, { useRef, useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen,
  Header,
  Text,
  Card,
  Button,
  Input,
  Select,
  Segmented,
  BookMeetingForm,
} from '../components';
import { DatePicker, TimePicker } from '../components/QuickDateTime';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { visitPurposes } from '../data/mockData';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';

interface VisitorBookingScreenProps {
  navigation: RootStackNavigation;
}

type BookingMode = 'visitor' | 'internal';

// VisitorBookingScreen -- the receptionist's "Book" tab. Defaults to
// the online visitor pre-registration form (booking on behalf of a
// visitor who called or walked up), with a toggle to switch over to
// booking an internal meeting -- reception needs to reserve rooms too,
// not just register outside visitors.
//
// Submitting the visitor form creates a new appointment in 'pending'
// status, mirroring the real visitor-side flow.
export default function VisitorBookingScreen({ navigation }: VisitorBookingScreenProps) {
  const { colors } = useTheme();
  const { employees, bookVisit } = useData();
  const [mode, setMode] = useState<BookingMode>('visitor');

  const [visitorName, setVisitorName] = useState('');
  const [visitorPhone, setVisitorPhone] = useState('');
  const [visitorEmail, setVisitorEmail] = useState('');
  const [visitorCompany, setVisitorCompany] = useState('');
  const [purpose, setPurpose] = useState('Official Business');
  const [otherPurpose, setOtherPurpose] = useState('');
  const [hostId, setHostId] = useState<string | null>(null);
  const [date, setDate] = useState(formatDate(new Date()));
  const [time, setTime] = useState('10:00');
  const [submitting, setSubmitting] = useState(false);
  const submittingRef = useRef(false);

  const onSubmit = async () => {
    if (submittingRef.current) {
      Alert.alert('Already booking', 'This appointment is already being submitted.');
      return;
    }
    if (!visitorName.trim() || !visitorPhone.trim() || !hostId) {
      Alert.alert('Almost there', 'Name, phone and host are required.');
      return;
    }
    if (purpose === 'Other' && !otherPurpose.trim()) {
      Alert.alert('Almost there', 'Please describe the purpose of the visit.');
      return;
    }
    submittingRef.current = true;
    setSubmitting(true);
    try {
      await bookVisit({
        visitorName: visitorName.trim(),
        visitorPhone: visitorPhone.trim(),
        visitorEmail: visitorEmail.trim(),
        visitorCompany: visitorCompany.trim(),
        purpose: purpose === 'Other' ? otherPurpose.trim() : purpose,
        hostId,
        scheduledAt: toInstant(date, time),
      });
      Alert.alert(
        'Appointment requested',
        `${visitorName} is now in the pending queue. The host will be notified to approve the visit.`,
        [{ text: 'Done', onPress: () => navigation.navigate('Home') }],
      );
    } catch (err) {
      Alert.alert(
        'Could not request appointment',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
    } finally {
      submittingRef.current = false;
      setSubmitting(false);
    }
  };

  return (
    <Screen>
      <Header
        eyebrow={mode === 'visitor' ? 'Pre-registration' : 'Self-service'}
        title={mode === 'visitor' ? 'Book a visit' : 'Book a meeting'}
        subtitle={
          mode === 'visitor'
            ? 'Face-to-face bookings taken over the phone or in person'
            : 'Reserve a room (or an outside spot) for an internal meeting'
        }
      />

      <Segmented
        value={mode}
        onChange={setMode}
        options={[
          { label: 'Visitor booking', value: 'visitor' },
          { label: 'Internal meeting', value: 'internal' },
        ]}
        style={{ marginBottom: spacing.md }}
      />

      {mode === 'internal' ? (
        <BookMeetingForm onDone={() => navigation.navigate('Home')} />
      ) : (
        <>
          <Card>
            <View style={[styles.notice, { backgroundColor: colors.primarySurface }]}>
              <Ionicons name="information-circle" size={18} color={colors.primary} />
              <Text variant="caption" color={colors.brand} style={{ marginLeft: 8, flex: 1 }}>
                Pre-booking speeds up reception. You will receive a QR code & badge ID after
                approval.
              </Text>
            </View>

            <Input
              label="Full name"
              value={visitorName}
              onChangeText={setVisitorName}
              placeholder="e.g. Selasi Akoto"
              icon="person-outline"
            />

            <Input
              label="Phone number"
              value={visitorPhone}
              onChangeText={setVisitorPhone}
              placeholder="+233 ..."
              icon="call-outline"
              keyboardType="phone-pad"
            />

            <Input
              label="Email (optional)"
              value={visitorEmail}
              onChangeText={setVisitorEmail}
              placeholder="name@example.com"
              icon="mail-outline"
              autoCapitalize="none"
              keyboardType="email-address"
            />

            <Input
              label="Company (optional)"
              value={visitorCompany}
              onChangeText={setVisitorCompany}
              placeholder="Your organisation"
              icon="business-outline"
            />

            <Select
              label="Purpose"
              value={purpose}
              onChange={setPurpose}
              icon="briefcase-outline"
              options={visitPurposes.map((p) => ({ label: p, value: p }))}
            />

            {purpose === 'Other' ? (
              <Input
                label="Please specify"
                value={otherPurpose}
                onChangeText={setOtherPurpose}
                placeholder="What's the purpose of the visit?"
                icon="create-outline"
              />
            ) : null}

            <Select
              label="Who are you visiting?"
              placeholder="Pick a host..."
              value={hostId}
              onChange={setHostId}
              icon="people-outline"
              options={employees.map((e) => ({
                label: e.name,
                value: e.id,
                sublabel: e.department,
              }))}
            />

            <Text variant="label" color={colors.textSecondary} style={{ marginBottom: 4 }}>
              Date
            </Text>
            <DatePicker value={date} onChange={setDate} />
            <Text variant="label" color={colors.textSecondary} style={{ marginBottom: 4 }}>
              Time
            </Text>
            <TimePicker value={time} onChange={setTime} />
          </Card>

          <Button
            label="Request appointment"
            icon="checkmark-circle-outline"
            onPress={onSubmit}
            loading={submitting}
            style={{ marginTop: spacing.md }}
          />
        </>
      )}
    </Screen>
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
// failing every appointment request with a generic error.
function toInstant(dateStr: string, timeStr: string): string {
  return new Date(`${dateStr}T${timeStr}:00`).toISOString();
}

const styles = StyleSheet.create({
  notice: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    borderRadius: radius.md,
    padding: spacing.sm,
    marginBottom: spacing.md,
  },
  dateRow: { flexDirection: 'row' },
});

'@
$path = Join-Path (Get-Location) 'src\screens\VisitorBookingScreen.tsx'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/VisitorBookingScreen.tsx'

$content = @'
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
        {/* Plain button for the first guest, "+ Add guest" for each one
            after. The plus reads as "another" -- on an empty form it
            suggested there was already a guest above it to add to. */}
        <Pressable
          onPress={onAddGuest}
          style={[styles.addGuestBtn, { borderColor: colors.primary }]}
        >
          {externalGuests.length > 0 ? (
            <Ionicons name="add-circle-outline" size={18} color={colors.primary} />
          ) : null}
          <Text
            variant="bodySemibold"
            color={colors.primary}
            style={externalGuests.length > 0 ? { marginLeft: 6 } : undefined}
          >
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

'@
$path = Join-Path (Get-Location) 'src\components\BookMeetingForm.tsx'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/BookMeetingForm.tsx'

Write-Host ''
Write-Host 'Done. 4 files written.'
Write-Host 'Next: npx tsc --noEmit'
