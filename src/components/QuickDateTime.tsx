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
