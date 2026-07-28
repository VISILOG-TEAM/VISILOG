import React, { useState } from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import Input from './Input';
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
// Deliberately a plain text field rather than the OS date picker module:
// keeps this working in stock Expo Go instead of requiring a custom dev
// client build.
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
      {expanded ? (
        <Input
          value={value}
          onChangeText={onChange}
          placeholder="YYYY-MM-DD"
          icon="calendar-outline"
          style={{ marginTop: spacing.xs }}
        />
      ) : null}
    </View>
  );
}

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
