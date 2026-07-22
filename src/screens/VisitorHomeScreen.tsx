import React from 'react';
import { View, StyleSheet, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Text, Card, Badge, Avatar, CompanyMapSection,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtDate, fmtTime } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';
import type { IoniconName } from '../types';

interface VisitorHomeScreenProps {
  navigation: RootStackNavigation;
}

// VisitorHomeScreen — the visitor's tab-bar landing page. The booking
// form itself now lives on its own "Book" tab (VisitorBookScreen); this
// screen is a dashboard: profile + notifications up top, a full-bleed
// virtual pass card in the org's own brand colors (or a prompt to
// book, if there isn't one yet), the submitted details, a visit-status
// timeline, and the company map/tour section.
export default function VisitorHomeScreen({ navigation }: VisitorHomeScreenProps) {
  const { colors: themeColors } = useTheme();
  const { user } = useAuth();
  const { employees, appointments, unreadNotificationCount } = useData();

  const myBooking = appointments
    .filter((a) => a.bookedByEmail === user!.email)
    .sort((a, b) => new Date(b.scheduledAt).getTime() - new Date(a.scheduledAt).getTime())[0];

  const host = myBooking ? employees.find((e) => e.id === myBooking.hostId) : null;

  return (
    <Screen>
      <View style={styles.topRow}>
        <Pressable onPress={() => navigation.navigate('Settings')}>
          <Avatar name={user?.name || 'You'} size={44} />
        </Pressable>
        <Pressable
          onPress={() => navigation.navigate('Notifications')}
          style={[styles.bellBtn, { backgroundColor: themeColors.primarySurface }]}
          hitSlop={8}
        >
          <Ionicons name="notifications-outline" size={22} color={themeColors.brand} />
          {unreadNotificationCount > 0 ? (
            <View style={[styles.bellBadge, { backgroundColor: colors.status.rejected.solid }]}>
              <Text variant="caption" color="#FFFFFF" style={styles.bellBadgeText}>
                {unreadNotificationCount > 9 ? '9+' : unreadNotificationCount}
              </Text>
            </View>
          ) : null}
        </Pressable>
      </View>

      <Text style={styles.welcome}>
        {myBooking
          ? `Welcome back, ${user!.name?.split(' ')[0] || 'there'}`
          : 'Ready to book your first appointment?'}
      </Text>
      <Text variant="body" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
        {myBooking
          ? "Here's your latest visit pass."
          : 'Head to the Book tab to schedule a visit and get your NFC pass.'}
      </Text>

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Your virtual card
      </Text>
      {myBooking ? (
        <>
          {/* Full-bleed pass card in the org's own brand colors */}
          <View style={[styles.passCard, { backgroundColor: themeColors.brand }]}>
            <View style={styles.passHead}>
              <View style={[styles.chip, { backgroundColor: themeColors.primary }]}>
                <Ionicons name="hardware-chip" size={20} color={themeColors.brandDark} />
              </View>
              <Ionicons name="wifi" size={22} color="rgba(255,255,255,0.6)" style={{ transform: [{ rotate: '90deg' }] }} />
            </View>

            <Text style={styles.passEyebrow}>
              {myBooking.nfcCode ? `VISITOR PASS - #${myBooking.nfcCode}` : 'VISITOR PASS - PENDING APPROVAL'}
            </Text>
            <Text style={styles.passName} numberOfLines={1}>{user?.name || 'Visitor'}</Text>

            <View style={styles.passMetaRow}>
              <View style={{ flex: 1 }}>
                <Text style={styles.passMetaLabel}>Host</Text>
                <Text style={styles.passMetaValue} numberOfLines={1}>
                  {host?.name || '—'}
                </Text>
              </View>
              <View style={{ flex: 1 }}>
                <Text style={styles.passMetaLabel}>Scheduled</Text>
                <Text style={styles.passMetaValue} numberOfLines={1}>
                  {fmtDate(myBooking.scheduledAt)} · {fmtTime(myBooking.scheduledAt)}
                </Text>
              </View>
            </View>

            <View style={[styles.passDivider, { backgroundColor: 'rgba(255,255,255,0.18)' }]} />

            <View style={styles.passStatusRow}>
              <View style={[styles.passDot, { backgroundColor: themeColors.primary }]} />
              <Text style={[styles.passStatusText, { color: themeColors.primary }]}>
                Present this card at reception to check in
              </Text>
            </View>
          </View>

          {/* Details you submitted */}
          <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
            Details you submitted
          </Text>
          <Card>
            <DetailRow label="Company" value={myBooking.visitorCompany || '—'} />
            <View style={styles.hairline} />
            <DetailRow label="Purpose" value={myBooking.purpose || '—'} />
            <View style={styles.hairline} />
            <DetailRow label="Contact" value={myBooking.visitorPhone || '—'} />
          </Card>

          {/* Visit status timeline */}
          <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
            Visit status
          </Text>
          <Card>
            <TimelineStep
              done
              icon="checkmark"
              label="Details submitted"
              sub={`${fmtDate(myBooking.scheduledAt)} · ${fmtTime(myBooking.scheduledAt)}`}
              isLast={false}
            />
            {myBooking.status === 'rejected' ? (
              <TimelineStep
                done
                negative
                icon="close"
                label="Request declined"
                sub="This visit was not approved."
                isLast
              />
            ) : myBooking.status === 'admitted' ? (
              <TimelineStep
                done
                icon="checkmark"
                label="Approved · card issued"
                sub="You're all set for your visit."
                isLast
              />
            ) : (
              <TimelineStep
                done={false}
                icon="time-outline"
                label="Awaiting approval"
                sub="Reception will review your visit shortly."
                isLast
              />
            )}
          </Card>
        </>
      ) : (
        <Card>
          <View style={styles.emptyCard}>
            <Ionicons name="card-outline" size={28} color={colors.textMuted} />
            <Text variant="bodySemibold" color={colors.textSecondary} style={{ marginTop: 8 }}>
              No upcoming visit
            </Text>
            <Text variant="caption" color={colors.textMuted}>
              Book one below to get your NFC pass.
            </Text>
          </View>
        </Card>
      )}

      <CompanyMapSection />
    </Screen>
  );
}

function DetailRow({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.detailRow}>
      <Text variant="body" color={colors.textSecondary}>{label}</Text>
      <Text variant="bodySemibold">{value}</Text>
    </View>
  );
}

interface TimelineStepProps {
  done: boolean;
  negative?: boolean;
  icon: IoniconName;
  label: string;
  sub: string;
  isLast: boolean;
}

function TimelineStep({ done, negative, icon, label, sub, isLast }: TimelineStepProps) {
  const { colors: themeColors } = useTheme();
  const dotColor = negative ? themeColors.status.rejected.solid : done ? themeColors.status.success.solid : colors.borderStrong;
  return (
    <View style={styles.timelineRow}>
      <View style={styles.timelineRail}>
        <View style={[styles.timelineDot, { backgroundColor: dotColor }]}>
          {done ? <Ionicons name={icon} size={12} color="#FFFFFF" /> : null}
        </View>
        {!isLast ? <View style={styles.timelineLine} /> : null}
      </View>
      <View style={{ flex: 1, paddingBottom: isLast ? 0 : spacing.md }}>
        <Text variant="bodySemibold" color={done ? colors.textPrimary : colors.textSecondary}>
          {label}
        </Text>
        <Text variant="caption" color={colors.textMuted}>{sub}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  topRow: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    marginBottom: spacing.md,
  },
  bellBtn: {
    width: 40, height: 40, borderRadius: 20,
    alignItems: 'center', justifyContent: 'center',
  },
  bellBadge: {
    position: 'absolute', top: 2, right: 2,
    minWidth: 16, height: 16, borderRadius: 8, paddingHorizontal: 3,
    alignItems: 'center', justifyContent: 'center',
  },
  bellBadgeText: { fontSize: 10, lineHeight: 12 },
  welcome: { fontFamily: fonts.displayBold, fontSize: 22, color: colors.textPrimary },
  eyebrow: { marginTop: spacing.md, marginBottom: spacing.sm },

  // Pass card
  passCard: {
    borderRadius: radius.xl,
    padding: spacing.lg,
  },
  passHead: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    marginBottom: spacing.lg,
  },
  chip: {
    width: 40, height: 28, borderRadius: 6,
    alignItems: 'center', justifyContent: 'center',
  },
  passEyebrow: {
    fontFamily: fonts.semibold, fontSize: 11, letterSpacing: 1,
    color: 'rgba(255,255,255,0.65)', marginBottom: 6,
  },
  passName: {
    fontFamily: fonts.displayExtra, fontSize: 26, lineHeight: 32,
    color: '#FFFFFF', marginBottom: spacing.md,
  },
  passMetaRow: { flexDirection: 'row' },
  passMetaLabel: {
    fontFamily: fonts.medium, fontSize: 11,
    color: 'rgba(255,255,255,0.6)', marginBottom: 2,
  },
  passMetaValue: {
    fontFamily: fonts.semibold, fontSize: 14, color: '#FFFFFF',
  },
  passDivider: { height: 1, marginVertical: spacing.md },
  passStatusRow: { flexDirection: 'row', alignItems: 'center' },
  passDot: { width: 8, height: 8, borderRadius: 4, marginRight: 8 },
  passStatusText: { fontFamily: fonts.semibold, fontSize: 12, flex: 1 },

  // Details
  detailRow: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingVertical: spacing.xs,
  },
  hairline: { height: 1, backgroundColor: colors.border },

  // Timeline
  timelineRow: { flexDirection: 'row' },
  timelineRail: { alignItems: 'center', width: 24, marginRight: spacing.sm },
  timelineDot: {
    width: 22, height: 22, borderRadius: 11,
    alignItems: 'center', justifyContent: 'center',
  },
  timelineLine: { width: 2, flex: 1, backgroundColor: colors.border, marginVertical: 4 },

  emptyCard: { alignItems: 'center', paddingVertical: spacing.sm },
});
