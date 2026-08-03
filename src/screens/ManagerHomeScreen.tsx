import React, { useCallback, useState } from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Badge, StatTile, Avatar, ClockCard } from '../components';
import ManagerTour from '../components/ManagerTour';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';

interface ManagerHomeScreenProps {
  navigation: RootStackNavigation;
}

// Manager dashboard: organisation-wide insight, plus the same
// clock-in/out card every other role gets -- an Administrator is staff
// too, and shows up on their own Clock-ins screen like everyone else.
export default function ManagerHomeScreen({ navigation }: ManagerHomeScreenProps) {
  const { colors, setOrgTheme } = useTheme();
  const { user, logout, listPendingApprovals } = useAuth();
  const { stats, visitors, calls, employees, employeeById, unreadNotificationCount, refreshAll } =
    useData();
  const onLogout = () => {
    logout();
    setOrgTheme(null);
  };
  const [refreshing, setRefreshing] = useState(false);
  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshAll();
    } finally {
      setRefreshing(false);
    }
  };

  // Sign-ups waiting on this Manager's approval (see PendingApprovalsScreen).
  // Refetched on focus so approving a batch and coming back updates the
  // count without a manual pull-to-refresh.
  const [pendingApprovalCount, setPendingApprovalCount] = useState(0);
  useFocusEffect(
    useCallback(() => {
      listPendingApprovals().then((result) => {
        if (result.ok) setPendingApprovalCount(result.approvals.length);
      });
    }, [listPendingApprovals]),
  );

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
    <Screen refreshing={refreshing} onRefresh={onRefresh}>
      <Header
        eyebrow="Manager view"
        title="Overview"
        subtitle="Insight & attendance across the organisation"
        rightActions={[
          {
            icon: 'notifications-outline',
            onPress: () => navigation.navigate('Notifications'),
            badge: unreadNotificationCount,
          },
          { icon: 'log-out-outline', onPress: onLogout, danger: true },
        ]}
      />

      <ClockCard />

      {pendingApprovalCount > 0 ? (
        <Pressable onPress={() => navigation.navigate('PendingApprovals')}>
          <Card accent="pending" style={styles.approvalCard}>
            <View style={[styles.approvalIcon, { backgroundColor: colors.status.pending.bg }]}>
              <Ionicons name="hourglass-outline" size={20} color={colors.status.pending.fg} />
            </View>
            <View style={{ flex: 1, marginLeft: spacing.sm }}>
              <Text variant="bodySemibold">Pending approvals</Text>
              <Text variant="caption" color={colors.textSecondary}>
                {pendingApprovalCount} sign-up{pendingApprovalCount === 1 ? '' : 's'} waiting on you
              </Text>
            </View>
            <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
          </Card>
        </Pressable>
      ) : null}

      <View style={{ flexDirection: 'row', marginTop: spacing.md }}>
        <StatTile icon="people" tint="primary" label="Visitors today" value={stats.visitorsToday} />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="checkmark-circle" tint="success" label="On-site" value={stats.onsite} />
      </View>
      <View style={{ flexDirection: 'row', marginTop: spacing.sm }}>
        <StatTile icon="call" tint="info" label="Calls today" value={stats.callsToday} />
        <View style={{ width: spacing.sm }} />
        <StatTile
          icon="calendar"
          tint="pending"
          label="This month"
          value={stats.visitorsThisMonth}
        />
      </View>

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Top hosts
      </Text>
      <Card>
        {topHosts.map((h, i) => (
          <View key={h.employee?.id || i} style={styles.row}>
            <Text variant="bodySemibold" style={{ width: 24 }}>
              {i + 1}
            </Text>
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

      <View style={styles.sectionHeader}>
        <Text variant="eyebrow" color={colors.textMuted}>
          Currently on-site
        </Text>
        <Pressable onPress={() => navigation.navigate('Visitors')}>
          <Text variant="label" color={colors.primary}>
            View all visitors
          </Text>
        </Pressable>
      </View>
      <Card>
        {visitors
          .filter((v) => v.status === 'onsite')
          .map((v) => (
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
      {/* First-run orientation, shown once per Administrator. Lives
          here rather than in the navigator so it appears over the
          screen a new manager actually lands on. */}
      <ManagerTour />
    </Screen>
  );
}

const styles = StyleSheet.create({
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: 8 },
  approvalCard: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing.md,
  },
  approvalIcon: {
    width: 40,
    height: 40,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: spacing.xl,
    marginBottom: spacing.sm,
  },
});
