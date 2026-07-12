import React, { useMemo, useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Button, Segmented, StatTile, Badge,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useData } from '../context/DataContext';
import { employeeById } from '../data/mockData';

// ReportsScreen — date-range filtered visit summary with simple charts
// drawn in plain React Native (no chart library required).
// Per spec: date range, export PDF/CSV, "chart visualisations".
export default function ReportsScreen({ navigation }) {
  const { colors: themeColors } = useTheme();
  const { visitors, calls } = useData();
  const [range, setRange] = useState('7d'); // '24h' | '7d' | '30d'

  const days = range === '24h' ? 1 : range === '7d' ? 7 : 30;

  // Slice data to the selected window.
  const { windowVisitors, windowCalls } = useMemo(() => {
    const cutoff = Date.now() - days * 24 * 60 * 60 * 1000;
    return {
      windowVisitors: visitors.filter((v) => new Date(v.checkInAt).getTime() >= cutoff),
      windowCalls: calls.filter((c) => new Date(c.timestamp).getTime() >= cutoff),
    };
  }, [visitors, calls, days]);

  // Bucket visitors per day for the bar chart. Always render `days` bars
  // (even when zero) so the axis is consistent.
  const dailyBars = useMemo(() => {
    const buckets = Array.from({ length: days }, (_, i) => ({
      label: dayLabel(days - 1 - i),
      count: 0,
    }));
    windowVisitors.forEach((v) => {
      const ago = Math.floor((Date.now() - new Date(v.checkInAt).getTime()) / 86400000);
      const idx = days - 1 - ago;
      if (idx >= 0 && idx < days) buckets[idx].count += 1;
    });
    return buckets;
  }, [windowVisitors, days]);

  const maxCount = Math.max(1, ...dailyBars.map((b) => b.count));

  // Top hosts by visitor count in the window.
  const topHosts = useMemo(() => {
    const counts = {};
    windowVisitors.forEach((v) => {
      counts[v.hostId] = (counts[v.hostId] || 0) + 1;
    });
    return Object.entries(counts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([id, count]) => ({ employee: employeeById(id), count }));
  }, [windowVisitors]);

  const avgDuration = useMemo(() => {
    const completed = windowVisitors.filter((v) => v.checkOutAt);
    if (!completed.length) return '—';
    const totalMin = completed.reduce((sum, v) => {
      return sum + (new Date(v.checkOutAt) - new Date(v.checkInAt)) / 60000;
    }, 0);
    const avg = Math.round(totalMin / completed.length);
    const h = Math.floor(avg / 60);
    const m = avg % 60;
    return h ? `${h}h ${m}m` : `${m}m`;
  }, [windowVisitors]);

  return (
    <Screen>
      <Header
        title="Reports"
        subtitle="Visit summaries & exports"
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      <Segmented
        value={range}
        onChange={setRange}
        options={[
          { label: 'Last 24h', value: '24h' },
          { label: 'Last 7 days', value: '7d' },
          { label: 'Last 30 days', value: '30d' },
        ]}
      />

      {/* Headline numbers */}
      <View style={[styles.statRow, { marginTop: spacing.md }]}>
        <StatTile icon="people" label="Total visitors" value={windowVisitors.length} tint="primary" />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="time" label="Avg. duration" value={avgDuration} tint="info" />
      </View>
      <View style={[styles.statRow, { marginTop: spacing.sm }]}>
        <StatTile icon="call" label="Calls handled" value={windowCalls.length} tint="success" />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="checkmark-done" label="Completed" value={windowVisitors.filter((v) => v.status === 'completed').length} tint="pending" />
      </View>

      {/* Daily bar chart - drawn as a row of flexed Views */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Visitors per day
      </Text>
      <Card>
        <View style={styles.chart}>
          {dailyBars.map((b, i) => {
            const h = (b.count / maxCount) * 120;
            return (
              <View key={i} style={styles.barCol}>
                <View style={styles.barTrack}>
                  <View style={[styles.bar, { height: Math.max(2, h), backgroundColor: themeColors.primary }]} />
                </View>
                <Text variant="caption" color={colors.textSecondary} style={styles.barLabel}>
                  {b.label}
                </Text>
                <Text style={styles.barValue}>{b.count}</Text>
              </View>
            );
          })}
        </View>
      </Card>

      {/* Top hosts */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Top hosts
      </Text>
      <Card>
        {topHosts.length === 0 ? (
          <Text variant="body" color={colors.textSecondary}>
            No host data in this range yet.
          </Text>
        ) : (
          topHosts.map((h, i) => (
            <View key={h.employee?.id || i} style={styles.hostRow}>
              <View style={[styles.rank, { backgroundColor: themeColors.primarySurface }]}>
                <Text style={[styles.rankNum, { color: themeColors.primary }]}>{i + 1}</Text>
              </View>
              <View style={{ flex: 1, marginLeft: spacing.sm }}>
                <Text variant="bodySemibold">{h.employee?.name || 'Unknown'}</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {h.employee?.department || ''}
                </Text>
              </View>
              <Badge label={`${h.count} visits`} status="info" size="sm" dot={false} />
            </View>
          ))
        )}
      </Card>

      {/* Exports - non-functional in the demo (would call jsPDF / ExcelJS) */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Export
      </Text>
      <Button
        label="Export as PDF"
        variant="secondary"
        icon="document-outline"
        onPress={() => Alert.alert('Demo export', 'PDF export wires up to jsPDF in production.')}
      />
      <Button
        label="Export as CSV"
        variant="secondary"
        icon="grid-outline"
        onPress={() => Alert.alert('Demo export', 'CSV export wires up to ExcelJS in production.')}
        style={{ marginTop: spacing.xs }}
      />
    </Screen>
  );
}

// "Mon", "Tue" etc. for the bar chart axis.
function dayLabel(daysAgo) {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][d.getDay()];
}

const styles = StyleSheet.create({
  statRow: { flexDirection: 'row' },
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },

  chart: { flexDirection: 'row', alignItems: 'flex-end', height: 160, gap: 4 },
  barCol: { flex: 1, alignItems: 'center' },
  barTrack: { width: '100%', height: 120, justifyContent: 'flex-end' },
  bar: {
    width: '70%', alignSelf: 'center',
    borderTopLeftRadius: 4, borderTopRightRadius: 4,
  },
  barLabel: { marginTop: 4 },
  barValue: { fontFamily: fonts.semibold, fontSize: 11, color: colors.textPrimary },

  hostRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 6 },
  rank: {
    width: 28, height: 28, borderRadius: 14,
    alignItems: 'center', justifyContent: 'center',
  },
  rankNum: { fontFamily: fonts.displayBold, fontSize: 13 },
});
