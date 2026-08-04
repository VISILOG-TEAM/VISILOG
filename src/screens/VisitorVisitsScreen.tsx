import React, { useMemo, useState } from 'react';
import { View, StyleSheet, FlatList } from 'react-native';
import {
  Screen,
  Header,
  Text,
  Card,
  Badge,
  Button,
  EmptyState,
  RescheduleModal,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtDate, fmtTime } from '../data/format';
import type { Appointment, AppointmentStatus, StatusKey } from '../types';
import { usePullToRefresh } from '../components/usePullToRefresh';

// VisitorVisitsScreen -- every booking this visitor has made, past and
// pending (VisitorHomeScreen only ever showed the single latest one).
// Visitors can also reschedule a pending visit, with a reason, same as
// Employees can on their own Appointments tab.
export default function VisitorVisitsScreen() {
  const refreshControl = usePullToRefresh();
  const { colors } = useTheme();
  const { user } = useAuth();
  const { appointments, employeeById } = useData();
  const [rescheduling, setRescheduling] = useState<Appointment | null>(null);

  const mine = useMemo(
    () =>
      appointments
        .filter((a) => a.bookedByEmail === user!.email)
        .sort((a, b) => new Date(b.scheduledAt).getTime() - new Date(a.scheduledAt).getTime()),
    [appointments, user],
  );

  const badgeStatus = (status: AppointmentStatus): StatusKey =>
    status === 'admitted' ? 'success' : status === 'rejected' ? 'rejected' : 'pending';

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header title="Your visits" subtitle="Past & pending appointments" />
      </View>

      <FlatList
        refreshControl={refreshControl}
        data={mine}
        keyExtractor={(a) => a.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="calendar-outline"
            title="No visits yet"
            message="Book an appointment from the Book tab to see it here."
          />
        }
        renderItem={({ item }) => {
          const host = employeeById(item.hostId);
          return (
            <Card style={{ marginHorizontal: spacing.md }}>
              <View style={styles.rowTop}>
                <Text variant="bodySemibold">{fmtDate(item.scheduledAt)}</Text>
                <Badge label={item.status} status={badgeStatus(item.status)} size="sm" />
              </View>
              <Text variant="caption" color={colors.textSecondary}>
                {item.purpose} - Host: {host?.name || 'Unassigned'}
              </Text>
              <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
                {fmtTime(item.scheduledAt)} - Code {item.nfcCode || 'pending approval'}
              </Text>
              {item.rescheduleReason ? (
                <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
                  Rescheduled: {item.rescheduleReason}
                </Text>
              ) : null}
              {item.rejectReason ? (
                <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
                  Reason: {item.rejectReason}
                </Text>
              ) : null}
              {item.status !== 'rejected' && (
                <Button
                  label="Reschedule"
                  variant="secondary"
                  icon="calendar-outline"
                  onPress={() => setRescheduling(item)}
                  style={{ marginTop: spacing.sm }}
                />
              )}
            </Card>
          );
        }}
      />

      <RescheduleModal
        appointment={rescheduling}
        visible={!!rescheduling}
        onClose={() => setRescheduling(null)}
      />
    </Screen>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  rowTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
});
