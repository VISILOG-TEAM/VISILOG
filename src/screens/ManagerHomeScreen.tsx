import React from 'react';
import { View, StyleSheet } from 'react-native';
import {
  Screen, Header, Text, Card, Badge, StatTile, Avatar, ClockCard,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime } from '../data/format';

// Manager dashboard: organisation-wide insight, plus the same
// clock-in/out card every other role gets — an Administrator is staff
// too, and shows up on their own Clock-ins screen like everyone else.
export default function ManagerHomeScreen() {
  const { setOrgTheme } = useTheme();
  const { user, logout } = useAuth();
  const { stats, visitors, calls, employees, employeeById } = useData();
  const onLogout = () => { logout(); setOrgTheme(null); };

  // Top hosts (employees with the most visitors).
  const hostCounts: Record<string, number> = {};
  visitors.forEach((v) => {
    hostCounts[v.hostId] = (hostCounts[v.hostId] || 0) + 1;
  });
  const topHosts = Object.entries(hostCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([id, count]) => ({ employee: employeeById(id), count }));

  return (
    <Screen>
      <Header
        eyebrow="Manager view"
        title="Overview"
        subtitle="Insight & attendance across the organisation"
        rightIcon="log-out-outline"
        onRightPress={onLogout}
      />

      <ClockCard />

      <View style={{ flexDirection: 'row', marginTop: spacing.md }}>
        <StatTile icon="people" tint="primary" label="Visitors today" value={stats.visitorsToday} />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="checkmark-circle" tint="success" label="On-site" value={stats.onsite} />
      </View>
      <View style={{ flexDirection: 'row', marginTop: spacing.sm }}>
        <StatTile icon="call" tint="info" label="Calls today" value={stats.callsToday} />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="calendar" tint="pending" label="This month" value={stats.visitorsThisMonth} />
      </View>

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Top hosts
      </Text>
      <Card>
        {topHosts.map((h, i) => (
          <View key={h.employee?.id || i} style={styles.row}>
            <Text variant="bodySemibold" style={{ width: 24 }}>{i + 1}</Text>
            <Avatar name={h.employee?.name || '?'} size={36} />
            <View style={{ flex: 1, marginLeft: spacing.sm }}>
              <Text variant="bodySemibold">{h.employee?.name || 'Unknown'}</Text>
              <Text variant="caption" color={colors.textSecondary}>
                {h.employee?.department}
              </Text>
            </View>
            <Badge label={`${h.count} visits`} status="info" size="sm" dot={false} />
          </View>
        ))}
      </Card>

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Currently on-site
      </Text>
      <Card>
        {visitors.filter((v) => v.status === 'onsite').map((v) => (
          <View key={v.id} style={styles.row}>
            <Avatar name={v.fullName} size={36} />
            <View style={{ flex: 1, marginLeft: spacing.sm }}>
              <Text variant="bodySemibold">{v.fullName}</Text>
              <Text variant="caption" color={colors.textSecondary}>
                {employeeById(v.hostId)?.name} - {fmtTime(v.checkInAt)}
              </Text>
            </View>
          </View>
        ))}
      </Card>
    </Screen>
  );
}

const styles = StyleSheet.create({
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: 8 },
});