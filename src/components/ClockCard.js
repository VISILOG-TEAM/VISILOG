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
import { isAtOffice } from '../data/locationCheck';

// ClockCard — the personal "on the clock" card shared by every role's
// home screen. Backed by DataContext's shared clock ledger (not local
// state) so the Manager's Clock-ins screen sees the same records.
//
// Clocking IN requires: (1) a best-effort WiFi check, (2) a best-effort
// GPS geofence check against the signed-in org's office location — see
// src/data/wifiCheck.js and src/data/locationCheck.js — and (3) not
// having already clocked in once today (one in/out cycle per day).
// Clocking OUT never blocks.
export default function ClockCard() {
  const { user, organization } = useAuth();
  const { clockRecords, clockIn, clockOut, isClockedIn, hasClockedInToday } = useData();
  const [checking, setChecking] = useState(false);

  const employeeId = user?.employeeId || user?.id;
  const clockedIn = isClockedIn(employeeId);
  const lastRecord = clockRecords.find((c) => c.employeeId === employeeId);
  const doneForToday = !clockedIn && hasClockedInToday(employeeId);

  const toggle = async () => {
    if (!clockedIn) {
      if (hasClockedInToday(employeeId)) {
        Alert.alert('Already clocked in today', 'You can only clock in once per day — see you tomorrow.');
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
      try {
        const r = await clockIn(employeeId, user.name);
        Alert.alert('Checked in', `Welcome. Clocked in at ${fmtTime(r.timestamp)}.`);
      } catch (err) {
        Alert.alert('Could not clock in', err.message);
      } finally {
        setChecking(false);
      }
    } else {
      try {
        const r = await clockOut(employeeId, user.name);
        Alert.alert('Checked out', `See you next time. Clocked out at ${fmtTime(r.timestamp)}.`);
      } catch (err) {
        Alert.alert('Could not clock out', err.message);
      }
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
          ) : doneForToday ? (
            <Text variant="caption" color={colors.textMuted}>
              Done for today — see you tomorrow.
            </Text>
          ) : null}
        </View>
        <Button
          label={checking ? 'Checking…' : clockedIn ? 'Check out' : doneForToday ? 'Done for today' : 'Check in'}
          icon={clockedIn ? 'log-out-outline' : 'log-in-outline'}
          variant={clockedIn ? 'danger' : 'primary'}
          onPress={toggle}
          disabled={checking || doneForToday}
        />
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center' },
});
