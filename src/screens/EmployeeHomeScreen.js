import React, { useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Button, Badge, Avatar, StatTile,
} from '../components';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime } from '../data/format';

// Employee dashboard: check in/out for work, accept/decline visitors
// who picked them as host, view incoming calls, see their NFC card.
export default function EmployeeHomeScreen() {
  const { user, logout } = useAuth();
  const { appointments, calls, updateAppointmentStatus, admitAppointment } = useData();

  // Local work check-in/out state. In production this would call
  // an /attendance endpoint on the backend.
  const [workCheckedIn, setWorkCheckedIn] = useState(false);
  const [checkInTime, setCheckInTime] = useState(null);

  // Visitor requests that picked any employee as host (demo — in production
  // we'd match by user.id == hostId).
  const myPending = appointments.filter((a) => a.status === 'pending');
  const myCalls = calls.slice(0, 3);

  const toggleWork = () => {
    if (workCheckedIn) {
      Alert.alert('Checked out', `You worked from ${fmtTime(checkInTime)} to ${fmtTime(new Date().toISOString())}.`);
      setWorkCheckedIn(false);
      setCheckInTime(null);
    } else {
      const now = new Date().toISOString();
      setWorkCheckedIn(true);
      setCheckInTime(now);
      Alert.alert('Checked in', `Welcome. Check-in time: ${fmtTime(now)}.`);
    }
  };

  return (
    <Screen>
      <Header
        eyebrow="Employee dashboard"
        title={`Hi, ${user.name?.split(' ')[0]}`}
        subtitle={user.email}
        rightIcon="log-out-outline"
        onRightPress={() => logout()}
      />

      {/* Work status */}
      <Card accent={workCheckedIn ? 'onsite' : 'neutral'}>
        <View style={styles.workRow}>
          <View style={{ flex: 1 }}>
            <Text variant="caption" color={colors.textSecondary}>Work status</Text>
            <Text variant="h2">{workCheckedIn ? 'On the clock' : 'Off the clock'}</Text>
            {workCheckedIn ? (
              <Text variant="caption" color={colors.textMuted}>
                Since {fmtTime(checkInTime)}
              </Text>
            ) : null}
          </View>
          <Button
            label={workCheckedIn ? 'Check out' : 'Check in'}
            icon={workCheckedIn ? 'log-out-outline' : 'log-in-outline'}
            variant={workCheckedIn ? 'danger' : 'primary'}
            onPress={toggleWork}
          />
        </View>
      </Card>

      {/* Stats */}
      <View style={{ flexDirection: 'row', marginTop: spacing.md }}>
        <StatTile icon="people" tint="primary"
          label="Pending visitors" value={myPending.length} />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="call" tint="info"
          label="Recent calls" value={myCalls.length} />
      </View>

      {/* Pending visitor requests */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Visitors waiting for you
      </Text>
      {myPending.length === 0 ? (
        <Card>
          <Text variant="body" color={colors.textSecondary}>
            No visitor requests at the moment.
          </Text>
        </Card>
      ) : (
        myPending.map((a) => (
          <Card key={a.id} style={{ marginBottom: spacing.sm }}>
            <View style={styles.requestRow}>
              <Avatar name={a.visitorName} size={40} />
              <View style={{ flex: 1, marginLeft: spacing.sm }}>
                <Text variant="bodySemibold">{a.visitorName}</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {a.purpose} - Code {a.nfcCode}
                </Text>
              </View>
            </View>
            <View style={{ flexDirection: 'row', marginTop: spacing.sm }}>
              <Button label="Decline" variant="secondary"
                onPress={() => updateAppointmentStatus(a.id, 'rejected')}
                style={{ flex: 1, marginRight: spacing.xs }} />
              <Button label="Accept"
                onPress={() => admitAppointment(a)}
                style={{ flex: 1, marginLeft: spacing.xs }} />
            </View>
          </Card>
        ))
      )}

      {/* Calls preview */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Recent calls for you
      </Text>
      <Card>
        {myCalls.length === 0 ? (
          <Text variant="body" color={colors.textSecondary}>No recent calls.</Text>
        ) : (
          myCalls.map((c) => (
            <View key={c.id} style={styles.callRow}>
              <Ionicons name="call" size={16} color={colors.primary} />
              <Text variant="bodyMd" style={{ flex: 1, marginLeft: 8 }}>
                {c.callerName}
              </Text>
              <Text variant="caption" color={colors.textMuted}>
                {fmtTime(c.timestamp)}
              </Text>
            </View>
          ))
        )}
      </Card>
    </Screen>
  );
}

const styles = StyleSheet.create({
  workRow: { flexDirection: 'row', alignItems: 'center' },
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  requestRow: { flexDirection: 'row', alignItems: 'center' },
  callRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 6 },
});