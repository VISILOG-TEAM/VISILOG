import React, { useMemo, useState } from 'react';
import { View, FlatList, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, Input, Segmented, EmptyState,
} from '../components';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtDateTime } from '../data/format';

// CallLogScreen — every incoming / outgoing / missed call.
// Fields per the User Guide: date+time, caller name+phone, host, duration, purpose.
export default function CallLogScreen({ navigation }) {
  const { calls, employeeById } = useData();
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState('all');

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return calls
      .filter((c) => {
        if (filter !== 'all' && c.callType.toLowerCase() !== filter) return false;
        if (!q) return true;
        const host = employeeById(c.hostId);
        return (
          c.callerName.toLowerCase().includes(q) ||
          c.callerPhone.includes(q) ||
          (host?.name || '').toLowerCase().includes(q)
        );
      })
      .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
  }, [calls, query, filter, employeeById]);

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Call log"
          subtitle={`${calls.length} calls recorded`}
          rightIcon="add"
          onRightPress={() => navigation.navigate('LogCall')}
        />
        <Input
          placeholder="Search caller, phone or host"
          value={query}
          onChangeText={setQuery}
          icon="search"
        />
        <Segmented
          value={filter}
          onChange={setFilter}
          options={[
            { label: 'All', value: 'all' },
            { label: 'Incoming', value: 'incoming' },
            { label: 'Outgoing', value: 'outgoing' },
            { label: 'Missed', value: 'missed' },
          ]}
        />
      </View>

      <FlatList
        data={filtered}
        keyExtractor={(c) => c.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="call-outline"
            title="No calls match"
            message="Try a different search, or log a new call from the + button."
            actionLabel="Log a call"
            onAction={() => navigation.navigate('LogCall')}
          />
        }
        renderItem={({ item }) => <CallRow call={item} />}
      />
    </Screen>
  );
}

function CallRow({ call }) {
  const { employeeById } = useData();
  const host = employeeById(call.hostId);
  const icon =
    call.callType === 'Incoming' ? 'call' :
    call.callType === 'Outgoing' ? 'call-outline' :
    'call-sharp';
  const badgeStatus =
    call.callType === 'Missed' ? 'rejected' :
    call.callType === 'Incoming' ? 'success' :
    'info';

  return (
    <Card padded={false} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <View style={[styles.iconWrap, { backgroundColor: colors.status[badgeStatus].bg }]}>
          <Ionicons
            name={icon}
            size={18}
            color={colors.status[badgeStatus].solid}
          />
        </View>
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <View style={styles.rowTop}>
            <Text variant="bodySemibold" numberOfLines={1}>{call.callerName}</Text>
            <Badge label={call.callType} status={badgeStatus} size="sm" dot={false} />
          </View>
          <Text variant="caption" color={colors.textSecondary} numberOfLines={1}>
            {call.callerPhone} - Host: {host?.name || 'Unassigned'}
          </Text>
          <Text variant="caption" color={colors.textMuted}>
            {fmtDateTime(call.timestamp)} - {call.durationMinutes}m - {call.purpose}
          </Text>
          {call.notes ? (
            <Text variant="caption" color={colors.textSecondary} style={{ marginTop: 2 }} numberOfLines={2}>
              "{call.notes}"
            </Text>
          ) : null}
        </View>
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  row: { flexDirection: 'row', alignItems: 'flex-start', padding: spacing.md },
  iconWrap: {
    width: 40, height: 40, borderRadius: 12,
    alignItems: 'center', justifyContent: 'center',
  },
  rowTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: 8 },
});
