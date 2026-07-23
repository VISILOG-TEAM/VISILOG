import React, { useState } from 'react';
import {
  View, StyleSheet, Alert, Modal, TextInput, Pressable,
  KeyboardAvoidingView,
} from 'react-native';
import * as LocalAuthentication from 'expo-local-authentication';
import Text from './Text';
import Card from './Card';
import Button from './Button';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime } from '../data/format';
import { isOnWifi } from '../data/wifiCheck';
import { isAtOffice } from '../data/locationCheck';
import { ApiError } from '../api/client';

// ClockCard -- the personal "on the clock" card shared by every role's
// home screen. Backed by DataContext's shared clock ledger (not local
// state) so the Manager's Clock-ins screen sees the same records.
//
// Clocking IN requires: (1) a best-effort WiFi check, (2) a best-effort
// GPS geofence check against the signed-in org's office location, (3)
// confirming it's really you -- an on-device biometric prompt (Face
// ID/fingerprint) when the device has one enrolled, falling back to
// re-entering your own password otherwise (or if the biometric prompt
// itself is cancelled/fails) -- and (4) not having already clocked in
// once today. None of this stops someone who genuinely knows a
// coworker's password/has their fingerprint, but it blocks the far
// more common case of clocking in from a phone someone else left
// signed in and unattended. Clocking OUT never blocks.
export default function ClockCard() {
  const { colors } = useTheme();
  const { user, organization, verifyPassword } = useAuth();
  const { clockRecords, clockIn, clockOut, isClockedIn, hasClockedInToday } = useData();
  const [checking, setChecking] = useState(false);
  const [confirmVisible, setConfirmVisible] = useState(false);
  const [password, setPassword] = useState('');
  const [confirming, setConfirming] = useState(false);

  const employeeId = (user?.employeeId || user?.id) as string;
  const clockedIn = isClockedIn(employeeId);
  const lastRecord = clockRecords.find((c) => c.employeeId === employeeId);
  const doneForToday = !clockedIn && hasClockedInToday(employeeId);

  const performClockIn = async () => {
    try {
      const r = await clockIn(employeeId, user!.name);
      Alert.alert('Checked in', `Welcome. Clocked in at ${fmtTime(r.timestamp)}.`);
    } catch (err) {
      Alert.alert('Could not clock in', err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  const toggle = async () => {
    if (!clockedIn) {
      if (hasClockedInToday(employeeId)) {
        Alert.alert('Already clocked in today', 'You can only clock in once per day -- see you tomorrow.');
        return;
      }
      setChecking(true);
      const onWifi = await isOnWifi();
      if (!onWifi) {
        setChecking(false);
        Alert.alert('Company network required', 'Connect to the company WiFi to clock in.');
        return;
      }
      const locationResult = await isAtOffice(organization?.officeLocation);
      if (!locationResult.ok) {
        setChecking(false);
        Alert.alert('Location check failed', locationResult.error);
        return;
      }

      const hasHardware = await LocalAuthentication.hasHardwareAsync();
      const isEnrolled = hasHardware && await LocalAuthentication.isEnrolledAsync();
      if (isEnrolled) {
        const result = await LocalAuthentication.authenticateAsync({
          promptMessage: 'Confirm it is you to clock in',
          cancelLabel: 'Use password instead',
        });
        setChecking(false);
        if (result.success) {
          await performClockIn();
          return;
        }
        // Cancelled, failed, or "Use password instead" was tapped --
        // fall back to the password modal rather than blocking the
        // clock-in outright (e.g. a dirty fingerprint sensor shouldn't
        // strand someone off the clock all day).
        setPassword('');
        setConfirmVisible(true);
        return;
      }

      setChecking(false);
      setPassword('');
      setConfirmVisible(true);
    } else {
      try {
        const r = await clockOut(employeeId, user!.name);
        Alert.alert('Checked out', `See you next time. Clocked out at ${fmtTime(r.timestamp)}.`);
      } catch (err) {
        Alert.alert('Could not clock out', err instanceof ApiError ? err.message : 'Something went wrong.');
      }
    }
  };

  const onConfirmClockIn = async () => {
    if (!password) return;
    setConfirming(true);
    const result = await verifyPassword(password);
    if (!result.ok) {
      setConfirming(false);
      Alert.alert('Could not verify you', result.error);
      return;
    }
    setConfirmVisible(false);
    setPassword('');
    setConfirming(false);
    await performClockIn();
  };

  return (
    <Card accent={clockedIn ? 'onsite' : 'neutral'}>
      <View style={styles.row}>
        <View style={{ flex: 1 }}>
          <Text variant="caption" color={colors.textSecondary}>Work status</Text>
          <Text variant="h2">{clockedIn ? 'On the clock' : 'Off the clock'}</Text>
          {clockedIn && lastRecord ? (
            <Text variant="caption" color={colors.textMuted}>
              Since {fmtTime(lastRecord.timestamp)}
            </Text>
          ) : doneForToday ? (
            <Text variant="caption" color={colors.textMuted}>
              Done for today -- see you tomorrow.
            </Text>
          ) : null}
        </View>
        <Button
          label={checking ? 'Checking...' : clockedIn ? 'Check out' : doneForToday ? 'Done for today' : 'Check in'}
          icon={clockedIn ? 'log-out-outline' : 'log-in-outline'}
          variant={clockedIn ? 'danger' : 'primary'}
          onPress={toggle}
          disabled={checking || doneForToday}
        />
      </View>

      <ConfirmClockInModal
        visible={confirmVisible}
        password={password}
        onChangePassword={setPassword}
        confirming={confirming}
        onCancel={() => { setConfirmVisible(false); setPassword(''); }}
        onConfirm={onConfirmClockIn}
      />
    </Card>
  );
}

interface ConfirmClockInModalProps {
  visible: boolean;
  password: string;
  onChangePassword: (password: string) => void;
  confirming: boolean;
  onCancel: () => void;
  onConfirm: () => void;
}

// Fallback for devices with no biometric enrolled (or when the
// biometric prompt itself was cancelled/failed) -- see the note on
// ClockCard above.
function ConfirmClockInModal({
  visible, password, onChangePassword, confirming, onCancel, onConfirm,
}: ConfirmClockInModalProps) {
  const { colors } = useTheme();
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onCancel}>
      <KeyboardAvoidingView
        style={styles.modalWrap}
        behavior="padding"
      >
        <View style={[styles.modalCard, { backgroundColor: colors.surface }]}>
          <Text variant="h3">Confirm it's you</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            Re-enter your password to clock in.
          </Text>
          <TextInput
            value={password}
            onChangeText={onChangePassword}
            placeholder="Password"
            placeholderTextColor={colors.textMuted}
            secureTextEntry
            autoFocus
            style={[styles.modalInput, { borderColor: colors.border, color: colors.textPrimary }]}
          />
          <View style={styles.modalRow}>
            <Pressable onPress={onCancel} style={[styles.modalBtn, { backgroundColor: colors.surfaceAlt }]}>
              <Text variant="bodySemibold" color={colors.textSecondary}>Cancel</Text>
            </Pressable>
            <Pressable
              onPress={onConfirm}
              disabled={!password || confirming}
              style={[
                styles.modalBtn,
                { backgroundColor: colors.primary, opacity: !password || confirming ? 0.6 : 1 },
              ]}
            >
              <Text variant="bodySemibold" color={colors.textInverse}>
                {confirming ? 'Checking...' : 'Clock in'}
              </Text>
            </Pressable>
          </View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center' },
  modalWrap: {
    flex: 1, backgroundColor: 'rgba(10,42,29,0.55)',
    alignItems: 'center', justifyContent: 'center', padding: spacing.lg,
  },
  modalCard: {
    width: '100%', maxWidth: 360,
    borderRadius: radius.lg,
    padding: spacing.lg,
  },
  modalInput: {
    borderWidth: 1, borderRadius: radius.md,
    paddingHorizontal: spacing.sm, paddingVertical: 10,
    fontFamily: fonts.regular, fontSize: 14,
    marginBottom: spacing.sm,
  },
  modalRow: { flexDirection: 'row', marginTop: spacing.xs, gap: spacing.sm },
  modalBtn: { flex: 1, height: 44, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center' },
});