import React, { useMemo, useState } from 'react';
import { View, FlatList, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, Button, Segmented, EmptyState, Avatar,
} from '../components';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { employeeById } from '../data/mockData';
import { fmtTime, fmtDate } from '../data/format';

// AppointmentsScreen
// Pre-scheduled visits with three statuses from the spec:
//   - Pending  (needs receptionist action)
//   - Admitted (already approved + checked in)
//   - Rejected (denied entry)
// Each pending row has one-tap Admit / Reject buttons.
export default function AppointmentsScreen({ navigation }) {
  const { appointments, updateAppointmentStatus, admitAppointment } = useData();
  const [filter, setFilter] = useState('pending');

  const filtered = useMemo(
    () => appointments
      .filter((a) => filter === 'all' || a.status === filter)
      .sort((a, b) => new Date(a.scheduledAt) - new Date(b.scheduledAt)),
    [appointments, filter]
  );

  const onAdmit = (appt) => {
    Alert.alert(
      'Admit visitor?',
      `${appt.visitorName} will be registered and checked in.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Admit',
          onPress: () => {
            const v = admitAppointment(appt);
            Alert.alert('Admitted', `${v.fullName} - ${v.badgeId}`);
          },
        },
      ]
    );
  };

  const onReject = (appt) => {
    Alert.alert(
      'Reject visitor?',
      `${appt.visitorName} will be denied entry.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Reject',
          style: 'destructive',
          onPress: () => updateAppointmentStatus(appt.id, 'rejected'),
        },
      ]
    );
  };

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Appointments"
          subtitle="Pre-booked visits & approvals"
        />
        <Segmented
          value={filter}
          onChange={setFilter}
          options={[
            { label: 'Pending', value: 'pending' },
            { label: 'Admitted', value: 'admitted' },
            { label: 'Rejected', value: 'rejected' },
            { label: 'All', value: 'all' },
          ]}
        />
      </View>

      <FlatList
        data={filtered}
        keyExtractor={(a) => a.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="calendar-outline"
            title="No appointments here"
            message={
              filter === 'pending'
                ? 'You\u2019re all caught up - no visitors waiting for approval.'
                : 'Try a different filter to see appointments in other states.'
            }
          />
        }
        renderItem={({ item }) => (
          <AppointmentRow
            appointment={item}
            onAdmit={() => onAdmit(item)}
            onReject={() => onReject(item)}
          />
        )}
      />
    </Screen>
  );
}

function AppointmentRow({ appointment, onAdmit, onReject }) {
  const host = employeeById(appointment.hostId);
  const accent =
    appointment.status === 'admitted' ? 'success' :
    appointment.status === 'rejected' ? 'rejected' :
    'pending';
  const badgeStatus =
    appointment.status === 'admitted' ? 'success' :
    appointment.status === 'rejected' ? 'rejected' :
    'pending';

  return (
    <Card accent={accent} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.headRow}>
        <Avatar name={appointment.visitorName} size={44} />
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold">{appointment.visitorName}</Text>
          <Text variant="caption" color={colors.textSecondary}>
            {appointment.visitorCompany || 'Visitor'}
          </Text>
        </View>
        <Badge label={appointment.status} status={badgeStatus} size="sm" />
      </View>

      <View style={styles.metaList}>
        <MetaRow icon="people-outline" text={`Host: ${host?.name || 'Unassigned'}`} />
        <MetaRow icon="briefcase-outline" text={appointment.purpose} />
        <MetaRow
          icon="time-outline"
          text={`${fmtDate(appointment.scheduledAt)} - ${fmtTime(appointment.scheduledAt)}`}
        />
      </View>

      {appointment.status === 'pending' && (
        <View style={styles.actionRow}>
          <Button
            label="Reject"
            variant="secondary"
            icon="close-circle-outline"
            onPress={onReject}
            style={{ flex: 1, marginRight: spacing.xs }}
          />
          <Button
            label="Admit"
            icon="checkmark-circle-outline"
            onPress={onAdmit}
            style={{ flex: 1, marginLeft: spacing.xs }}
          />
        </View>
      )}
    </Card>
  );
}

function MetaRow({ icon, text }) {
  return (
    <View style={styles.metaRow}>
      <Ionicons name={icon} size={14} color={colors.textMuted} />
      <Text variant="caption" color={colors.textSecondary} style={{ marginLeft: 6 }}>
        {text}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  headRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.sm },
  metaList: { gap: 6, marginBottom: spacing.sm },
  metaRow: { flexDirection: 'row', alignItems: 'center' },
  actionRow: { flexDirection: 'row', marginTop: spacing.xs },
});
