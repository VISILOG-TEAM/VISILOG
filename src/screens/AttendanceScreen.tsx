import React from 'react';
import { View, StyleSheet, FlatList } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, EmptyState, Avatar, StatTile,
} from '../components';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtTime, fmtRelative } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';
import type { ClockRecord, ClockType, Employee } from '../types';

interface AttendanceScreenProps {
  navigation: RootStackNavigation;
}

// AttendanceScreen — the clock-in/out ledger, presented as a tap log.
// (There's no separate NFC-tap-log concept in the real backend — this
// reads the same shared clockRecords ledger as the Employee/Receptionist
// "on the clock" cards and ManagerClockInsScreen.)
export default function AttendanceScreen({ navigation }: AttendanceScreenProps) {
  const { clockRecords, employeeById } = useData();

  const sorted = [...clockRecords].sort(
    (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
  );

  // Stat: how many distinct employees are currently signed in (based on
  // their last record of the day being 'in').
  const onsiteCount = (() => {
    const last: Record<string, ClockType> = {};
    sorted.forEach((t) => {
      if (!last[t.employeeId]) last[t.employeeId] = t.type;
    });
    return Object.values(last).filter((t) => t === 'in').length;
  })();

  const lateCount = sorted.filter((t) => {
    if (t.type !== 'in') return false;
    const d = new Date(t.timestamp);
    return d.getHours() > 8 || (d.getHours() === 8 && d.getMinutes() > 30);
  }).length;

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Attendance"
          subtitle="Clock-in/out log & punctuality"
          rightIcon="close"
          onRightPress={() => navigation.goBack()}
        />
        <View style={{ flexDirection: 'row' }}>
          <StatTile icon="people" tint="primary"
            label="Employees on-site" value={onsiteCount} />
          <View style={{ width: spacing.sm }} />
          <StatTile icon="alarm" tint="pending"
            label="Late arrivals" value={lateCount} />
        </View>
      </View>

      <FlatList
        data={sorted}
        keyExtractor={(t) => t.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.xs }} />}
        ListEmptyComponent={
          <EmptyState
            icon="card-outline"
            title="No clock records yet"
            message="Clock-in/out activity will appear here as it happens."
          />
        }
        renderItem={({ item }) => (
          <TapRow tap={item} employee={employeeById(item.employeeId)} />
        )}
      />
    </Screen>
  );
}

function TapRow({ tap, employee }: { tap: ClockRecord; employee?: Employee }) {
  const isIn = tap.type === 'in';
  return (
    <Card padded={false} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <Avatar name={employee?.name || 'Unknown'} size={40} />
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold" numberOfLines={1}>
            {employee?.name || 'Unknown employee'}
          </Text>
          <Text variant="caption" color={colors.textSecondary}>
            {employee?.department || ''}
          </Text>
        </View>
        <View style={{ alignItems: 'flex-end' }}>
          <Badge label={isIn ? 'Tap in' : 'Tap out'} status={isIn ? 'success' : 'neutral'} size="sm" />
          <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
            {fmtTime(tap.timestamp)} - {fmtRelative(tap.timestamp)}
          </Text>
        </View>
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.md, paddingBottom: spacing.huge },
  row: { flexDirection: 'row', alignItems: 'center', padding: spacing.sm },
});
