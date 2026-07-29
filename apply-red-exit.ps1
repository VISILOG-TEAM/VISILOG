# VisiLog - red exit buttons everywhere you leave the app
# Run from the repository root.
$ErrorActionPreference = 'Stop'

$content = @'
import React, { type ReactNode } from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import type { IoniconName } from '../types';

interface HeaderAction {
  icon: IoniconName;
  onPress?: () => void;
  badge?: number;
  /** Red treatment for an action that signs you out of the app. Matches
   *  the `dangerSubtle` Button variant used by Sign out in Settings, so
   *  leaving VisiLog looks the same wherever you do it. */
  danger?: boolean;
}

interface HeaderProps {
  title: string;
  subtitle?: string;
  eyebrow?: string;
  rightIcon?: IoniconName;
  onRightPress?: () => void;
  /** Unread-count badge for the single rightIcon button. */
  badge?: number;
  /** A row of icon buttons (e.g. notifications bell + logout) -- takes
   * priority over rightIcon/right when given. */
  rightActions?: HeaderAction[];
  right?: ReactNode;
  onBackPress?: () => void;
}

function ActionButton({ icon, onPress, badge, danger }: HeaderAction) {
  const { colors } = useTheme();
  const background = danger ? colors.status.error.bg : colors.surface;
  const border = danger ? colors.status.error.fg : colors.border;
  const foreground = danger ? colors.status.error.fg : colors.brand;
  return (
    <Pressable
      onPress={onPress}
      hitSlop={8}
      style={({ pressed }) => [
        styles.iconBtn,
        { backgroundColor: background, borderColor: border },
        pressed && { opacity: 0.6 },
      ]}
    >
      <Ionicons name={icon} size={20} color={foreground} />
      {badge ? (
        <View style={[styles.badge, { backgroundColor: colors.palette.red600 }]}>
          <Text variant="caption" color={colors.textInverse} style={styles.badgeText}>
            {badge > 9 ? '9+' : badge}
          </Text>
        </View>
      ) : null}
    </Pressable>
  );
}

// Consistent page header. Pass `rightIcon` (+ onRightPress, optionally
// `badge`... via rightActions) for a quick action button, `rightActions`
// for several buttons in a row, or `right` to drop in a fully custom
// element. Pass `onBackPress` for a leading back chevron on screens
// pushed onto the stack (the app hides the native header, so this is
// the only back affordance those screens get).
export default function Header({
  title,
  subtitle,
  eyebrow,
  rightIcon,
  onRightPress,
  badge,
  rightActions,
  right,
  onBackPress,
}: HeaderProps) {
  const { colors } = useTheme();
  return (
    <View style={styles.row}>
      {onBackPress ? (
        <Pressable onPress={onBackPress} hitSlop={8} style={styles.backBtn}>
          <Ionicons name="chevron-back" size={22} color={colors.brand} />
        </Pressable>
      ) : null}
      <View style={styles.left}>
        {eyebrow ? (
          <Text variant="eyebrow" color={colors.primary} style={styles.eyebrow}>
            {eyebrow}
          </Text>
        ) : null}
        <Text variant="h1">{title}</Text>
        {subtitle ? (
          <Text variant="body" color={colors.textSecondary} style={styles.subtitle}>
            {subtitle}
          </Text>
        ) : null}
      </View>

      {rightActions && rightActions.length > 0 ? (
        <View style={styles.actionsRow}>
          {rightActions.map((action, i) => (
            <View key={action.icon + i} style={i > 0 ? styles.actionsGap : undefined}>
              <ActionButton {...action} />
            </View>
          ))}
        </View>
      ) : rightIcon ? (
        <ActionButton icon={rightIcon} onPress={onRightPress} badge={badge} />
      ) : (
        right || null
      )}
    </View>
  );
}

// row/left/backBtn/eyebrow/subtitle are layout-only; iconBtn's/badge's
// color values are applied inline above from useTheme() instead.
const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    marginBottom: spacing.lg,
  },
  left: { flex: 1, paddingRight: spacing.md },
  backBtn: {
    width: 36,
    height: 36,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing.xs,
    marginTop: 2,
  },
  eyebrow: { marginBottom: 4 },
  subtitle: { marginTop: 2 },
  iconBtn: {
    width: 40,
    height: 40,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
  },
  actionsRow: { flexDirection: 'row' },
  actionsGap: { marginLeft: spacing.xs },
  badge: {
    position: 'absolute',
    top: -4,
    right: -4,
    minWidth: 16,
    height: 16,
    borderRadius: 8,
    paddingHorizontal: 3,
    alignItems: 'center',
    justifyContent: 'center',
  },
  badgeText: { fontSize: 10, lineHeight: 12 },
});

'@
$path = Join-Path (Get-Location) 'src\components\Header.tsx'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/Header.tsx'

$content = @'
import React, { useState } from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import { Screen, Header, Text, Card, Badge, StatTile, Avatar, ClockCard } from '../components';
import ManagerTour from '../components/ManagerTour';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';

interface ManagerHomeScreenProps {
  navigation: RootStackNavigation;
}

// Manager dashboard: organisation-wide insight, plus the same
// clock-in/out card every other role gets -- an Administrator is staff
// too, and shows up on their own Clock-ins screen like everyone else.
export default function ManagerHomeScreen({ navigation }: ManagerHomeScreenProps) {
  const { colors, setOrgTheme } = useTheme();
  const { user, logout } = useAuth();
  const { stats, visitors, calls, employees, employeeById, unreadNotificationCount, refreshAll } =
    useData();
  const onLogout = () => {
    logout();
    setOrgTheme(null);
  };
  const [refreshing, setRefreshing] = useState(false);
  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshAll();
    } finally {
      setRefreshing(false);
    }
  };

  // Top hosts (employees with the most visitors).
  const hostCounts: Record<string, number> = {};
  visitors.forEach((v) => {
    hostCounts[v.hostId] = (hostCounts[v.hostId] || 0) + 1;
  });
  const topHosts = Object.entries(hostCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([id, count]) => ({ employee: employeeById(id), count }));

  return (
    <Screen refreshing={refreshing} onRefresh={onRefresh}>
      <Header
        eyebrow="Manager view"
        title="Overview"
        subtitle="Insight & attendance across the organisation"
        rightActions={[
          {
            icon: 'notifications-outline',
            onPress: () => navigation.navigate('Notifications'),
            badge: unreadNotificationCount,
          },
          { icon: 'log-out-outline', onPress: onLogout, danger: true },
        ]}
      />

      <ClockCard />

      <View style={{ flexDirection: 'row', marginTop: spacing.md }}>
        <StatTile icon="people" tint="primary" label="Visitors today" value={stats.visitorsToday} />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="checkmark-circle" tint="success" label="On-site" value={stats.onsite} />
      </View>
      <View style={{ flexDirection: 'row', marginTop: spacing.sm }}>
        <StatTile icon="call" tint="info" label="Calls today" value={stats.callsToday} />
        <View style={{ width: spacing.sm }} />
        <StatTile
          icon="calendar"
          tint="pending"
          label="This month"
          value={stats.visitorsThisMonth}
        />
      </View>

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Top hosts
      </Text>
      <Card>
        {topHosts.map((h, i) => (
          <View key={h.employee?.id || i} style={styles.row}>
            <Text variant="bodySemibold" style={{ width: 24 }}>
              {i + 1}
            </Text>
            <Avatar name={h.employee?.name || '?'} size={36} />
            <View style={{ flex: 1, marginLeft: spacing.sm }}>
              <Text variant="bodySemibold">{h.employee?.name || 'Unknown'}</Text>
              <Text variant="caption" color={colors.textSecondary}>
                {h.employee?.department}
              </Text>
            </View>
            <Badge label={`${h.count} visits`} status="info" size="sm" dot={false} />
          </View>
        ))}
      </Card>

      <View style={styles.sectionHeader}>
        <Text variant="eyebrow" color={colors.textMuted}>
          Currently on-site
        </Text>
        <Pressable onPress={() => navigation.navigate('Visitors')}>
          <Text variant="label" color={colors.primary}>
            View all visitors
          </Text>
        </Pressable>
      </View>
      <Card>
        {visitors
          .filter((v) => v.status === 'onsite')
          .map((v) => (
            <View key={v.id} style={styles.row}>
              <Avatar name={v.fullName} size={36} />
              <View style={{ flex: 1, marginLeft: spacing.sm }}>
                <Text variant="bodySemibold">{v.fullName}</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {employeeById(v.hostId)?.name} - {fmtTime(v.checkInAt)}
                </Text>
              </View>
            </View>
          ))}
      </Card>
      {/* First-run orientation, shown once per Administrator. Lives
          here rather than in the navigator so it appears over the
          screen a new manager actually lands on. */}
      <ManagerTour />
    </Screen>
  );
}

const styles = StyleSheet.create({
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: 8 },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: spacing.xl,
    marginBottom: spacing.sm,
  },
});

'@
$path = Join-Path (Get-Location) 'src\screens\ManagerHomeScreen.tsx'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/ManagerHomeScreen.tsx'

$content = @'
import React, { useState } from 'react';
import { View, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Button, Avatar, StatTile, ClockCard } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';

interface EmployeeHomeScreenProps {
  navigation: RootStackNavigation;
}

// Employee dashboard: check in/out for work, accept/decline visitors
// who picked them as host, view incoming calls, see their NFC card.
export default function EmployeeHomeScreen({ navigation }: EmployeeHomeScreenProps) {
  const { colors, setOrgTheme } = useTheme();
  const { user, logout } = useAuth();
  const {
    appointments,
    calls,
    updateAppointmentStatus,
    admitAppointment,
    unreadNotificationCount,
    refreshAll,
  } = useData();
  const onLogout = () => {
    logout();
    setOrgTheme(null);
  };
  const [refreshing, setRefreshing] = useState(false);
  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshAll();
    } finally {
      setRefreshing(false);
    }
  };

  // The backend already scopes GET /appointments to only this employee's
  // own hosted visits (see AppointmentService.list) -- reception is the
  // only role that ever gets the whole org's list.
  const myPending = appointments.filter((a) => a.status === 'pending');
  const myCalls = calls.slice(0, 3);

  return (
    <Screen refreshing={refreshing} onRefresh={onRefresh}>
      <Header
        eyebrow="Employee dashboard"
        title={`Hi, ${user!.name?.split(' ')[0]}`}
        subtitle={user!.email}
        rightActions={[
          {
            icon: 'notifications-outline',
            onPress: () => navigation.navigate('Notifications'),
            badge: unreadNotificationCount,
          },
          { icon: 'log-out-outline', onPress: onLogout, danger: true },
        ]}
      />

      <ClockCard />

      {/* Stats */}
      <View style={{ flexDirection: 'row', marginTop: spacing.md }}>
        <StatTile icon="people" tint="primary" label="Pending visitors" value={myPending.length} />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="call" tint="info" label="Recent calls" value={myCalls.length} />
      </View>

      {/* Pending visitor requests */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Visitors waiting for you
      </Text>
      {myPending.length === 0 ? (
        <Card>
          <Text variant="body" color={colors.textSecondary}>
            No visitor requests at the moment.
          </Text>
        </Card>
      ) : (
        myPending.map((a) => (
          <Card key={a.id} style={{ marginBottom: spacing.sm }}>
            <View style={styles.requestRow}>
              <Avatar name={a.visitorName} size={40} />
              <View style={{ flex: 1, marginLeft: spacing.sm }}>
                <Text variant="bodySemibold">{a.visitorName}</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {a.purpose} - Code {a.nfcCode}
                </Text>
              </View>
            </View>
            <View style={{ flexDirection: 'row', marginTop: spacing.sm }}>
              <Button
                label="Decline"
                variant="secondary"
                onPress={() => updateAppointmentStatus(a.id, 'rejected')}
                style={{ flex: 1, marginRight: spacing.xs }}
              />
              <Button
                label="Accept"
                onPress={() => admitAppointment(a)}
                style={{ flex: 1, marginLeft: spacing.xs }}
              />
            </View>
          </Card>
        ))
      )}

      {/* Calls preview */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Recent calls for you
      </Text>
      <Card>
        {myCalls.length === 0 ? (
          <Text variant="body" color={colors.textSecondary}>
            No recent calls.
          </Text>
        ) : (
          myCalls.map((c) => (
            <View key={c.id} style={styles.callRow}>
              <Ionicons name="call" size={16} color={colors.primary} />
              <Text variant="bodyMd" style={{ flex: 1, marginLeft: 8 }}>
                {c.callerName}
              </Text>
              <Text variant="caption" color={colors.textMuted}>
                {fmtTime(c.timestamp)}
              </Text>
            </View>
          ))
        )}
      </Card>
    </Screen>
  );
}

const styles = StyleSheet.create({
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  requestRow: { flexDirection: 'row', alignItems: 'center' },
  callRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 6 },
});

'@
$path = Join-Path (Get-Location) 'src\screens\EmployeeHomeScreen.tsx'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/EmployeeHomeScreen.tsx'

$content = @'
import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  Pressable,
  TextInput,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { Text } from '../components';
import { useAuth } from '../context/AuthContext';
import { fonts } from '../theme/typography';
import { spacing, radius } from '../theme/spacing';

// The last step of signing up: confirm the email address the account
// was created with by entering the 6-digit code sent to it.
//
// This is the ONLY screen an unverified account can reach -- see
// RootNavigator, and the matching server-side gate in JwtAuthFilter, so
// it holds whether or not the app is the thing enforcing it. Styled
// like RegisterCompany/Signup rather than the in-app screens because
// that's what it continues from; it isn't "inside" the app yet.
export default function VerifyEmailScreen() {
  const { user, organization, verifyEmail, resendVerification, logout } = useAuth();
  const [code, setCode] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [resending, setResending] = useState(false);

  const onSubmit = async () => {
    if (submitting) return;
    setSubmitting(true);
    setError(null);
    setNotice(null);
    const result = await verifyEmail(code);
    // On success there's nothing to navigate to: `user.emailVerified`
    // flips, RootNavigator re-renders, and this screen is replaced by
    // the role's tab shell. Don't setState after that -- the component
    // is already on its way out.
    if (!result.ok) {
      setError(result.error ?? 'Could not verify that code.');
      setSubmitting(false);
    }
  };

  const onResend = async () => {
    if (resending) return;
    setResending(true);
    setError(null);
    setNotice(null);
    const result = await resendVerification();
    if (result.ok) {
      setNotice(result.message);
      setCode('');
    } else {
      setError(result.message);
    }
    setResending(false);
  };

  return (
    <View style={styles.bg}>
      <StatusBar style="light" />
      <SafeAreaView style={styles.safe}>
        <KeyboardAvoidingView style={{ flex: 1 }} behavior="padding">
          <ScrollView
            contentContainerStyle={styles.scroll}
            keyboardShouldPersistTaps="handled"
            showsVerticalScrollIndicator={false}
          >
            <BlurView intensity={25} tint="light" style={styles.card}>
              <View style={styles.cardInner}>
                <View style={styles.iconRing}>
                  <Ionicons name="mail-open-outline" size={26} color="#FFFFFF" />
                </View>

                <Text style={styles.heading}>Check your email</Text>
                <Text style={styles.body}>
                  We sent a 6-digit code to {user?.email ?? 'your email address'}. Enter it below to
                  finish setting up your account.
                </Text>

                <TextInput
                  value={code}
                  onChangeText={(next) => setCode(next.replace(/[^0-9]/g, ''))}
                  placeholder="000000"
                  placeholderTextColor="rgba(255,255,255,0.4)"
                  keyboardType="number-pad"
                  maxLength={6}
                  style={styles.codeInput}
                  autoFocus
                />

                {error ? <Text style={styles.error}>{error}</Text> : null}
                {notice ? <Text style={styles.notice}>{notice}</Text> : null}

                <Pressable
                  onPress={onSubmit}
                  disabled={submitting}
                  style={({ pressed }) => [{ opacity: pressed || submitting ? 0.85 : 1 }]}
                >
                  <LinearGradient
                    colors={['#5ECFC9', '#1B8A82', '#0B4A47']}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={styles.submitBtn}
                  >
                    {submitting ? (
                      <ActivityIndicator color="#FFFFFF" />
                    ) : (
                      <Text style={styles.submitBtnText}>Verify my email</Text>
                    )}
                  </LinearGradient>
                </Pressable>

                <Pressable onPress={onResend} disabled={resending} style={styles.resendRow}>
                  <Text style={styles.resendText}>
                    {resending ? 'Sending...' : "Didn't get it? Resend code"}
                  </Text>
                </Pressable>

                {/* A manager who just registered gets their company code
                    here as well as in the confirmation dialog -- they
                    can't reach Company Setup (where it otherwise lives)
                    until this screen is done with, and that code is the
                    thing their whole staff needs to sign up. */}
                {user?.role === 'manager' && organization?.code ? (
                  <View style={styles.codeNote}>
                    <Text style={styles.codeNoteLabel}>Your company code</Text>
                    <Text style={styles.codeNoteValue}>{organization.code}</Text>
                    <Text style={styles.codeNoteHint}>
                      Share this with your staff and visitors so they can sign up. You can find it
                      again in Company Setup.
                    </Text>
                  </View>
                ) : null}

                {/* Escape hatch: without this, one typo in an email
                    address locks the account out of the app with no way
                    back to the login screen. */}
                <Pressable onPress={logout} style={styles.signOutRow}>
                  <Text style={styles.signOutText}>Wrong address? Sign out and start again</Text>
                </Pressable>
              </View>
            </BlurView>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  bg: { flex: 1, backgroundColor: '#0F3D2A' },
  safe: { flex: 1 },
  scroll: {
    flexGrow: 1,
    justifyContent: 'center',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.xxl,
  },

  card: {
    borderRadius: radius.xl,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.35)',
  },
  cardInner: {
    padding: spacing.xl,
    backgroundColor:
      Platform.OS === 'android' ? 'rgba(255,255,255,0.12)' : 'rgba(255,255,255,0.05)',
  },

  iconRing: {
    width: 56,
    height: 56,
    borderRadius: 28,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.15)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.3)',
    alignSelf: 'center',
    marginBottom: spacing.md,
  },

  heading: {
    fontFamily: fonts.displayBold,
    fontSize: 24,
    color: '#FFFFFF',
    textAlign: 'center',
  },
  body: {
    fontFamily: fonts.regular,
    fontSize: 13,
    lineHeight: 20,
    color: 'rgba(255,255,255,0.85)',
    textAlign: 'center',
    marginTop: spacing.xs,
    marginBottom: spacing.lg,
  },

  // Wide letter-spacing and a big face: this is six digits copied from
  // an email, so legibility beats matching the ordinary input style.
  codeInput: {
    fontFamily: fonts.displayBold,
    fontSize: 28,
    letterSpacing: 8,
    color: '#FFFFFF',
    textAlign: 'center',
    backgroundColor: 'rgba(255,255,255,0.12)',
    borderColor: 'rgba(255,255,255,0.28)',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingVertical: spacing.sm,
    marginBottom: spacing.md,
  },

  error: {
    fontFamily: fonts.regular,
    fontSize: 13,
    color: '#FFD9D9',
    textAlign: 'center',
    marginBottom: spacing.sm,
  },
  notice: {
    fontFamily: fonts.regular,
    fontSize: 13,
    color: '#D6F5E4',
    textAlign: 'center',
    marginBottom: spacing.sm,
  },

  submitBtn: {
    height: 50,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  submitBtnText: { fontFamily: fonts.bold, fontSize: 16, color: '#FFFFFF', letterSpacing: 0.3 },

  resendRow: { alignItems: 'center', marginTop: spacing.md },
  resendText: { fontFamily: fonts.bold, fontSize: 13, color: '#FFFFFF' },

  codeNote: {
    marginTop: spacing.lg,
    padding: spacing.md,
    borderRadius: radius.md,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.22)',
  },
  codeNoteLabel: {
    fontFamily: fonts.regular,
    fontSize: 11,
    color: 'rgba(255,255,255,0.75)',
    textAlign: 'center',
  },
  codeNoteValue: {
    fontFamily: fonts.displayBold,
    fontSize: 22,
    letterSpacing: 1,
    color: '#FFFFFF',
    textAlign: 'center',
    marginVertical: 2,
  },
  codeNoteHint: {
    fontFamily: fonts.regular,
    fontSize: 11,
    lineHeight: 16,
    color: 'rgba(255,255,255,0.75)',
    textAlign: 'center',
  },

  signOutRow: { alignItems: 'center', marginTop: spacing.lg },
  // Red, like every other way out of the app. A literal theme red would
  // disappear against this dark green card, so this is the same soft
  // red the error text on this screen uses -- reads as "red" at a
  // glance while staying legible on the brand background.
  signOutText: { fontFamily: fonts.bold, fontSize: 12, color: '#FFB4B4' },
});

'@
$path = Join-Path (Get-Location) 'src\screens\VerifyEmailScreen.tsx'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/VerifyEmailScreen.tsx'

Write-Host ''
Write-Host 'Done. 4 files written.'
Write-Host 'Next: run   npx tsc --noEmit'
