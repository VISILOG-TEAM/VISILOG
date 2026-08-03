import React, { useCallback, useMemo } from 'react';
import { View, StyleSheet, FlatList } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Screen, Header, Text, Card, Badge, EmptyState, Avatar, StatTile } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtTime, fmtDate } from '../data/format';
import { usePullToRefresh } from '../components/usePullToRefresh';

// ManagerClockInsScreen -- every clock-in/out record, for record
// keeping. Sourced from DataContext's shared `clockRecords` ledger --
// the same one the Employee/Receptionist "on the clock" cards write
// to. That ledger is only loaded once at login though, so it won't
// pick up a *different* signed-in session's clock-ins on its own (no
// websockets/polling in this build) -- refetch on focus so re-opening
// this tab always shows what everyone else has actually done.
export default function ManagerClockInsScreen() {
  const refreshControl = usePullToRefresh();
  const { colors } = useTheme();
  const { clockRecords, refreshClockRecords } = useData();

  useFocusEffect(
    useCallback(() => {
      refreshClockRecords().catch(() => {});
    }, []),
  );

  const sorted = useMemo(
    () =>
      [...clockRecords].sort(
        (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime(),
      ),
    [clockRecords],
  );

  const onsiteCount = useMemo(() => {
    const seen = new Set<string>();
    let count = 0;
    sorted.forEach((r) => {
      if (seen.has(r.employeeId)) return;
      seen.add(r.employeeId);
      if (r.type === 'in') count += 1;
    });
    return count;
  }, [sorted]);

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header title="Clock ins" subtitle="Attendance record for every role" />
        <View style={styles.statRow}>
          <StatTile icon="people" tint="primary" label="Currently on the clock" value={onsiteCount} />
        </View>
      </View>

      <FlatList
        refreshControl={refreshControl}
        data={sorted}
        keyExtractor={(r) => r.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.xs }} />}
        ListEmptyComponent={
          <EmptyState
            icon="time-outline"
            title="No clock records yet"
            message="Clock-in/out activity from Employee and Receptionist home screens will appear here."
          />
        }
        renderItem={({ item }) => (
          <Card padded={false} style={{ marginHorizontal: spacing.md }}>
            <View style={styles.row}>
              <Avatar name={item.employeeName || 'Unknown'} size={40} />
              <View style={{ flex: 1, marginLeft: spacing.sm }}>
                <Text variant="bodySemibold" numberOfLines={1}>
                  {item.employeeName || 'Unknown'}
                </Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {fmtDate(item.timestamp)}
                </Text>
              </View>
              <View style={{ alignItems: 'flex-end' }}>
                <Badge
                  label={item.type === 'in' ? 'Clocked in' : 'Clocked out'}
                  status={item.type === 'in' ? 'success' : 'neutral'}
                  size="sm"
                />
                <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
                  {fmtTime(item.timestamp)}
                </Text>
              </View>
            </View>
          </Card>
        )}
      />
    </Screen>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: spacing.sm, gap: spacing.sm },
  // StatTile is built with `flex: 1` so several sit side-by-side in a
  // row (see DashboardScreen). Dropped straight into a column here
  // without that row wrapper, flex:1 had nothing to grow against --
  // the card collapsed to zero height and its icon chip rendered
  // outside its own bounds instead of inside a properly sized card.
  statRow: { flexDirection: 'row' },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  row: { flexDirection: 'row', alignItems: 'center', padding: spacing.sm },
});
