import React, { useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import Text from './Text';
import Card from './Card';
import Button from './Button';
import { colors } from '../theme/colors';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime } from '../data/format';
import { isOnWifi } from '../data/wifiCheck';

// ClockCard — the personal "on the clock" card shared by the
// Receptionist and Employee home screens. Backed by DataContext's
// shared clock ledger (not local state) so the Manager's Clock-ins
// screen sees the same records. Clocking IN requires a best-effort
// WiFi check (see src/data/wifiCheck.js) — clocking OUT never blocks.
export default function ClockCard() {
  const { user } = useAuth();
  const { clockRecords, clockIn, clockOut, isClockedIn } = useData();
  const [checking, setChecking] = useState(false);

  const employeeId = user?.employeeId || user?.id;
  const clockedIn = isClockedIn(employeeId);
  const lastRecord = clockRecords.find((c) => c.employeeId === employeeId);

  const toggle = async () => {
    if (!clockedIn) {
      setChecking(true);
      const onWifi = await isOnWifi();
      setChecking(false);
      if (!onWifi) {
        Alert.alert('Company network required', 'Connect to the company WiFi to clock in.');
        return;
      }
      const r = clockIn(employeeId, user.name);
      Alert.alert('Checked in', `Welcome. Clocked in at ${fmtTime(r.timestamp)}.`);
    } else {
      const r = clockOut(employeeId, user.name);
      Alert.alert('Checked out', `See you next time. Clocked out at ${fmtTime(r.timestamp)}.`);
    }
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
          ) : null}
        </View>
        <Button
          label={checking ? 'Checking…' : clockedIn ? 'Check out' : 'Check in'}
          icon={clockedIn ? 'log-out-outline' : 'log-in-outline'}
          variant={clockedIn ? 'danger' : 'primary'}
          onPress={toggle}
          disabled={checking}
        />
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center' },
});
