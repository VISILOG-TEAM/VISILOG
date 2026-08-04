import React, { useState } from 'react';
import { View, StyleSheet, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Text, Card, Badge, Avatar, CompanyMapSection } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtDate, fmtTime } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';
import type { Appointment, IoniconName } from '../types';

interface VisitorHomeScreenProps {
  navigation: RootStackNavigation;
}

// VisitorHomeScreen -- the visitor's tab-bar landing page. The booking
// form itself now lives on its own "Book" tab (VisitorBookScreen); this
// screen is a dashboard: profile + notifications up top, a swipeable
// row of virtual pass cards -- one per non-rejected visit, not just the
// latest -- in the org's own brand colors (or a prompt to book, if
// there isn't one yet), then the submitted details and status timeline
// for whichever card is currently in view, and the company map/tour
// section.
export default function VisitorHomeScreen({ navigation }: VisitorHomeScreenProps) {
  const { colors } = useTheme();
  const { user, organization } = useAuth();
  const { employees, appointments, unreadNotificationCount, refreshAll, plans } = useData();
  // organization.planId (not the manager-only billing.planId) since
  // visitors don't have access to Billing -- see OrganizationDto.
  const currentPlan = plans.find((p) => p.id === organization?.planId);
  const hasTourMap = !!currentPlan?.features.includes('Interactive tour map');
  const [refreshing, setRefreshing] = useState(false);
  const [activeCardIndex, setActiveCardIndex] = useState(0);
  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshAll();
    } finally {
      setRefreshing(false);
    }
  };

  // Every one of this visitor's own bookings that could still matter --
  // a rejected one has no pass to present, so it doesn't get a card.
  // Soonest-up-next first, same convention as the appointments list
  // (see AppointmentsScreen.byUpcomingFirst): a visit still ahead of you
  // belongs before one that already happened.
  const myBookings = appointments
    .filter((a) => a.bookedByEmail === user!.email && a.status !== 'rejected')
    .sort((a, b) => {
      const now = Date.now();
      const aTime = new Date(a.scheduledAt).getTime();
      const bTime = new Date(b.scheduledAt).getTime();
      const aUpcoming = aTime >= now;
      const bUpcoming = bTime >= now;
      if (aUpcoming !== bUpcoming) return aUpcoming ? -1 : 1;
      return aUpcoming ? aTime - bTime : bTime - aTime;
    });

  const activeBooking = myBookings[activeCardIndex] ?? myBookings[0] ?? null;

  // Tapping the card advances to the next one (wrapping back to the
  // first after the last) -- a horizontal ScrollView here used to let
  // the next card's edge peek into view and didn't reliably respond to
  // a swipe (it was competing with the page's own vertical scroll for
  // the gesture); showing exactly one card and advancing on tap has no
  // gesture to lose to anything else.
  const onCardTap = () => {
    if (myBookings.length < 2) return;
    setActiveCardIndex((i) => (i + 1) % myBookings.length);
  };

  return (
    <Screen refreshing={refreshing} onRefresh={onRefresh}>
      <View style={styles.topRow}>
        <Pressable onPress={() => navigation.navigate('Settings')}>
          <Avatar name={user?.name || 'You'} size={44} />
        </Pressable>
        <Pressable
          onPress={() => navigation.navigate('Notifications')}
          style={[styles.bellBtn, { backgroundColor: colors.primarySurface }]}
          hitSlop={8}
        >
          <Ionicons name="notifications-outline" size={22} color={colors.brand} />
          {unreadNotificationCount > 0 ? (
            <View style={[styles.bellBadge, { backgroundColor: colors.status.rejected.solid }]}>
              <Text variant="caption" color="#FFFFFF" style={styles.bellBadgeText}>
                {unreadNotificationCount > 9 ? '9+' : unreadNotificationCount}
              </Text>
            </View>
          ) : null}
        </Pressable>
      </View>

      <Text style={[styles.welcome, { color: colors.textPrimary }]}>
        {myBookings.length > 0
          ? `Welcome back, ${user!.name?.split(' ')[0] || 'there'}`
          : 'Ready to book your first appointment?'}
      </Text>
      <Text variant="body" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
        {myBookings.length === 0
          ? 'Head to the Book tab to schedule a visit and get your NFC pass.'
          : myBookings.length === 1
            ? "Here's your visit pass."
            : `Here are your ${myBookings.length} visit passes -- tap the card to switch.`}
      </Text>

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Your virtual card{myBookings.length > 1 ? 's' : ''}
      </Text>
      {myBookings.length > 0 && activeBooking ? (
        <>
          <Pressable onPress={onCardTap} disabled={myBookings.length < 2}>
            <PassCard
              booking={activeBooking}
              visitorName={user?.name || 'Visitor'}
              hostName={employees.find((e) => e.id === activeBooking.hostId)?.name}
              tapHint={myBookings.length > 1}
            />
          </Pressable>

          {myBookings.length > 1 ? (
            <View style={styles.dotsRow}>
              {myBookings.map((b, i) => (
                <Pressable key={b.id} onPress={() => setActiveCardIndex(i)} hitSlop={6}>
                  <View
                    style={[
                      styles.dot,
                      { backgroundColor: i === activeCardIndex ? colors.primary : colors.border },
                    ]}
                  />
                </Pressable>
              ))}
            </View>
          ) : null}

          {/* Details you submitted -- for whichever card is in view */}
          <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
            Details you submitted
          </Text>
          <Card>
            <DetailRow label="Company" value={activeBooking!.visitorCompany || '--'} />
            <View style={[styles.hairline, { backgroundColor: colors.border }]} />
            <DetailRow label="Purpose" value={activeBooking!.purpose || '--'} />
            <View style={[styles.hairline, { backgroundColor: colors.border }]} />
            <DetailRow label="Contact" value={activeBooking!.visitorPhone || '--'} />
          </Card>

          {/* Visit status timeline -- for whichever card is in view */}
          <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
            Visit status
          </Text>
          <Card>
            <TimelineStep
              done
              icon="checkmark"
              label="Details submitted"
              sub={`${fmtDate(activeBooking!.scheduledAt)} - ${fmtTime(activeBooking!.scheduledAt)}`}
              isLast={false}
            />
            {activeBooking!.status === 'rejected' ? (
              <TimelineStep
                done
                negative
                icon="close"
                label="Request declined"
                sub="This visit was not approved."
                isLast
              />
            ) : activeBooking!.status === 'admitted' ? (
              <TimelineStep
                done
                icon="checkmark"
                label="Approved - card issued"
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

      {hasTourMap && <CompanyMapSection />}
    </Screen>
  );
}

function PassCard({
  booking,
  visitorName,
  hostName,
  tapHint,
}: {
  booking: Appointment;
  visitorName: string;
  hostName?: string;
  /** Shows a small "tap for next" affordance -- only meaningful when there's more than one card. */
  tapHint?: boolean;
}) {
  const { colors } = useTheme();
  return (
    // Full-bleed pass card in the org's own brand colors
    <View style={[styles.passCard, { backgroundColor: colors.brand }]}>
      <View style={styles.passHead}>
        <View style={[styles.chip, { backgroundColor: colors.primary }]}>
          <Ionicons name="hardware-chip" size={20} color={colors.brandDark} />
        </View>
        {tapHint ? (
          <View style={styles.tapHint}>
            <Text style={styles.tapHintText}>Tap for next</Text>
            <Ionicons name="chevron-forward" size={14} color="rgba(255,255,255,0.6)" />
          </View>
        ) : (
          <Ionicons
            name="wifi"
            size={22}
            color="rgba(255,255,255,0.6)"
            style={{ transform: [{ rotate: '90deg' }] }}
          />
        )}
      </View>

      <Text style={styles.passEyebrow}>
        {booking.nfcCode ? `VISITOR PASS - #${booking.nfcCode}` : 'VISITOR PASS - PENDING APPROVAL'}
      </Text>
      <Text style={styles.passName} numberOfLines={1}>
        {visitorName}
      </Text>

      <View style={styles.passMetaRow}>
        <View style={{ flex: 1 }}>
          <Text style={styles.passMetaLabel}>Host</Text>
          <Text style={styles.passMetaValue} numberOfLines={1}>
            {hostName || '--'}
          </Text>
        </View>
        <View style={{ flex: 1 }}>
          <Text style={styles.passMetaLabel}>Scheduled</Text>
          <Text style={styles.passMetaValue} numberOfLines={1}>
            {fmtDate(booking.scheduledAt)} - {fmtTime(booking.scheduledAt)}
          </Text>
        </View>
      </View>

      <View style={[styles.passDivider, { backgroundColor: 'rgba(255,255,255,0.18)' }]} />

      <View style={styles.passStatusRow}>
        <View style={[styles.passDot, { backgroundColor: colors.primary }]} />
        <Text style={[styles.passStatusText, { color: colors.primary }]}>
          Present this card at reception to check in
        </Text>
      </View>
    </View>
  );
}

function DetailRow({ label, value }: { label: string; value: string }) {
  const { colors } = useTheme();
  return (
    <View style={styles.detailRow}>
      <Text variant="body" color={colors.textSecondary}>
        {label}
      </Text>
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
  const { colors } = useTheme();
  const dotColor = negative
    ? colors.status.rejected.solid
    : done
      ? colors.status.success.solid
      : colors.borderStrong;
  return (
    <View style={styles.timelineRow}>
      <View style={styles.timelineRail}>
        <View style={[styles.timelineDot, { backgroundColor: dotColor }]}>
          {done ? <Ionicons name={icon} size={12} color="#FFFFFF" /> : null}
        </View>
        {!isLast ? (
          <View style={[styles.timelineLine, { backgroundColor: colors.border }]} />
        ) : null}
      </View>
      <View style={{ flex: 1, paddingBottom: isLast ? 0 : spacing.md }}>
        <Text variant="bodySemibold" color={done ? colors.textPrimary : colors.textSecondary}>
          {label}
        </Text>
        <Text variant="caption" color={colors.textMuted}>
          {sub}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  topRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: spacing.md,
  },
  bellBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  bellBadge: {
    position: 'absolute',
    top: 2,
    right: 2,
    minWidth: 16,
    height: 16,
    borderRadius: 8,
    paddingHorizontal: 3,
    alignItems: 'center',
    justifyContent: 'center',
  },
  bellBadgeText: { fontSize: 10, lineHeight: 12 },
  welcome: { fontFamily: fonts.displayBold, fontSize: 22 },
  eyebrow: { marginTop: spacing.md, marginBottom: spacing.sm },

  dotsRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: spacing.sm,
  },
  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    marginHorizontal: 3,
  },

  // Pass card
  passCard: {
    borderRadius: radius.xl,
    padding: spacing.lg,
  },
  passHead: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: spacing.lg,
  },
  tapHint: { flexDirection: 'row', alignItems: 'center' },
  tapHintText: {
    fontFamily: fonts.medium,
    fontSize: 11,
    color: 'rgba(255,255,255,0.6)',
    marginRight: 2,
  },
  chip: {
    width: 40,
    height: 28,
    borderRadius: 6,
    alignItems: 'center',
    justifyContent: 'center',
  },
  passEyebrow: {
    fontFamily: fonts.semibold,
    fontSize: 11,
    letterSpacing: 1,
    color: 'rgba(255,255,255,0.65)',
    marginBottom: 6,
  },
  passName: {
    fontFamily: fonts.displayExtra,
    fontSize: 26,
    lineHeight: 32,
    color: '#FFFFFF',
    marginBottom: spacing.md,
  },
  passMetaRow: { flexDirection: 'row' },
  passMetaLabel: {
    fontFamily: fonts.medium,
    fontSize: 11,
    color: 'rgba(255,255,255,0.6)',
    marginBottom: 2,
  },
  passMetaValue: {
    fontFamily: fonts.semibold,
    fontSize: 14,
    color: '#FFFFFF',
  },
  passDivider: { height: 1, marginVertical: spacing.md },
  passStatusRow: { flexDirection: 'row', alignItems: 'center' },
  passDot: { width: 8, height: 8, borderRadius: 4, marginRight: 8 },
  passStatusText: { fontFamily: fonts.semibold, fontSize: 12, flex: 1 },

  // Details
  detailRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: spacing.xs,
  },
  hairline: { height: 1 },

  // Timeline
  timelineRow: { flexDirection: 'row' },
  timelineRail: { alignItems: 'center', width: 24, marginRight: spacing.sm },
  timelineDot: {
    width: 22,
    height: 22,
    borderRadius: 11,
    alignItems: 'center',
    justifyContent: 'center',
  },
  timelineLine: { width: 2, flex: 1, marginVertical: 4 },

  emptyCard: { alignItems: 'center', paddingVertical: spacing.sm },
});
