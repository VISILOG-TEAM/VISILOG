import React from 'react';
import { View, StyleSheet, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, StatTile, ListItem, ClockCard, OrgLogo,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';
import type { IoniconName } from '../types';

interface DashboardScreenProps {
  navigation: RootStackNavigation;
}

// DashboardScreen — the receptionist's landing page.
// Implements the four headline stats from the VisiLog User Guide:
//   1. Visitors Today
//   2. Currently Checked-In
//   3. Calls Today
//   4. Visitors This Month
// Plus pending appointment approvals and a Recent Visitor Logs preview.
export default function DashboardScreen({ navigation }: DashboardScreenProps) {
  const { colors: themeColors } = useTheme();
  const { user } = useAuth();
  const { stats, visitors, appointments, employeeById, unreadNotificationCount } = useData();

  // Personalise the greeting by time of day.
  const greeting = (() => {
    const h = new Date().getHours();
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  })();

  // Show the 5 most recent visitor records, newest first.
  const recent = [...visitors]
    .sort((a, b) => new Date(b.checkInAt).getTime() - new Date(a.checkInAt).getTime())
    .slice(0, 5);

  const pending = appointments.filter((a) => a.status === 'pending');

  return (
    <Screen>
      <OrgLogo />
      <Header
        eyebrow="VisiLog · Reception"
        title={`${greeting},`}
        subtitle={`${user?.name?.split(' ')[0] || 'there'} · Front desk`}
        rightIcon="notifications-outline"
        onRightPress={() => navigation.navigate('Notifications')}
        badge={unreadNotificationCount}
      />

      <ClockCard />

      {/* Four headline stats — rendered as a 2x2 grid */}
      <View style={[styles.statsRow, { marginTop: spacing.md }]}>
        <StatTile icon="people" tint="primary" label="Visitors today" value={stats.visitorsToday} />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="checkmark-circle" tint="success" label="Currently on-site" value={stats.onsite} />
      </View>
      <View style={[styles.statsRow, { marginTop: spacing.sm }]}>
        <StatTile icon="call" tint="info" label="Calls today" value={stats.callsToday} />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="calendar" tint="pending" label="Visitors this month" value={stats.visitorsThisMonth} />
      </View>

      {/* Pending approvals call-out - only shown when there are some */}
      {pending.length > 0 && (
        <Pressable
          onPress={() => navigation.navigate('Appointments')}
          style={({ pressed }) => [styles.alert, pressed && { opacity: 0.9 }]}
        >
          <View style={styles.alertIcon}>
            <Ionicons name="time-outline" size={18} color={colors.status.pending.solid} />
          </View>
          <View style={{ flex: 1 }}>
            <Text variant="bodySemibold" color={themeColors.brand}>
              {pending.length} appointment{pending.length === 1 ? '' : 's'} need your review
            </Text>
            <Text variant="caption" color={colors.textSecondary}>
              Tap to admit or reject pending visitors.
            </Text>
          </View>
          <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
        </Pressable>
      )}

      {/* Quick actions — Visitors, Directory, NFC lookup/cards & Call
          log all live here now instead of as their own tabs/More menu,
          since the bottom bar shrank to 4 tabs. */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.sectionEyebrow}>
        Quick actions
      </Text>
      <View style={styles.quickGrid}>
        <QuickAction
          icon="person-add" label="Register visitor"
          onPress={() => navigation.navigate('RegisterVisitor')}
        />
        <QuickAction
          icon="people-outline" label="Visitors"
          onPress={() => navigation.navigate('Visitors')}
        />
        <QuickAction
          icon="book-outline" label="Directory"
          onPress={() => navigation.navigate('Directory')}
        />
        <QuickAction
          icon="call-outline" label="Call log"
          onPress={() => navigation.navigate('CallLog')}
        />
        <QuickAction
          icon="scan-outline" label="NFC lookup"
          onPress={() => navigation.navigate('NFCLookup')}
        />
        <QuickAction
          icon="card-outline" label="NFC cards"
          onPress={() => navigation.navigate('NFCCards')}
        />
        <QuickAction
          icon="finger-print-outline" label="Attendance"
          onPress={() => navigation.navigate('Attendance')}
        />
        <QuickAction
          icon="document-text-outline" label="Reports"
          onPress={() => navigation.navigate('Reports')}
        />
      </View>

      {/* Recent visitor logs - preview that links to the full Visitors screen */}
      <View style={styles.sectionHeader}>
        <Text variant="h2">Recent visitor logs</Text>
        <Pressable onPress={() => navigation.navigate('Visitors')}>
          <Text variant="label" color={themeColors.primary}>
            View all
          </Text>
        </Pressable>
      </View>

      <Card padded={false}>
        {recent.map((v, i) => {
          const host = employeeById(v.hostId);
          return (
            <View key={v.id}>
              <ListItem
                avatarName={v.fullName}
                title={v.fullName}
                subtitle={`${v.purpose} - ${host?.name || 'No host'}`}
                meta={fmtTime(v.checkInAt)}
                right={
                  <Badge
                    label={v.status === 'onsite' ? 'On-site' : 'Completed'}
                    status={v.status === 'onsite' ? 'onsite' : 'neutral'}
                    size="sm"
                  />
                }
                chevron
                onPress={() => navigation.navigate('VisitorDetail', { visitorId: v.id })}
              />
              {i < recent.length - 1 ? <View style={styles.sep} /> : null}
            </View>
          );
        })}
      </Card>
    </Screen>
  );
}

// Local quick-action button - vertical icon-over-label tile.
function QuickAction({
  icon, label, onPress,
}: { icon: IoniconName; label: string; onPress: () => void }) {
  const { colors: themeColors } = useTheme();
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.qa, pressed && { opacity: 0.85 }]}>
      <View style={[styles.qaIcon, { backgroundColor: themeColors.primarySurface }]}>
        <Ionicons name={icon} size={22} color={themeColors.primary} />
      </View>
      <Text variant="caption" color={colors.textPrimary} align="center" numberOfLines={2}>
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  statsRow: { flexDirection: 'row' },

  alert: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.status.pending.bg,
    borderRadius: radius.lg,
    padding: spacing.md,
    marginTop: spacing.md,
  },
  alertIcon: {
    width: 32, height: 32, borderRadius: 16,
    backgroundColor: '#FFFFFF',
    alignItems: 'center', justifyContent: 'center',
    marginRight: spacing.sm,
  },

  sectionEyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  quickGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.xs },
  qa: {
    width: '31%',
    backgroundColor: colors.surface,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    padding: spacing.sm,
    alignItems: 'center',
    minHeight: 84,
  },
  qaIcon: {
    width: 36, height: 36, borderRadius: 12,
    alignItems: 'center', justifyContent: 'center',
    marginBottom: 6,
  },

  sectionHeader: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-end',
    marginTop: spacing.xl, marginBottom: spacing.sm,
  },
  sep: { height: 1, backgroundColor: colors.border, marginLeft: spacing.md + 40 + spacing.sm },
});
