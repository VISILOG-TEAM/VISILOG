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

          <Field label="New date (YYYY-MM-DD)" value={date} onChangeText={setDate} />
          <Field label="New time (HH:MM)" value={time} onChangeText={setTime} />
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