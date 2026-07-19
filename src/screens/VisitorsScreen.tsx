import React, { useMemo, useState } from 'react';
import { View, FlatList, StyleSheet, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, Input, Segmented, EmptyState, Avatar,
} from '../components';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtTime, fmtDuration } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';
import type { Visitor } from '../types';

interface VisitorsScreenProps {
  navigation: RootStackNavigation;
}

type StatusFilter = 'all' | 'onsite' | 'completed';

// VisitorsScreen — the live visitor log.
// Implements the "Visitor Logs" page from the User Guide:
//   - search by name, badge number, or host
//   - status filter: All / On-site / Completed
//   - badge IDs are auto-generated (VIS-YYYY-NNN)
//   - each row links into a detail page where check-out happens
// A floating "Register" button opens the registration modal.
export default function VisitorsScreen({ navigation }: VisitorsScreenProps) {
  const { visitors, employeeById } = useData();
  const [query, setQuery] = useState('');
  const [status, setStatus] = useState<StatusFilter>('all');

  // Filter pipeline: text search across name/badge/host, then status.
  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return visitors
      .filter((v) => {
        if (status !== 'all' && v.status !== status) return false;
        if (!q) return true;
        const host = employeeById(v.hostId);
        return (
          v.fullName.toLowerCase().includes(q) ||
          v.badgeId.toLowerCase().includes(q) ||
          (host?.name || '').toLowerCase().includes(q)
        );
      })
      .sort((a, b) => new Date(b.checkInAt).getTime() - new Date(a.checkInAt).getTime());
  }, [visitors, query, status]);

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Visitors"
          subtitle="Live visitor log & check-in"
          onBackPress={() => navigation.goBack()}
          rightIcon="person-add"
          onRightPress={() => navigation.navigate('RegisterVisitor')}
        />

        <Input
          placeholder="Search name, badge or host"
          value={query}
          onChangeText={setQuery}
          icon="search"
        />

        <Segmented
          value={status}
          onChange={setStatus}
          options={[
            { label: 'All', value: 'all' },
            { label: 'On-site', value: 'onsite' },
            { label: 'Completed', value: 'completed' },
          ]}
        />
      </View>

      <FlatList
        data={filtered}
        keyExtractor={(v) => v.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="people-outline"
            title="No visitors match"
            message={
              status === 'onsite'
                ? 'No one is currently on-site. Tap the + button to register a walk-in.'
                : 'Try a different search or status filter.'
            }
            actionLabel="Register visitor"
            onAction={() => navigation.navigate('RegisterVisitor')}
          />
        }
        renderItem={({ item }) => {
          const host = employeeById(item.hostId);
          return (
            <VisitorRow
              visitor={item}
              hostName={host?.name}
              onPress={() => navigation.navigate('VisitorDetail', { visitorId: item.id })}
            />
          );
        }}
      />
    </Screen>
  );
}

// Single row inside the visitor list. Status drives the card's accent
// stripe (on the leading edge) AND a pill badge on the right.
function VisitorRow({
  visitor, hostName, onPress,
}: { visitor: Visitor; hostName?: string; onPress: () => void }) {
  const isOnsite = visitor.status === 'onsite';
  const accent = isOnsite ? 'onsite' : 'neutral';
  return (
    <Card accent={accent} padded={false} onPress={onPress} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <Avatar name={visitor.fullName} size={44} />
        <View style={styles.middle}>
          <View style={styles.titleRow}>
            <Text variant="bodySemibold" numberOfLines={1}>{visitor.fullName}</Text>
            <Badge
              label={isOnsite ? 'On-site' : 'Completed'}
              status={isOnsite ? 'onsite' : 'neutral'}
              size="sm"
            />
          </View>
          <Text variant="caption" color={colors.textSecondary} numberOfLines={1}>
            {visitor.purpose} - {hostName || 'No host'}
          </Text>
          <View style={styles.metaRow}>
            <Ionicons name="card-outline" size={12} color={colors.textMuted} />
            <Text variant="caption" color={colors.textMuted} style={{ marginLeft: 4 }}>
              {visitor.badgeId}
            </Text>
            <View style={styles.dot} />
            <Ionicons name="time-outline" size={12} color={colors.textMuted} />
            <Text variant="caption" color={colors.textMuted} style={{ marginLeft: 4 }}>
              {isOnsite
                ? `In - ${fmtTime(visitor.checkInAt)} - ${fmtDuration(visitor.checkInAt)}`
                : `${fmtTime(visitor.checkInAt)} → ${fmtTime(visitor.checkOutAt)}`}
            </Text>
          </View>
        </View>
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  row: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  middle: { flex: 1, marginLeft: spacing.sm },
  titleRow: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: 8,
  },
  metaRow: { flexDirection: 'row', alignItems: 'center', marginTop: 4 },
  dot: {
    width: 3, height: 3, borderRadius: 2,
    backgroundColor: colors.textMuted, marginHorizontal: 8,
  },
});
