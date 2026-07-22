import React, { useMemo, useState } from 'react';
import { ScrollView, View, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import Input from './Input';
import { colors as staticColors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';

const pad = (n: number): string => String(n).padStart(2, '0');
const toDateStr = (d: Date): string => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

interface DateChipsProps {
  value: string;
  onChange: (dateStr: string) => void;
  days?: number;
}

// Tap-to-pick date, no native picker module (so it works in plain Expo
// Go, not just a custom dev client) -- a row of the next N days as
// chips, plus a "Pick a date" fallback for anything further out or in
// the past, since the quick-pick row alone was too restrictive.
export function DateChips({ value, onChange, days = 10 }: DateChipsProps) {
  const { colors } = useTheme();
  const [customOpen, setCustomOpen] = useState(false);
  const options = useMemo(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return Array.from({ length: days }, (_, i) => {
      const d = new Date(today);
      d.setDate(d.getDate() + i);
      const dateStr = toDateStr(d);
      const label = i === 0 ? 'Today' : i === 1 ? 'Tomorrow' : `${WEEKDAYS[d.getDay()]} ${d.getDate()}`;
      return { dateStr, label };
    });
  }, [days]);
  const isQuickPick = options.some((opt) => opt.dateStr === value);

  return (
    <View>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.row}>
        {options.map((opt) => {
          const selected = opt.dateStr === value;
          return (
            <Pressable
              key={opt.dateStr}
              onPress={() => { onChange(opt.dateStr); setCustomOpen(false); }}
              style={[
                styles.chip,
                { borderColor: colors.border, backgroundColor: staticColors.surface },
                selected && { backgroundColor: colors.primary, borderColor: colors.primary },
              ]}
            >
              <Text variant="label" color={selected ? colors.textInverse : staticColors.textPrimary}>
                {opt.label}
              </Text>
            </Pressable>
          );
        })}
      </ScrollView>
      <Pressable
        onPress={() => setCustomOpen((o) => !o)}
        style={[
          styles.customToggle,
          { borderColor: colors.border, backgroundColor: staticColors.surface },
          (customOpen || !isQuickPick) && { backgroundColor: colors.primary, borderColor: colors.primary },
        ]}
      >
        <Ionicons
          name="calendar-outline"
          size={16}
          color={(customOpen || !isQuickPick) ? colors.textInverse : staticColors.textPrimary}
        />
        <Text
          variant="label"
          color={(customOpen || !isQuickPick) ? colors.textInverse : staticColors.textPrimary}
          style={{ marginLeft: 6 }}
        >
          Pick a date
        </Text>
      </Pressable>
      {customOpen || !isQuickPick ? (
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

interface TimeChipsProps {
  value: string;
  onChange: (timeStr: string) => void;
  startHour?: number;
  endHour?: number;
  stepMinutes?: number;
}

// Same idea for time -- half-hour slots across the working day as
// chips, plus a tap-to-open hour/minute stepper (up/down arrows) for
// anything off the half-hour grid.
export function TimeChips({ value, onChange, startHour = 7, endHour = 19, stepMinutes = 30 }: TimeChipsProps) {
  const { colors } = useTheme();
  const [customOpen, setCustomOpen] = useState(false);
  const options = useMemo(() => {
    const slots: string[] = [];
    for (let mins = startHour * 60; mins <= endHour * 60; mins += stepMinutes) {
      slots.push(`${pad(Math.floor(mins / 60))}:${pad(mins % 60)}`);
    }
    return slots;
  }, [startHour, endHour, stepMinutes]);
  const isQuickPick = options.includes(value);

  return (
    <View>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.row}>
        {options.map((t) => {
          const selected = t === value;
          return (
            <Pressable
              key={t}
              onPress={() => { onChange(t); setCustomOpen(false); }}
              style={[
                styles.chip,
                { borderColor: colors.border, backgroundColor: staticColors.surface },
                selected && { backgroundColor: colors.primary, borderColor: colors.primary },
              ]}
            >
              <Text variant="label" color={selected ? colors.textInverse : staticColors.textPrimary}>
                {t}
              </Text>
            </Pressable>
          );
        })}
      </ScrollView>
      <Pressable
        onPress={() => setCustomOpen((o) => !o)}
        style={[
          styles.customToggle,
          { borderColor: colors.border, backgroundColor: staticColors.surface },
          (customOpen || !isQuickPick) && { backgroundColor: colors.primary, borderColor: colors.primary },
        ]}
      >
        <Ionicons
          name="time-outline"
          size={16}
          color={(customOpen || !isQuickPick) ? colors.textInverse : staticColors.textPrimary}
        />
        <Text
          variant="label"
          color={(customOpen || !isQuickPick) ? colors.textInverse : staticColors.textPrimary}
          style={{ marginLeft: 6 }}
        >
          Pick a time
        </Text>
      </Pressable>
      {customOpen || !isQuickPick ? <TimeStepper value={value} onChange={onChange} /> : null}
    </View>
  );
}

function TimeStepper({ value, onChange }: { value: string; onChange: (t: string) => void }) {
  const { colors } = useTheme();
  const [hStr, mStr] = value.split(':');
  const h = Number(hStr) || 0;
  const m = Number(mStr) || 0;

  const setHour = (next: number) => onChange(`${pad(((next % 24) + 24) % 24)}:${pad(m)}`);
  const setMinute = (next: number) => onChange(`${pad(h)}:${pad(((next % 60) + 60) % 60)}`);

  return (
    <View style={[stepperStyles.wrap, { borderColor: colors.border }]}>
      <StepperColumn value={pad(h)} onUp={() => setHour(h + 1)} onDown={() => setHour(h - 1)} colors={colors} />
      <Text variant="h2" style={stepperStyles.colon}>:</Text>
      <StepperColumn value={pad(m)} onUp={() => setMinute(m + 1)} onDown={() => setMinute(m - 1)} colors={colors} />
    </View>
  );
}

function StepperColumn({
  value, onUp, onDown, colors,
}: { value: string; onUp: () => void; onDown: () => void; colors: { primarySurface: string; primary: string } }) {
  return (
    <View style={stepperStyles.col}>
      <Pressable onPress={onUp} style={[stepperStyles.btn, { backgroundColor: colors.primarySurface }]}>
        <Ionicons name="chevron-up" size={18} color={colors.primary} />
      </Pressable>
      <Text variant="h2" style={stepperStyles.value}>{value}</Text>
      <Pressable onPress={onDown} style={[stepperStyles.btn, { backgroundColor: colors.primarySurface }]}>
        <Ionicons name="chevron-down" size={18} color={colors.primary} />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { marginBottom: spacing.xs },
  chip: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.pill,
    borderWidth: 1,
    marginRight: spacing.xs,
  },
  customToggle: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.pill,
    borderWidth: 1,
    marginBottom: spacing.md,
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
    marginBottom: spacing.md,
  },
  col: { alignItems: 'center', width: 64 },
  btn: { width: 44, height: 32, borderRadius: radius.sm, alignItems: 'center', justifyContent: 'center' },
  value: { marginVertical: 4 },
  colon: { marginHorizontal: spacing.sm },
});