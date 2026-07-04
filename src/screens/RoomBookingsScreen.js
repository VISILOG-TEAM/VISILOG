import React from 'react';
import { View, StyleSheet, FlatList } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, EmptyState,
} from '../components';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { employeeById, roomById } from '../data/mockData';
import { fmtTime, fmtDate } from '../data/format';

// RoomBookingsScreen — meeting room reservations (NFC-gated in 2.0).
export default function RoomBookingsScreen({ navigation }) {
  const { roomBookings } = useData();

  const sorted = [...roomBookings].sort(
    (a, b) => new Date(a.startTime) - new Date(b.startTime)
  );

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Room bookings"
          subtitle="Meeting rooms & NFC access"
          rightIcon="close"
          onRightPress={() => navigation.goBack()}
        />
      </View>

      <FlatList
        data={sorted}
        keyExtractor={(b) => b.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="calendar-outline"
            title="No bookings"
            message="Schedule a meeting room to grant NFC access for the time window."
          />
        }
        renderItem={({ item }) => <BookingCard booking={item} />}
      />
    </Screen>
  );
}

function BookingCard({ booking }) {
  const room = roomById(booking.roomId);
  const organiser = employeeById(booking.organiserId);
  const now = Date.now();
  const isLive = new Date(booking.startTime).getTime() <= now &&
                 new Date(booking.endTime).getTime() > now;
  return (
    <Card accent={isLive ? 'onsite' : 'info'} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <View style={styles.chip}>
          <Ionicons name="business" size={20} color={colors.primary} />
        </View>
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold">{room?.name || 'Unknown room'}</Text>
          <Text variant="caption" color={colors.textSecondary}>
            {room?.floor} - Capacity {room?.capacity}
          </Text>
        </View>
        {isLive ? <Badge label="Live" status="onsite" size="sm" /> : null}
      </View>

      <Text variant="body" style={{ marginTop: spacing.sm }}>
        {booking.title}
      </Text>

      <View style={styles.metaRow}>
        <Ionicons name="time-outline" size={14} color={colors.textMuted} />
        <Text variant="caption" color={colors.textSecondary} style={{ marginLeft: 6 }}>
          {fmtDate(booking.startTime)} - {fmtTime(booking.startTime)} → {fmtTime(booking.endTime)}
        </Text>
      </View>
      <View style={styles.metaRow}>
        <Ionicons name="person-outline" size={14} color={colors.textMuted} />
        <Text variant="caption" color={colors.textSecondary} style={{ marginLeft: 6 }}>
          Organiser: {organiser?.name || '—'}
        </Text>
      </View>
      <View style={styles.metaRow}>
        <Ionicons name="people-outline" size={14} color={colors.textMuted} />
        <Text variant="caption" color={colors.textSecondary} style={{ marginLeft: 6 }}>
          {booking.participantIds.length} participants - NFC granted
        </Text>
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.md, paddingBottom: spacing.huge },
  row: { flexDirection: 'row', alignItems: 'center' },
  chip: {
    width: 44, height: 44, borderRadius: 12,
    backgroundColor: colors.primarySurface,
    alignItems: 'center', justifyContent: 'center',
  },
  metaRow: { flexDirection: 'row', alignItems: 'center', marginTop: 6 },
});
