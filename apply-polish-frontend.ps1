# VisiLog frontend - red exit buttons, Company name field, pull-to-refresh everywhere
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
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
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
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
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
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
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
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/VerifyEmailScreen.tsx'

$content = @'
import React, { useEffect, useState } from 'react';
import {
  View,
  StyleSheet,
  Pressable,
  TextInput,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import * as AuthSession from 'expo-auth-session';
import * as WebBrowser from 'expo-web-browser';
import * as Crypto from 'expo-crypto';
import { Text, Segmented } from '../components';
import { fonts } from '../theme/typography';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { loadRememberedLogin } from '../api/rememberedLogin';
import { API_BASE_URL } from '../api/config';
import { GOOGLE_CLIENT_ID } from '../api/googleConfig';
import type { RootStackNavigation } from '../types/navigation';

// Closes the in-app browser tab automatically once Google redirects
// back -- without this the tab can be left hanging open after a
// successful sign-in.
WebBrowser.maybeCompleteAuthSession();

const GOOGLE_DISCOVERY = {
  authorizationEndpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
  tokenEndpoint: 'https://oauth2.googleapis.com/token',
};

interface LoginScreenProps {
  navigation: RootStackNavigation;
}

// LoginScreen
// ---------------------------------------------------------------
// Uses the original teal-silk background photo (kept on Login/Signup
// specifically, per design direction -- the green gradient is only for
// the newer Splash/RoleSelect screens). The sign-in/register pill at
// the top of the card is purely navigational -- tapping "Register"
// jumps to the Signup screen (see Segmented usage below).
//
// The company code identifies which paying organization (tenant) this
// login belongs to -- VisiLog serves several companies, each with their
// own data and brand colors, so this resolves both.
export default function LoginScreen({ navigation }: LoginScreenProps) {
  const { login, loginWithGoogle } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [companyCode, setCompanyCode] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [remember, setRemember] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [googleSubmitting, setGoogleSubmitting] = useState(false);
  const [nonce] = useState(() => Crypto.randomUUID());

  // "Remember me" previously only kept the session alive across app
  // restarts -- it never actually remembered anything the user could
  // see, which is what the label promises. This restores the last
  // company code + email (never the password) that were saved on a
  // successful login with the box checked.
  useEffect(() => {
    (async () => {
      const remembered = await loadRememberedLogin();
      if (remembered) {
        setCompanyCode(remembered.companyCode);
        setEmail(remembered.email);
      }
    })();
  }, []);

  // Requesting an ID token directly (rather than an auth code) means no
  // client secret is ever needed on the phone -- Google hands back a
  // signed token in the redirect, and the backend is the one that
  // actually verifies it (see GoogleTokenService), never the app itself.
  //
  // Google's OAuth client only accepts a real HTTPS domain as a
  // redirect target, not a bare app scheme -- so this points at a tiny
  // landing page hosted by our own backend (OAuthRedirectController),
  // which immediately bounces the browser on to visilog://oauth-redirect
  // carrying the result forward. expo-auth-session's redirect listener
  // (registered via app.json's "scheme") catches that final hop.
  const [request, , promptAsync] = AuthSession.useAuthRequest(
    {
      clientId: GOOGLE_CLIENT_ID,
      scopes: ['openid', 'profile', 'email'],
      redirectUri: `${API_BASE_URL}/oauth/google/redirect`,
      responseType: AuthSession.ResponseType.IdToken,
      extraParams: { nonce },
    },
    GOOGLE_DISCOVERY,
  );

  const onSubmit = async () => {
    setSubmitting(true);
    const result = await login(email, password, companyCode, remember);
    setSubmitting(false);
    if (!result.ok) {
      Alert.alert('Login failed', result.error);
      return;
    }
    // On success the root navigator will swap to the app stack.
  };

  const onGoogleLogin = async () => {
    if (!GOOGLE_CLIENT_ID) {
      Alert.alert('Not set up yet', 'Google sign-in has not been configured for this build.');
      return;
    }
    if (!companyCode.trim()) {
      Alert.alert('Almost there', 'Enter your company code first, then continue with Google.');
      return;
    }
    setGoogleSubmitting(true);
    try {
      const result = await promptAsync();
      if (result.type !== 'success' || !result.params.id_token) {
        setGoogleSubmitting(false);
        return;
      }
      const authResult = await loginWithGoogle(companyCode, result.params.id_token);
      setGoogleSubmitting(false);
      if (!authResult.ok) {
        Alert.alert('Google sign-in failed', authResult.error);
      }
      // On success the root navigator will swap to the app stack.
    } catch {
      setGoogleSubmitting(false);
      Alert.alert('Google sign-in failed', 'Something went wrong. Please try again.');
    }
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
            {/* The frosted glass card. expo-blur renders a real iOS-style
 blur; on Android it falls back to a translucent fill. */}
            <BlurView intensity={25} tint="light" style={styles.card}>
              <View style={styles.cardInner}>
                {/* Wordmark -- used here instead of a separate logo image */}
                <Text style={styles.wordmark}>VisiLog</Text>
                <Text style={styles.tagline}>Visitor Management & Reception Operations</Text>

                <Segmented
                  value="signin"
                  onChange={(v) => {
                    if (v === 'register') navigation.navigate('Signup');
                  }}
                  options={[
                    { label: 'Sign in', value: 'signin' },
                    { label: 'Register', value: 'register' },
                  ]}
                  style={{ marginBottom: spacing.lg }}
                />

                <Text style={styles.heading}>Login</Text>
                <Text style={styles.subheading}>Welcome back. Please sign in to continue.</Text>

                {/* The company you belong to -- resolves which organization this
                    login is for. Labelled "Company name" because that IS the
                    code for companies registered from now on (see
                    AuthService.generateUniqueCompanyCode); the backend strips
                    spaces and punctuation so "Acme Logistics" and
                    "ACMELOGISTICS" both resolve. */}
                <View style={styles.fieldRow}>
                  <Ionicons name="business-outline" size={18} color="rgba(255,255,255,0.85)" />
                  <TextInput
                    value={companyCode}
                    onChangeText={setCompanyCode}
                    placeholder="Company name"
                    placeholderTextColor="rgba(255,255,255,0.65)"
                    autoCapitalize="characters"
                    style={styles.input}
                  />
                </View>

                {/* Email */}
                <View style={styles.fieldRow}>
                  <Ionicons name="person-outline" size={18} color="rgba(255,255,255,0.85)" />
                  <TextInput
                    value={email}
                    onChangeText={setEmail}
                    placeholder="Email address"
                    placeholderTextColor="rgba(255,255,255,0.65)"
                    autoCapitalize="none"
                    keyboardType="email-address"
                    style={styles.input}
                  />
                </View>

                {/* Password */}
                <View style={styles.fieldRow}>
                  <Ionicons name="lock-closed-outline" size={18} color="rgba(255,255,255,0.85)" />
                  <TextInput
                    value={password}
                    onChangeText={setPassword}
                    placeholder="Password"
                    placeholderTextColor="rgba(255,255,255,0.65)"
                    secureTextEntry={!showPassword}
                    style={styles.input}
                  />
                  <Pressable onPress={() => setShowPassword((s) => !s)} hitSlop={8}>
                    <Ionicons
                      name={showPassword ? 'eye-outline' : 'eye-off-outline'}
                      size={18}
                      color="rgba(255,255,255,0.85)"
                    />
                  </Pressable>
                </View>

                {/* Remember me / Forgot password */}
                <View style={styles.rememberRow}>
                  <Pressable style={styles.remember} onPress={() => setRemember((r) => !r)}>
                    <View style={[styles.checkbox, remember && styles.checkboxOn]}>
                      {remember ? <Ionicons name="checkmark" size={14} color="#FFF" /> : null}
                    </View>
                    <Text style={styles.rememberText}>Remember me</Text>
                  </Pressable>
                  <Pressable onPress={() => navigation.navigate('ForgotPassword')} hitSlop={6}>
                    <Text style={styles.forgotText}>Forgot password?</Text>
                  </Pressable>
                </View>

                {/* Gradient login button */}
                <Pressable
                  onPress={onSubmit}
                  disabled={submitting}
                  style={({ pressed }) => [{ opacity: pressed || submitting ? 0.85 : 1 }]}
                >
                  <LinearGradient
                    colors={['#5ECFC9', '#1B8A82', '#0B4A47']}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={styles.loginBtn}
                  >
                    <Text style={styles.loginBtnText}>
                      {submitting ? 'Signing in...' : 'Login'}
                    </Text>
                  </LinearGradient>
                </Pressable>

                {/* Google sign-in -- verified server-side, see GoogleTokenService */}
                <Pressable
                  onPress={onGoogleLogin}
                  disabled={!request || googleSubmitting}
                  style={({ pressed }) => [
                    styles.googleBtn,
                    { opacity: pressed || googleSubmitting ? 0.85 : 1 },
                  ]}
                >
                  <Ionicons name="logo-google" size={18} color="#FFFFFF" />
                  <Text style={styles.googleBtnText}>
                    {googleSubmitting ? 'Signing in...' : 'Continue with Google'}
                  </Text>
                </Pressable>

                {/* Signup */}
                <View style={styles.signupRow}>
                  <Text style={styles.signupHint}>Don&apos;t have an account? </Text>
                  <Pressable onPress={() => navigation.navigate('Signup')} hitSlop={6}>
                    <Text style={styles.signupLink}>Signup</Text>
                  </Pressable>
                </View>

                {/* New company */}
                <View style={[styles.signupRow, styles.newCompanyRow]}>
                  <Text style={styles.signupHint}>Setting up VisiLog for your company? </Text>
                  <Pressable onPress={() => navigation.navigate('RegisterCompany')} hitSlop={6}>
                    <Text style={styles.signupLink}>Register your company</Text>
                  </Pressable>
                </View>
              </View>
            </BlurView>

            <Text style={styles.footer}>VisiLog 2.0 - Secure visitor management</Text>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  // Solid brand green -- replaced the decorative photo background so
  // the auth screens read as part of the branded app rather than a
  // stock image. Uses the emerald brand ink from theme/colors.ts.
  bg: { flex: 1, backgroundColor: '#0F3D2A' },
  safe: { flex: 1 },
  scroll: {
    flexGrow: 1,
    justifyContent: 'center',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.xxl,
  },

  // Card
  card: {
    borderRadius: radius.xl,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.35)',
  },
  cardInner: {
    padding: spacing.xl,
    // On Android BlurView is weaker, so we tint the inner panel too
    backgroundColor:
      Platform.OS === 'android' ? 'rgba(255,255,255,0.12)' : 'rgba(255,255,255,0.05)',
  },

  // Branding inside the card
  wordmark: {
    fontFamily: fonts.displayExtra,
    fontSize: 32,
    lineHeight: 40,
    color: '#FFFFFF',
    letterSpacing: -0.5,
    textAlign: 'center',
  },
  tagline: {
    fontFamily: fonts.medium,
    fontSize: 12,
    color: 'rgba(255,255,255,0.85)',
    textAlign: 'center',
    marginTop: 2,
    marginBottom: spacing.lg,
  },

  heading: {
    fontFamily: fonts.displayBold,
    fontSize: 26,
    color: '#FFFFFF',
    marginBottom: 4,
  },
  subheading: {
    fontFamily: fonts.regular,
    fontSize: 13,
    color: 'rgba(255,255,255,0.85)',
    marginBottom: spacing.lg,
  },

  // Form fields -- translucent so the glass shows through
  fieldRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.12)',
    borderColor: 'rgba(255,255,255,0.28)',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    height: 48,
    marginBottom: spacing.sm,
  },
  input: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 15,
    color: '#FFFFFF',
    marginHorizontal: 8,
    paddingVertical: 0,
  },

  // Remember me / Forgot password
  rememberRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginVertical: spacing.sm,
  },
  remember: { flexDirection: 'row', alignItems: 'center' },
  forgotText: {
    fontFamily: fonts.medium,
    fontSize: 13,
    color: '#FFFFFF',
    textDecorationLine: 'underline',
  },
  checkbox: {
    width: 18,
    height: 18,
    borderRadius: 5,
    borderWidth: 1.5,
    borderColor: 'rgba(255,255,255,0.85)',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 8,
  },
  checkboxOn: { backgroundColor: '#2E9E96', borderColor: '#2E9E96' },
  rememberText: { fontFamily: fonts.medium, fontSize: 13, color: '#FFFFFF' },

  // Login button
  loginBtn: {
    height: 50,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: spacing.sm,
  },
  loginBtnText: {
    fontFamily: fonts.bold,
    fontSize: 16,
    color: '#FFFFFF',
    letterSpacing: 0.3,
  },

  // Google button
  googleBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 48,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.35)',
    backgroundColor: 'rgba(255,255,255,0.10)',
    marginTop: spacing.sm,
    gap: 8,
  },
  googleBtnText: { fontFamily: fonts.medium, fontSize: 14, color: '#FFFFFF' },

  // Signup -- flexWrap so long copy ("Setting up VisiLog for your
  // company? Register your company") breaks onto its own centered line
  // on narrow phones instead of the two Text nodes bunching together.
  signupRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    marginTop: spacing.lg,
    paddingHorizontal: spacing.sm,
  },
  newCompanyRow: { marginTop: spacing.sm },
  signupHint: {
    fontFamily: fonts.regular,
    fontSize: 13,
    lineHeight: 20,
    color: 'rgba(255,255,255,0.85)',
    textAlign: 'center',
  },
  signupLink: { fontFamily: fonts.bold, fontSize: 13, lineHeight: 20, color: '#FFFFFF' },

  footer: {
    fontFamily: fonts.medium,
    fontSize: 11,
    color: 'rgba(255,255,255,0.75)',
    textAlign: 'center',
    marginTop: spacing.xl,
    letterSpacing: 0.5,
  },
});

'@
$path = Join-Path (Get-Location) 'src\screens\LoginScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/LoginScreen.tsx'

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
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { Text, Segmented } from '../components';
import { useAuth } from '../context/AuthContext';
import { fonts } from '../theme/typography';
import { spacing, radius } from '../theme/spacing';
import type { RootStackNavigation } from '../types/navigation';
import type { IoniconName } from '../types';

interface SignupScreenProps {
  navigation: RootStackNavigation;
}

// Signup uses the exact same background photo as Login, so the two
// pages feel like one continuous flow. The sign-in/register pill at
// the top mirrors Login's -- tapping "Sign in" here just goes back.
//
// Role isn't chosen here -- the backend matches `email` against the
// company's staff roster (that role) or falls back to visitor.
export default function SignupScreen({ navigation }: SignupScreenProps) {
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [companyCode, setCompanyCode] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const { signup } = useAuth();

  const onSubmit = async () => {
    if (!fullName.trim() || !email.trim() || !password || !companyCode.trim()) {
      Alert.alert('Almost there', 'Please fill in every field above.');
      return;
    }
    if (password.length < 8) {
      Alert.alert('Password too short', 'Your password must be at least 8 characters.');
      return;
    }
    if (password !== confirm) {
      Alert.alert("Passwords don't match", 'Please re-enter the same password twice.');
      return;
    }
    setSubmitting(true);
    const result = await signup(companyCode, email, password, fullName);
    setSubmitting(false);
    if (!result.ok) {
      Alert.alert('Signup failed', result.error);
      return;
    }
    // On success the root navigator will swap to the app stack.
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
            {/* Back chevron */}
            <Pressable onPress={() => navigation.goBack()} style={styles.back} hitSlop={8}>
              <Ionicons name="chevron-back" size={22} color="#FFFFFF" />
            </Pressable>

            <BlurView intensity={25} tint="light" style={styles.card}>
              <View style={styles.cardInner}>
                <Text style={styles.wordmark}>VisiLog</Text>

                <Segmented
                  value="register"
                  onChange={(v) => {
                    if (v === 'signin') navigation.goBack();
                  }}
                  options={[
                    { label: 'Sign in', value: 'signin' },
                    { label: 'Register', value: 'register' },
                  ]}
                  style={{ marginBottom: spacing.lg }}
                />

                <Text style={styles.heading}>Create account</Text>
                <Text style={styles.subheading}>Request access to the reception system.</Text>

                <Field
                  icon="business-outline"
                  placeholder="Company name"
                  value={companyCode}
                  onChangeText={setCompanyCode}
                  autoCapitalize="characters"
                />
                <Field
                  icon="person-outline"
                  placeholder="Full name"
                  value={fullName}
                  onChangeText={setFullName}
                />
                <Field
                  icon="mail-outline"
                  placeholder="Email address"
                  value={email}
                  onChangeText={setEmail}
                  autoCapitalize="none"
                  keyboardType="email-address"
                />
                <Field
                  icon="lock-closed-outline"
                  placeholder="Password"
                  value={password}
                  onChangeText={setPassword}
                  secureTextEntry
                />
                <Text style={styles.passwordHint}>Must be at least 8 characters.</Text>
                <Field
                  icon="shield-checkmark-outline"
                  placeholder="Confirm password"
                  value={confirm}
                  onChangeText={setConfirm}
                  secureTextEntry
                />

                <Pressable
                  onPress={onSubmit}
                  disabled={submitting}
                  style={({ pressed }) => [{ opacity: pressed || submitting ? 0.85 : 1 }]}
                >
                  <LinearGradient
                    colors={['#5ECFC9', '#1B8A82', '#0B4A47']}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={styles.signupBtn}
                  >
                    <Text style={styles.signupBtnText}>
                      {submitting ? 'Creating account...' : 'Create account'}
                    </Text>
                  </LinearGradient>
                </Pressable>

                <View style={styles.loginRow}>
                  <Text style={styles.loginHint}>Already have one? </Text>
                  <Pressable onPress={() => navigation.goBack()}>
                    <Text style={styles.loginLink}>Login</Text>
                  </Pressable>
                </View>
              </View>
            </BlurView>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </View>
  );
}

// Small internal field component to keep the JSX above readable. Local
// because it's only used on this screen.
function Field({
  icon,
  secureTextEntry,
  ...inputProps
}: { icon: IoniconName; secureTextEntry?: boolean } & React.ComponentProps<typeof TextInput>) {
  const [revealed, setRevealed] = useState(false);
  return (
    <View style={styles.fieldRow}>
      <Ionicons name={icon} size={18} color="rgba(255,255,255,0.85)" />
      <TextInput
        placeholderTextColor="rgba(255,255,255,0.65)"
        style={styles.input}
        secureTextEntry={secureTextEntry && !revealed}
        {...inputProps}
      />
      {secureTextEntry ? (
        <Pressable onPress={() => setRevealed((r) => !r)} hitSlop={8}>
          <Ionicons
            name={revealed ? 'eye-outline' : 'eye-off-outline'}
            size={18}
            color="rgba(255,255,255,0.85)"
          />
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  // Solid brand green -- replaced the decorative photo background so
  // the auth screens read as part of the branded app rather than a
  // stock image. Uses the emerald brand ink from theme/colors.ts.
  bg: { flex: 1, backgroundColor: '#0F3D2A' },
  safe: { flex: 1 },
  scroll: {
    flexGrow: 1,
    justifyContent: 'center',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.xxl,
  },

  back: { position: 'absolute', top: spacing.sm, left: spacing.sm, padding: 8, zIndex: 1 },

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

  wordmark: {
    fontFamily: fonts.displayExtra,
    fontSize: 28,
    lineHeight: 36,
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: spacing.md,
  },
  heading: { fontFamily: fonts.displayBold, fontSize: 24, color: '#FFFFFF' },
  subheading: {
    fontFamily: fonts.regular,
    fontSize: 13,
    color: 'rgba(255,255,255,0.85)',
    marginBottom: spacing.lg,
  },

  fieldRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.12)',
    borderColor: 'rgba(255,255,255,0.28)',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    height: 48,
    marginBottom: spacing.sm,
  },
  input: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 15,
    color: '#FFFFFF',
    marginHorizontal: 8,
    paddingVertical: 0,
  },
  passwordHint: {
    fontFamily: fonts.regular,
    fontSize: 11,
    color: 'rgba(255,255,255,0.7)',
    marginTop: -6,
    marginBottom: spacing.sm,
  },

  signupBtn: {
    height: 50,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: spacing.sm,
  },
  signupBtnText: { fontFamily: fonts.bold, fontSize: 16, color: '#FFFFFF', letterSpacing: 0.3 },

  loginRow: { flexDirection: 'row', justifyContent: 'center', marginTop: spacing.lg },
  loginHint: { fontFamily: fonts.regular, fontSize: 13, color: 'rgba(255,255,255,0.85)' },
  loginLink: { fontFamily: fonts.bold, fontSize: 13, color: '#FFFFFF' },
});

'@
$path = Join-Path (Get-Location) 'src\screens\SignupScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/SignupScreen.tsx'

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
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { Text } from '../components';
import { fonts } from '../theme/typography';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import type { RootStackNavigation } from '../types/navigation';

interface ForgotPasswordScreenProps {
  navigation: RootStackNavigation;
}

// ForgotPasswordScreen -- a two-step recovery flow: request a numeric
// code by email, then enter that code alongside a new password. Chose
// an emailed code over a clickable reset link specifically to avoid the
// custom-URI-scheme restrictions Google Sign-In ran into (see
// OAuthRedirectController) -- this needs no deep link at all.
export default function ForgotPasswordScreen({ navigation }: ForgotPasswordScreenProps) {
  const { forgotPassword, resetPassword } = useAuth();
  const [step, setStep] = useState<'request' | 'reset'>('request');
  const [companyCode, setCompanyCode] = useState('');
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  const onRequestCode = async () => {
    if (!companyCode.trim() || !email.trim()) {
      Alert.alert('Almost there', 'Enter your company code and email address.');
      return;
    }
    setSubmitting(true);
    const result = await forgotPassword(companyCode, email);
    setSubmitting(false);
    if (!result.ok) {
      Alert.alert('Could not send code', result.message);
      return;
    }
    Alert.alert('Check your email', result.message);
    setStep('reset');
  };

  const onResetPassword = async () => {
    if (!code.trim() || newPassword.length < 6) {
      Alert.alert(
        'Almost there',
        'Enter the code from your email and a password of at least 6 characters.',
      );
      return;
    }
    setSubmitting(true);
    const result = await resetPassword(companyCode, email, code, newPassword);
    setSubmitting(false);
    if (!result.ok) {
      Alert.alert('Could not reset password', result.message);
      return;
    }
    Alert.alert('Password reset', result.message, [
      { text: 'OK', onPress: () => navigation.navigate('Login') },
    ]);
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
                <Pressable
                  style={styles.backRow}
                  onPress={() => navigation.navigate('Login')}
                  hitSlop={8}
                >
                  <Ionicons name="chevron-back" size={18} color="#FFFFFF" />
                  <Text style={styles.backText}>Back to login</Text>
                </Pressable>

                <Text style={styles.heading}>
                  {step === 'request' ? 'Forgot password' : 'Enter reset code'}
                </Text>
                <Text style={styles.subheading}>
                  {step === 'request'
                    ? "Enter your company code and email -- we'll send you a reset code."
                    : `We sent a 6-digit code to ${email}. Enter it below with your new password.`}
                </Text>

                {step === 'request' ? (
                  <>
                    <View style={styles.fieldRow}>
                      <Ionicons name="business-outline" size={18} color="rgba(255,255,255,0.85)" />
                      <TextInput
                        value={companyCode}
                        onChangeText={setCompanyCode}
                        placeholder="Company name"
                        placeholderTextColor="rgba(255,255,255,0.65)"
                        autoCapitalize="characters"
                        style={styles.input}
                      />
                    </View>
                    <View style={styles.fieldRow}>
                      <Ionicons name="person-outline" size={18} color="rgba(255,255,255,0.85)" />
                      <TextInput
                        value={email}
                        onChangeText={setEmail}
                        placeholder="Email address"
                        placeholderTextColor="rgba(255,255,255,0.65)"
                        autoCapitalize="none"
                        keyboardType="email-address"
                        style={styles.input}
                      />
                    </View>

                    <Pressable
                      onPress={onRequestCode}
                      disabled={submitting}
                      style={({ pressed }) => [{ opacity: pressed || submitting ? 0.85 : 1 }]}
                    >
                      <LinearGradient
                        colors={['#5ECFC9', '#1B8A82', '#0B4A47']}
                        start={{ x: 0, y: 0 }}
                        end={{ x: 1, y: 1 }}
                        style={styles.actionBtn}
                      >
                        <Text style={styles.actionBtnText}>
                          {submitting ? 'Sending...' : 'Send reset code'}
                        </Text>
                      </LinearGradient>
                    </Pressable>
                  </>
                ) : (
                  <>
                    <View style={styles.fieldRow}>
                      <Ionicons name="keypad-outline" size={18} color="rgba(255,255,255,0.85)" />
                      <TextInput
                        value={code}
                        onChangeText={setCode}
                        placeholder="6-digit code"
                        placeholderTextColor="rgba(255,255,255,0.65)"
                        keyboardType="number-pad"
                        maxLength={6}
                        style={styles.input}
                      />
                    </View>
                    <View style={styles.fieldRow}>
                      <Ionicons
                        name="lock-closed-outline"
                        size={18}
                        color="rgba(255,255,255,0.85)"
                      />
                      <TextInput
                        value={newPassword}
                        onChangeText={setNewPassword}
                        placeholder="New password"
                        placeholderTextColor="rgba(255,255,255,0.65)"
                        secureTextEntry={!showPassword}
                        style={styles.input}
                      />
                      <Pressable onPress={() => setShowPassword((s) => !s)} hitSlop={8}>
                        <Ionicons
                          name={showPassword ? 'eye-outline' : 'eye-off-outline'}
                          size={18}
                          color="rgba(255,255,255,0.85)"
                        />
                      </Pressable>
                    </View>
                    <Text style={styles.hint}>At least 6 characters.</Text>

                    <Pressable
                      onPress={onResetPassword}
                      disabled={submitting}
                      style={({ pressed }) => [{ opacity: pressed || submitting ? 0.85 : 1 }]}
                    >
                      <LinearGradient
                        colors={['#5ECFC9', '#1B8A82', '#0B4A47']}
                        start={{ x: 0, y: 0 }}
                        end={{ x: 1, y: 1 }}
                        style={styles.actionBtn}
                      >
                        <Text style={styles.actionBtnText}>
                          {submitting ? 'Resetting...' : 'Reset password'}
                        </Text>
                      </LinearGradient>
                    </Pressable>

                    <Pressable
                      onPress={() => setStep('request')}
                      hitSlop={6}
                      style={{ marginTop: spacing.md }}
                    >
                      <Text style={styles.resendText}>Didn&apos;t get a code? Send again</Text>
                    </Pressable>
                  </>
                )}
              </View>
            </BlurView>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  // Solid brand green -- replaced the decorative photo background so
  // the auth screens read as part of the branded app rather than a
  // stock image. Uses the emerald brand ink from theme/colors.ts.
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

  backRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.lg },
  backText: { fontFamily: fonts.medium, fontSize: 13, color: '#FFFFFF', marginLeft: 2 },

  heading: {
    fontFamily: fonts.displayBold,
    fontSize: 24,
    color: '#FFFFFF',
    marginBottom: 4,
  },
  subheading: {
    fontFamily: fonts.regular,
    fontSize: 13,
    lineHeight: 19,
    color: 'rgba(255,255,255,0.85)',
    marginBottom: spacing.lg,
  },

  fieldRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.12)',
    borderColor: 'rgba(255,255,255,0.28)',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    height: 48,
    marginBottom: spacing.sm,
  },
  input: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 15,
    color: '#FFFFFF',
    marginHorizontal: 8,
    paddingVertical: 0,
  },
  hint: {
    fontFamily: fonts.regular,
    fontSize: 11,
    color: 'rgba(255,255,255,0.7)',
    marginBottom: spacing.sm,
  },

  actionBtn: {
    height: 50,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: spacing.sm,
  },
  actionBtnText: {
    fontFamily: fonts.bold,
    fontSize: 16,
    color: '#FFFFFF',
    letterSpacing: 0.3,
  },

  resendText: {
    fontFamily: fonts.medium,
    fontSize: 13,
    color: '#FFFFFF',
    textAlign: 'center',
    textDecorationLine: 'underline',
  },
});

'@
$path = Join-Path (Get-Location) 'src\screens\ForgotPasswordScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/ForgotPasswordScreen.tsx'

$content = @'
import React, { useState } from 'react';
import { RefreshControl, type RefreshControlProps } from 'react-native';
import { useData } from '../context/DataContext';
import { useTheme } from '../theme/ThemeContext';

// Pull-to-refresh, wired to reload everything from the API.
//
// Data in this app goes stale constantly and invisibly: a visitor is
// admitted at reception while you're looking at the appointments list,
// a colleague books the room you were about to take. Screens refetch
// when focused, but that does nothing while you're already sitting on
// one -- and "pull down to reload" is the gesture every phone user
// already reaches for.
//
// Two shapes for the two kinds of screen this app has:
//   useRefreshState()   -> { refreshing, onRefresh } for anything that
//                          needs the raw values (Screen, or a list that
//                          also does something of its own).
//   usePullToRefresh()  -> a ready-made <RefreshControl>, for the
//                          screens that render their own FlatList and
//                          just need to drop it into refreshControl.
export function useRefreshState(): { refreshing: boolean; onRefresh: () => void } {
  const { refreshAll } = useData();
  const [refreshing, setRefreshing] = useState(false);

  const onRefresh = (): void => {
    if (refreshing) return;
    setRefreshing(true);
    refreshAll().finally(() => setRefreshing(false));
  };

  return { refreshing, onRefresh };
}

// Typed as ReactElement<RefreshControlProps> rather than a bare
// ReactElement: FlatList/SectionList's refreshControl prop demands that
// exact element type, and a looser return makes every call site fail to
// typecheck.
export function usePullToRefresh(): React.ReactElement<RefreshControlProps> {
  const { colors } = useTheme();
  const { refreshing, onRefresh } = useRefreshState();
  return <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={colors.primary} />;
}

'@
$path = Join-Path (Get-Location) 'src\components\usePullToRefresh.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/usePullToRefresh.tsx'

$content = @'
import React, { type ReactNode } from 'react';
import {
  View,
  Image,
  ScrollView,
  StyleSheet,
  KeyboardAvoidingView,
  RefreshControl,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import { SafeAreaView, type Edge } from 'react-native-safe-area-context';
import { spacing } from '../theme/spacing';
import { useTheme } from '../theme/ThemeContext';
import { useAuth } from '../context/AuthContext';
import { useRefreshState } from './usePullToRefresh';

interface ScreenProps {
  children?: ReactNode;
  scroll?: boolean;
  padded?: boolean;
  style?: StyleProp<ViewStyle>;
  contentStyle?: StyleProp<ViewStyle>;
  edges?: Edge[];
  // Pull-to-refresh. Optional: leave both out and the screen still
  // pulls to refresh, reloading everything from the API (see below).
  // Pass them to take over -- a screen that has its own local state to
  // reset alongside the reload needs to drive it itself.
  //
  // Only applies to the scroll={true} (default) variant; scroll={false}
  // screens render their own FlatList and pass usePullToRefresh() into
  // its refreshControl prop directly.
  refreshing?: boolean;
  onRefresh?: () => void;
}

// A big, faint, diagonal brand mark behind every screen's content --
// purely decorative (pointerEvents="none" so it never intercepts
// taps). Shows the signed-in org's own uploaded logo once they've set
// one (Company Setup > Branding), so a company's app actually looks
// like their own; falls back to the static VisiLog mark before
// sign-in and for orgs that haven't uploaded a logo yet. Sits under
// the ScrollView/View as an absolutely positioned sibling so it never
// scrolls with the content.
function Watermark() {
  const { organization } = useAuth();
  return (
    <View style={styles.watermarkWrap} pointerEvents="none">
      <Image
        source={
          organization?.logoUrl ? { uri: organization.logoUrl } : require('../../assets/logo.png')
        }
        style={styles.watermarkImage}
        resizeMode="contain"
      />
    </View>
  );
}

// Standard page shell: respects the notch/home-indicator, paints the app
// background, and gives you a scroll view by default. Set scroll={false}
// for screens that manage their own list or need vertical centring.
//
// Wrapped in KeyboardAvoidingView so forms (Register visitor, Add
// employee, Book a visit, etc.) don't get their lower fields hidden
// behind the on-screen keyboard -- every screen built on Screen gets
// this for free instead of each one having to wire it up itself.
export default function Screen({
  children,
  scroll = true,
  padded = true,
  style,
  contentStyle,
  edges = ['top'],
  refreshing,
  onRefresh,
}: ScreenProps) {
  const { colors: themeColors } = useTheme();
  // Every scrolling screen gets pull-to-refresh for free. Doing it here
  // rather than per screen is the only way "every screen" stays true --
  // wiring it up individually meant 7 of 29 screens had it and the rest
  // silently didn't, with no way to tell which was which from the UI.
  const fallback = useRefreshState();
  const handleRefresh = onRefresh ?? fallback.onRefresh;
  const isRefreshing = onRefresh ? !!refreshing : fallback.refreshing;
  if (scroll) {
    return (
      <SafeAreaView
        style={[styles.safe, { backgroundColor: themeColors.background }, style]}
        edges={edges}
      >
        <Watermark />
        <KeyboardAvoidingView style={styles.flex} behavior="padding">
          <ScrollView
            contentContainerStyle={[padded && styles.padded, contentStyle]}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
            refreshControl={
              <RefreshControl
                refreshing={isRefreshing}
                onRefresh={handleRefresh}
                tintColor={themeColors.primary}
              />
            }
          >
            {children}
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    );
  }
  return (
    <SafeAreaView
      style={[styles.safe, { backgroundColor: themeColors.background }, style]}
      edges={edges}
    >
      <Watermark />
      <KeyboardAvoidingView style={styles.flex} behavior="padding">
        <View style={[styles.flex, padded && styles.padded, contentStyle]}>{children}</View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  flex: { flex: 1 },
  padded: { padding: spacing.md, paddingBottom: spacing.xxxl },
  watermarkWrap: {
    ...StyleSheet.absoluteFillObject,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  watermarkImage: {
    width: '180%',
    height: '60%',
    opacity: 0.05,
    transform: [{ rotate: '-25deg' }],
  },
});

'@
$path = Join-Path (Get-Location) 'src\components\Screen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/Screen.tsx'

$content = @'
import React, { useMemo, useState } from 'react';
import { View, FlatList, StyleSheet, Pressable, Linking } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen,
  Header,
  Input,
  Text,
  Card,
  EmptyState,
  Avatar,
  CsvImportModal,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import type { RootStackNavigation } from '../types/navigation';
import type { Employee, EmployeeInput, Role } from '../types';
import { usePullToRefresh } from '../components/usePullToRefresh';

interface DirectoryScreenProps {
  navigation: RootStackNavigation;
}

// Accepts a wide range of header spellings so a real HR export (which
// almost never matches a fixed schema) doesn't need renaming first --
// "code"/"employee code"/"employeeid"/"staff id" all work for the id
// column, and FirstName+LastName combine into one name if there's no
// single "name" column at all.
function mapCsvRow(record: Record<string, string>): EmployeeInput {
  const firstName = record['firstname'] || record['first name'] || '';
  const lastName = record['lastname'] || record['last name'] || '';
  const combinedName = [firstName, lastName].filter(Boolean).join(' ');

  return {
    employeeId:
      record['code'] ||
      record['employee code'] ||
      record['employeecode'] ||
      record['employeeid'] ||
      record['employee id'] ||
      record['staff id'] ||
      record['id'] ||
      '',
    name: record['name'] || record['full name'] || record['fullname'] || combinedName || '',
    department: record['department'] || '',
    phone:
      record['phone'] || record['phone number'] || record['phonenumber'] || record['mobile'] || '',
    email: record['email'] || record['email address'] || record['emailaddress'] || '',
    role: (record['role'] || 'employee').toLowerCase() as Role,
  };
}

// DirectoryScreen -- the Phone Book.
// Lists every staff member; tap a row to open their detail page; tap
// the phone icon to dial straight from the device.
export default function DirectoryScreen({ navigation }: DirectoryScreenProps) {
  const refreshControl = usePullToRefresh();
  const { employees, bulkImportEmployees } = useData();
  const [query, setQuery] = useState('');
  const [importVisible, setImportVisible] = useState(false);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return employees;
    return employees.filter(
      (e) =>
        e.name.toLowerCase().includes(q) ||
        e.department.toLowerCase().includes(q) ||
        e.phone.includes(q),
    );
  }, [employees, query]);

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Directory"
          subtitle={`${employees.length} employees`}
          onBackPress={() => navigation.goBack()}
          rightActions={[
            { icon: 'document-attach-outline', onPress: () => setImportVisible(true) },
            { icon: 'person-add-outline', onPress: () => navigation.navigate('AddEmployee') },
          ]}
        />
        <Input
          placeholder="Search name or department"
          value={query}
          onChangeText={setQuery}
          icon="search"
        />
      </View>

      <FlatList
        refreshControl={refreshControl}
        data={filtered}
        keyExtractor={(e) => e.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.xs }} />}
        ListEmptyComponent={
          <EmptyState
            icon="people-outline"
            title="No matches"
            message="Try a different name or department."
          />
        }
        renderItem={({ item }) => (
          <DirectoryRow
            employee={item}
            onPress={() => navigation.navigate('EmployeeDetail', { employeeId: item.id })}
            onCall={() => Linking.openURL(`tel:${item.phone}`)}
          />
        )}
      />

      <CsvImportModal
        visible={importVisible}
        onClose={() => setImportVisible(false)}
        title="Import staff"
        columnsHint="Columns: code, name, department, phone, email, role (employee/receptionist/manager)"
        mapRow={mapCsvRow}
        onImport={bulkImportEmployees}
      />
    </Screen>
  );
}

function DirectoryRow({
  employee,
  onPress,
  onCall,
}: {
  employee: Employee;
  onPress: () => void;
  onCall: () => void;
}) {
  const { colors } = useTheme();
  return (
    <Card padded={false} onPress={onPress} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <Avatar name={employee.name} size={44} />
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold" numberOfLines={1}>
            {employee.name}
          </Text>
          <Text variant="caption" color={colors.textSecondary} numberOfLines={1}>
            {employee.department}
          </Text>
        </View>
        <Pressable
          onPress={onCall}
          hitSlop={8}
          style={[styles.callBtn, { backgroundColor: colors.primarySurface }]}
        >
          <Ionicons name="call" size={18} color={colors.primary} />
        </Pressable>
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  row: { flexDirection: 'row', alignItems: 'center', padding: spacing.sm },
  callBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

'@
$path = Join-Path (Get-Location) 'src\screens\DirectoryScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/DirectoryScreen.tsx'

$content = @'
import React, { useState } from 'react';
import { View, StyleSheet, FlatList } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen,
  Header,
  Text,
  Card,
  Badge,
  EmptyState,
  Avatar,
  StatTile,
  ExportModal,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtTime, fmtDateTime, fmtRelative } from '../data/format';
import {
  toCsv,
  toHtmlTable,
  exportCsvFile,
  exportPdfFile,
  type ExportColumn,
} from '../data/export';
import type { RootStackNavigation } from '../types/navigation';
import type { ClockRecord, ClockType, Employee } from '../types';
import { usePullToRefresh } from '../components/usePullToRefresh';

interface AttendanceScreenProps {
  navigation: RootStackNavigation;
}

// AttendanceScreen -- the clock-in/out ledger, presented as a tap log.
// (There's no separate NFC-tap-log concept in the real backend -- this
// reads the same shared clockRecords ledger as the Employee/Receptionist
// "on the clock" cards and ManagerClockInsScreen.)
export default function AttendanceScreen({ navigation }: AttendanceScreenProps) {
  const refreshControl = usePullToRefresh();
  const { clockRecords, employeeById } = useData();
  const [exporting, setExporting] = useState(false);

  const sorted = [...clockRecords].sort(
    (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime(),
  );

  const exportColumns: ExportColumn<ClockRecord>[] = [
    { header: 'Employee', get: (t) => employeeById(t.employeeId)?.name || 'Unknown' },
    { header: 'Department', get: (t) => employeeById(t.employeeId)?.department || '' },
    { header: 'Type', get: (t) => (t.type === 'in' ? 'Tap in' : 'Tap out') },
    { header: 'Time', get: (t) => fmtDateTime(t.timestamp) },
  ];
  const onExportCsv = () =>
    exportCsvFile(`attendance-${Date.now()}.csv`, toCsv(sorted, exportColumns));
  const onExportPdf = () =>
    exportPdfFile(
      `attendance-${Date.now()}.pdf`,
      toHtmlTable('Attendance log', sorted, exportColumns),
    );

  // Stat: how many distinct employees are currently signed in (based on
  // their last record of the day being 'in').
  const onsiteCount = (() => {
    const last: Record<string, ClockType> = {};
    sorted.forEach((t) => {
      if (!last[t.employeeId]) last[t.employeeId] = t.type;
    });
    return Object.values(last).filter((t) => t === 'in').length;
  })();

  const lateCount = sorted.filter((t) => {
    if (t.type !== 'in') return false;
    const d = new Date(t.timestamp);
    return d.getHours() > 8 || (d.getHours() === 8 && d.getMinutes() > 30);
  }).length;

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Attendance"
          subtitle="Clock-in/out log & punctuality"
          rightActions={[
            { icon: 'download-outline', onPress: () => setExporting(true) },
            {
              icon: 'time-outline',
              onPress: () => navigation.navigate('History', { tab: 'clock' }),
            },
            { icon: 'close', onPress: () => navigation.goBack() },
          ]}
        />
        <View style={{ flexDirection: 'row' }}>
          <StatTile icon="people" tint="primary" label="Employees on-site" value={onsiteCount} />
          <View style={{ width: spacing.sm }} />
          <StatTile icon="alarm" tint="pending" label="Late arrivals" value={lateCount} />
        </View>
      </View>

      <FlatList
        refreshControl={refreshControl}
        data={sorted}
        keyExtractor={(t) => t.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.xs }} />}
        ListEmptyComponent={
          <EmptyState
            icon="card-outline"
            title="No clock records yet"
            message="Clock-in/out activity will appear here as it happens."
          />
        }
        renderItem={({ item }) => <TapRow tap={item} employee={employeeById(item.employeeId)} />}
      />

      <ExportModal
        visible={exporting}
        title="Export attendance log"
        onClose={() => setExporting(false)}
        onExportCsv={onExportCsv}
        onExportPdf={onExportPdf}
      />
    </Screen>
  );
}

function TapRow({ tap, employee }: { tap: ClockRecord; employee?: Employee }) {
  const { colors } = useTheme();
  const isIn = tap.type === 'in';
  return (
    <Card padded={false} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <Avatar name={employee?.name || 'Unknown'} size={40} />
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold" numberOfLines={1}>
            {employee?.name || 'Unknown employee'}
          </Text>
          <Text variant="caption" color={colors.textSecondary}>
            {employee?.department || ''}
          </Text>
        </View>
        <View style={{ alignItems: 'flex-end' }}>
          <Badge
            label={isIn ? 'Tap in' : 'Tap out'}
            status={isIn ? 'success' : 'neutral'}
            size="sm"
          />
          <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
            {fmtTime(tap.timestamp)} - {fmtRelative(tap.timestamp)}
          </Text>
        </View>
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.md, paddingBottom: spacing.huge },
  row: { flexDirection: 'row', alignItems: 'center', padding: spacing.sm },
});

'@
$path = Join-Path (Get-Location) 'src\screens\AttendanceScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/AttendanceScreen.tsx'

$content = @'
import React, { useCallback, useState } from 'react';
import {
  View,
  FlatList,
  Pressable,
  StyleSheet,
  Modal,
  TextInput,
  KeyboardAvoidingView,
  Alert,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Button, EmptyState } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtRelative } from '../data/format';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type { AppNotification, IoniconName, NotificationType, RoomBookingResponse } from '../types';
import { usePullToRefresh } from '../components/usePullToRefresh';

// One icon per notification type -- anything not listed (shouldn't
// happen, but keeps this forward-compatible with a type this build
// doesn't know about yet) falls back to a plain bell.
const NOTIFICATION_ICONS: Record<NotificationType, IoniconName> = {
  meeting_invite: 'calendar-outline',
  meeting_declined: 'close-circle-outline',
  visit_admitted: 'card-outline',
  visit_rejected: 'close-circle-outline',
  visit_checked_out: 'exit-outline',
  appointment_requested: 'person-add-outline',
  appointment_rescheduled: 'swap-horizontal-outline',
  call_logged: 'call-outline',
  participant_absent: 'close-circle-outline',
};

interface NotificationsScreenProps {
  navigation: RootStackNavigation;
}

// NotificationsScreen -- in-app alerts (meeting invites, and an
// organiser being told someone declined). Reached from the bell icon
// on the Home header. There's no push/SMS delivery in this build, so
// this list (fetched on focus) is the only place these show up -- see
// NotificationService on the backend.
export default function NotificationsScreen({ navigation }: NotificationsScreenProps) {
  const refreshControl = usePullToRefresh();
  const { user } = useAuth();
  const {
    notifications,
    refreshNotifications,
    markNotificationRead,
    roomBookings,
    respondToMeeting,
  } = useData();
  const [refreshing, setRefreshing] = useState(false);
  const [declining, setDeclining] = useState<AppNotification | null>(null);

  useFocusEffect(
    useCallback(() => {
      refreshNotifications();
    }, []),
  );

  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshNotifications();
    } finally {
      setRefreshing(false);
    }
  };

  const sorted = [...notifications].sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
  );

  // A participant's own response row for the meeting a notification
  // points at -- undefined once the organiser sees it (they don't get
  // a response row for their own meeting) or for non-invite types.
  const myResponseFor = (n: AppNotification): RoomBookingResponse | undefined => {
    if (n.type !== 'meeting_invite' || !n.relatedId || !user?.employeeId) return undefined;
    const booking = roomBookings.find((b) => b.id === n.relatedId);
    return booking?.responses.find((r) => r.employeeId === user.employeeId);
  };

  const onAcknowledge = async (n: AppNotification) => {
    if (!n.relatedId) return;
    try {
      await respondToMeeting(n.relatedId, 'acknowledged');
      markNotificationRead(n.id);
    } catch (err) {
      Alert.alert(
        'Could not respond',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
    }
  };

  const onConfirmDecline = async (reason: string) => {
    if (!declining?.relatedId) return;
    try {
      await respondToMeeting(declining.relatedId, 'declined', reason);
      markNotificationRead(declining.id);
      setDeclining(null);
    } catch (err) {
      Alert.alert(
        'Could not decline',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
    }
  };

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Notifications"
          subtitle={sorted.length ? `${sorted.length} total` : undefined}
          onBackPress={() => navigation.goBack()}
        />
      </View>

      <FlatList
        refreshControl={refreshControl}
        data={sorted}
        keyExtractor={(n) => n.id}
        contentContainerStyle={styles.list}
        refreshing={refreshing}
        onRefresh={onRefresh}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="notifications-outline"
            title="No notifications yet"
            message="Meeting invites and other alerts will show up here."
          />
        }
        renderItem={({ item }) => (
          <NotificationRow
            notification={item}
            myResponse={myResponseFor(item)}
            onPress={() => markNotificationRead(item.id)}
            onAcknowledge={() => onAcknowledge(item)}
            onDecline={() => setDeclining(item)}
          />
        )}
      />

      <DeclineReasonModal
        visible={!!declining}
        onCancel={() => setDeclining(null)}
        onConfirm={onConfirmDecline}
      />
    </Screen>
  );
}

function NotificationRow({
  notification,
  myResponse,
  onPress,
  onAcknowledge,
  onDecline,
}: {
  notification: AppNotification;
  myResponse: RoomBookingResponse | undefined;
  onPress: () => void;
  onAcknowledge: () => void;
  onDecline: () => void;
}) {
  const { colors: themeColors } = useTheme();
  const canRespond = notification.type === 'meeting_invite' && myResponse?.status === 'pending';

  return (
    <Pressable onPress={onPress} disabled={notification.read}>
      <Card padded={false} style={{ marginHorizontal: spacing.md }}>
        <View style={styles.row}>
          <View style={[styles.iconWrap, { backgroundColor: themeColors.primarySurface }]}>
            <Ionicons
              name={NOTIFICATION_ICONS[notification.type] || 'notifications-outline'}
              size={18}
              color={themeColors.primary}
            />
          </View>
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <View style={styles.rowTop}>
              <Text variant="bodySemibold" numberOfLines={1}>
                {notification.title}
              </Text>
              {!notification.read ? (
                <View style={[styles.unreadDot, { backgroundColor: themeColors.palette.red600 }]} />
              ) : null}
            </View>
            <Text variant="body" color={themeColors.textSecondary}>
              {notification.body}
            </Text>
            <Text variant="caption" color={themeColors.textMuted} style={{ marginTop: 2 }}>
              {fmtRelative(notification.createdAt)}
            </Text>

            {canRespond ? (
              <View style={styles.actionRow}>
                <Button
                  label="Seen it"
                  icon="checkmark-circle-outline"
                  variant="secondary"
                  size="sm"
                  onPress={onAcknowledge}
                  style={{ flex: 1, marginRight: spacing.xs }}
                />
                <Button
                  label="Can't make it"
                  icon="close-circle-outline"
                  variant="secondary"
                  size="sm"
                  onPress={onDecline}
                  style={{ flex: 1, marginLeft: spacing.xs }}
                />
              </View>
            ) : myResponse?.status === 'acknowledged' ? (
              <View style={styles.respondedRow}>
                <Ionicons name="checkmark-circle" size={14} color={themeColors.primary} />
                <Text variant="caption" color={themeColors.primary} style={{ marginLeft: 4 }}>
                  You said you've seen this
                </Text>
              </View>
            ) : myResponse?.status === 'declined' ? (
              <View style={styles.respondedRow}>
                <Ionicons name="close-circle" size={14} color={themeColors.status.rejected.solid} />
                <Text
                  variant="caption"
                  color={themeColors.status.rejected.solid}
                  style={{ marginLeft: 4 }}
                >
                  You declined
                </Text>
              </View>
            ) : null}
          </View>
        </View>
      </Card>
    </Pressable>
  );
}

// A reason is required to decline (per RoomBookingService.respond),
// and Android has no built-in Alert.prompt, so this is a small custom
// modal -- same pattern as RescheduleModal's reason field.
function DeclineReasonModal({
  visible,
  onCancel,
  onConfirm,
}: {
  visible: boolean;
  onCancel: () => void;
  onConfirm: (reason: string) => void;
}) {
  const { colors } = useTheme();
  const [reason, setReason] = useState('');

  const onSubmit = () => {
    if (!reason.trim()) {
      Alert.alert('Almost there', "Let the organiser know why you can't make it.");
      return;
    }
    onConfirm(reason.trim());
    setReason('');
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onCancel}>
      <KeyboardAvoidingView style={modalStyles.wrap} behavior="padding">
        <View style={[modalStyles.card, { backgroundColor: colors.surface }]}>
          <Text variant="h3">Can't make it?</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            Let the organiser know why -- they'll see this right away.
          </Text>
          <TextInput
            value={reason}
            onChangeText={setReason}
            placeholder="e.g. I have another commitment that day"
            placeholderTextColor={colors.textMuted}
            style={[modalStyles.input, { borderColor: colors.border, color: colors.textPrimary }]}
            multiline
          />
          <View style={modalStyles.row}>
            <Pressable
              onPress={onCancel}
              style={[modalStyles.btn, { backgroundColor: colors.surfaceAlt }]}
            >
              <Text variant="bodySemibold" color={colors.textSecondary}>
                Cancel
              </Text>
            </Pressable>
            <Pressable
              onPress={onSubmit}
              style={[modalStyles.btn, { backgroundColor: colors.brand }]}
            >
              <Text variant="bodySemibold" color={colors.textInverse}>
                Send
              </Text>
            </Pressable>
          </View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  row: { flexDirection: 'row', alignItems: 'flex-start', padding: spacing.md },
  iconWrap: {
    width: 40,
    height: 40,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rowTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: 8 },
  unreadDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  actionRow: { flexDirection: 'row', marginTop: spacing.sm },
  respondedRow: { flexDirection: 'row', alignItems: 'center', marginTop: spacing.xs },
});

const modalStyles = StyleSheet.create({
  wrap: {
    flex: 1,
    backgroundColor: 'rgba(10,42,29,0.55)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.lg,
  },
  card: {
    width: '100%',
    maxWidth: 360,
    borderRadius: radius.lg,
    padding: spacing.lg,
  },
  input: {
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    paddingVertical: 10,
    minHeight: 80,
    textAlignVertical: 'top',
    fontFamily: fonts.regular,
    fontSize: 14,
  },
  row: { flexDirection: 'row', marginTop: spacing.md, gap: spacing.sm },
  btn: {
    flex: 1,
    height: 44,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

'@
$path = Join-Path (Get-Location) 'src\screens\NotificationsScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/NotificationsScreen.tsx'

$content = @'
import React, { useMemo, useState } from 'react';
import { View, StyleSheet, FlatList, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen,
  Header,
  Text,
  Card,
  Badge,
  Segmented,
  EmptyState,
  Avatar,
  Button,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useData } from '../context/DataContext';
import { fmtDate } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';
import type { NfcCard as NfcCardType } from '../types';
import { usePullToRefresh } from '../components/usePullToRefresh';

interface NFCCardsScreenProps {
  navigation: RootStackNavigation;
}

type NfcCardFilter = 'active' | 'revoked' | 'all';

// NFCCardsScreen -- list of virtual NFC cards.
// Per the VisiLog 2.0 spec: each card has a holder, an issuance date,
// an expiry, and a status ('active' | 'revoked'). Receptionists can
// revoke (or in this demo, "rotate") a card.
export default function NFCCardsScreen({ navigation }: NFCCardsScreenProps) {
  const refreshControl = usePullToRefresh();
  const { nfcCards, employeeById } = useData();
  const [filter, setFilter] = useState<NfcCardFilter>('active');

  const list = useMemo(() => {
    return nfcCards
      .filter((c) => filter === 'all' || c.status === filter)
      .map((c) => {
        let holder;
        if (c.holderType === 'employee') holder = employeeById(c.holderId)?.name || 'Unknown';
        else holder = `Visitor ${c.holderId}`;
        return { ...c, holderName: holder };
      });
  }, [nfcCards, filter, employeeById]);

  const onRevoke = (card: NfcCardType) => {
    Alert.alert('Revoke NFC card?', `Card ${card.tokenHash} will no longer grant access.`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Revoke',
        style: 'destructive',
        onPress: () => {
          Alert.alert('Demo only', 'Card revocation hits the NFC service in production.');
        },
      },
    ]);
  };

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="NFC Cards"
          subtitle="Issued credentials & access tokens"
          rightIcon="add"
          onRightPress={() => Alert.alert('Issue card', 'Card issuance is a demo placeholder.')}
        />
        <Segmented
          value={filter}
          onChange={setFilter}
          options={[
            { label: 'Active', value: 'active' },
            { label: 'Revoked', value: 'revoked' },
            { label: 'All', value: 'all' },
          ]}
        />
      </View>

      <FlatList
        refreshControl={refreshControl}
        data={list}
        keyExtractor={(c) => c.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="card-outline"
            title="No cards here"
            message="Issued NFC cards will appear in this list."
          />
        }
        renderItem={({ item }) => <NfcCard card={item} onRevoke={() => onRevoke(item)} />}
      />
    </Screen>
  );
}

function NfcCard({
  card,
  onRevoke,
}: {
  card: NfcCardType & { holderName: string };
  onRevoke: () => void;
}) {
  const { colors } = useTheme();
  const isActive = card.status === 'active';
  return (
    <Card accent={isActive ? 'onsite' : 'rejected'} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.cardHead}>
        <View
          style={[
            styles.chip,
            { backgroundColor: isActive ? colors.primarySurface : colors.status.rejected.bg },
          ]}
        >
          <Ionicons
            name="card"
            size={20}
            color={isActive ? colors.primary : colors.status.rejected.solid}
          />
        </View>
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold">{card.holderName}</Text>
          <Text variant="caption" color={colors.textSecondary}>
            {card.holderType === 'employee' ? 'Employee credential' : 'Visitor pass'}
          </Text>
        </View>
        <Badge label={card.status} status={isActive ? 'success' : 'rejected'} size="sm" />
      </View>

      <View style={[styles.tokenRow, { backgroundColor: colors.surfaceAlt }]}>
        <Text variant="caption" color={colors.textMuted}>
          Token
        </Text>
        <Text style={[styles.token, { color: colors.brand }]}>{card.tokenHash}</Text>
      </View>

      <View style={styles.dateRow}>
        <View style={{ flex: 1 }}>
          <Text variant="caption" color={colors.textMuted}>
            Issued
          </Text>
          <Text variant="bodyMd">{fmtDate(card.issuedAt)}</Text>
        </View>
        <View style={{ flex: 1 }}>
          <Text variant="caption" color={colors.textMuted}>
            Expires
          </Text>
          <Text variant="bodyMd">{fmtDate(card.expiresAt)}</Text>
        </View>
      </View>

      {isActive && (
        <Button
          label="Revoke card"
          variant="secondary"
          icon="ban-outline"
          onPress={onRevoke}
          style={{ marginTop: spacing.sm }}
        />
      )}
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  cardHead: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.sm },
  chip: {
    width: 44,
    height: 44,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  tokenRow: {
    borderRadius: radius.sm,
    padding: spacing.sm,
    marginBottom: spacing.sm,
  },
  token: { fontFamily: fonts.semibold, fontSize: 16, letterSpacing: 1 },
  dateRow: { flexDirection: 'row', gap: spacing.md },
});

'@
$path = Join-Path (Get-Location) 'src\screens\NFCCardsScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/NFCCardsScreen.tsx'

$content = @'
import React, { useState } from 'react';
import { View, Image, FlatList, StyleSheet, Alert, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import {
  Screen,
  Header,
  Text,
  Card,
  Button,
  Input,
  EmptyState,
  CsvImportModal,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type { MeetingRoom, MeetingRoomInput } from '../types';
import { usePullToRefresh } from '../components/usePullToRefresh';

interface MeetingRoomsScreenProps {
  navigation: RootStackNavigation;
}

// Same idea as DirectoryScreen's mapCsvRow -- a real spreadsheet export
// rarely matches a fixed schema, so this accepts a range of common
// header spellings instead of only the exact literal ones.
function mapCsvRow(record: Record<string, string>): MeetingRoomInput {
  return {
    name: record['name'] || record['room name'] || record['roomname'] || record['room'] || '',
    capacity: record['capacity'] || record['seats'] || record['size'] || '',
    floor: record['floor'] || record['level'] || '',
    photoUrl: null,
    description: record['description'] || record['directions'] || record['notes'] || '',
  };
}

// MeetingRoomsScreen -- Company Setup > meeting rooms (manager only).
// The rooms managed here are exactly what BookMeetingForm and
// AppointmentsScreen's "Meeting Rooms" tab draw from.
export default function MeetingRoomsScreen({ navigation }: MeetingRoomsScreenProps) {
  const refreshControl = usePullToRefresh();
  const { colors } = useTheme();
  const { meetingRooms, addMeetingRoom, bulkImportMeetingRooms, removeMeetingRoom } = useData();

  const [name, setName] = useState('');
  const [capacity, setCapacity] = useState('');
  const [floor, setFloor] = useState('');
  const [description, setDescription] = useState('');
  const [photoUrl, setPhotoUrl] = useState('');
  const [pickingPhoto, setPickingPhoto] = useState(false);
  const [adding, setAdding] = useState(false);
  const [importVisible, setImportVisible] = useState(false);

  const onPickPhoto = async () => {
    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) {
      Alert.alert('Permission needed', 'Allow photo library access to add a room photo.');
      return;
    }
    setPickingPhoto(true);
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ['images'],
        allowsEditing: true,
        aspect: [4, 3],
        quality: 0.6,
        base64: true,
      });
      if (result.canceled) return;
      const asset = result.assets[0];
      if (!asset.base64) {
        Alert.alert('Could not read image', 'Please try a different photo.');
        return;
      }
      setPhotoUrl(`data:${asset.mimeType || 'image/jpeg'};base64,${asset.base64}`);
    } finally {
      setPickingPhoto(false);
    }
  };

  const onAdd = async () => {
    if (!name.trim()) {
      Alert.alert('Almost there', 'Give the room a name.');
      return;
    }
    setAdding(true);
    try {
      await addMeetingRoom({
        name: name.trim(),
        capacity,
        floor: floor.trim(),
        photoUrl: photoUrl || null,
        description: description.trim() || null,
      });
      setName('');
      setCapacity('');
      setFloor('');
      setPhotoUrl('');
      setDescription('');
    } catch (err) {
      Alert.alert(
        'Could not add room',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
    } finally {
      setAdding(false);
    }
  };

  const onRemove = (room: MeetingRoom) => {
    Alert.alert('Remove room?', `${room.name} will no longer be bookable.`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Remove',
        style: 'destructive',
        onPress: () =>
          removeMeetingRoom(room.id).catch((err) =>
            Alert.alert(
              'Could not remove room',
              err instanceof ApiError ? err.message : 'Something went wrong.',
            ),
          ),
      },
    ]);
  };

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Meeting rooms"
          subtitle="Bookable spaces across the office"
          rightActions={[
            { icon: 'document-attach-outline', onPress: () => setImportVisible(true) },
            { icon: 'close', onPress: () => navigation.goBack() },
          ]}
        />
        <Card>
          <Input
            label="Room name"
            value={name}
            onChangeText={setName}
            placeholder="e.g. Boardroom A"
            icon="business-outline"
          />
          <View style={styles.row}>
            <View style={{ flex: 1 }}>
              <Input
                label="Capacity"
                value={capacity}
                onChangeText={setCapacity}
                placeholder="e.g. 12"
                icon="people-outline"
                keyboardType="number-pad"
              />
            </View>
            <View style={{ width: spacing.sm }} />
            <View style={{ flex: 1 }}>
              <Input
                label="Floor"
                value={floor}
                onChangeText={setFloor}
                placeholder="e.g. 3rd Floor"
                icon="layers-outline"
              />
            </View>
          </View>
          <Input
            label="Description / directions (optional)"
            value={description}
            onChangeText={setDescription}
            placeholder="e.g. Past the kitchen, second door on the left"
            icon="map-outline"
            multiline
          />
          <Pressable onPress={onPickPhoto} disabled={pickingPhoto} style={styles.photoRow}>
            <View
              style={[
                styles.photoPreview,
                { borderColor: colors.border, backgroundColor: colors.surfaceAlt },
              ]}
            >
              {photoUrl ? (
                <Image source={{ uri: photoUrl }} style={styles.photoImage} resizeMode="cover" />
              ) : (
                <Ionicons name="camera-outline" size={20} color={colors.textMuted} />
              )}
            </View>
            <Text variant="bodySemibold" color={colors.brand} style={{ marginLeft: spacing.sm }}>
              {pickingPhoto
                ? 'Opening photos...'
                : photoUrl
                  ? 'Change photo'
                  : 'Add a room photo (optional)'}
            </Text>
          </Pressable>
          <Button label={adding ? 'Adding...' : 'Add room'} onPress={onAdd} disabled={adding} />
        </Card>
      </View>

      <FlatList
        refreshControl={refreshControl}
        data={meetingRooms}
        keyExtractor={(r) => r.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="business-outline"
            title="No rooms yet"
            message="Add your first meeting room above."
          />
        }
        renderItem={({ item }) => (
          <Card style={{ marginHorizontal: spacing.md }}>
            <View style={styles.roomRow}>
              <View style={[styles.roomIcon, { backgroundColor: colors.primarySurface }]}>
                {item.photoUrl ? (
                  <Image
                    source={{ uri: item.photoUrl }}
                    style={styles.roomIconImage}
                    resizeMode="cover"
                  />
                ) : (
                  <Ionicons name="business" size={20} color={colors.primary} />
                )}
              </View>
              <View style={{ flex: 1, marginLeft: spacing.sm }}>
                <Text variant="bodySemibold">{item.name}</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {item.floor || 'No floor set'}
                  {item.capacity ? ` - Capacity ${item.capacity}` : ''}
                </Text>
                {item.description ? (
                  <Text
                    variant="caption"
                    color={colors.textMuted}
                    numberOfLines={2}
                    style={{ marginTop: 2 }}
                  >
                    {item.description}
                  </Text>
                ) : null}
              </View>
              <Pressable onPress={() => onRemove(item)} hitSlop={8}>
                <Ionicons name="trash-outline" size={20} color={colors.status.rejected.solid} />
              </Pressable>
            </View>
          </Card>
        )}
      />

      <CsvImportModal
        visible={importVisible}
        onClose={() => setImportVisible(false)}
        title="Import rooms"
        columnsHint="Columns: name, capacity, floor, description"
        mapRow={mapCsvRow}
        onImport={bulkImportMeetingRooms}
      />
    </Screen>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  row: { flexDirection: 'row' },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  roomRow: { flexDirection: 'row', alignItems: 'center' },
  roomIcon: {
    width: 44,
    height: 44,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  roomIconImage: { width: '100%', height: '100%' },
  photoRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.md },
  photoPreview: {
    width: 44,
    height: 44,
    borderRadius: radius.md,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  photoImage: { width: '100%', height: '100%' },
});

'@
$path = Join-Path (Get-Location) 'src\screens\MeetingRoomsScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/MeetingRoomsScreen.tsx'

$content = @'
import React, { useCallback, useMemo } from 'react';
import { View, StyleSheet, FlatList } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Screen, Header, Text, Card, Badge, EmptyState, Avatar, StatTile } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtTime, fmtDate } from '../data/format';
import { usePullToRefresh } from '../components/usePullToRefresh';

// ManagerClockInsScreen -- every clock-in/out record, for record
// keeping. Sourced from DataContext's shared `clockRecords` ledger --
// the same one the Employee/Receptionist "on the clock" cards write
// to. That ledger is only loaded once at login though, so it won't
// pick up a *different* signed-in session's clock-ins on its own (no
// websockets/polling in this build) -- refetch on focus so re-opening
// this tab always shows what everyone else has actually done.
export default function ManagerClockInsScreen() {
  const refreshControl = usePullToRefresh();
  const { colors } = useTheme();
  const { clockRecords, refreshClockRecords } = useData();

  useFocusEffect(
    useCallback(() => {
      refreshClockRecords().catch(() => {});
    }, []),
  );

  const sorted = useMemo(
    () =>
      [...clockRecords].sort(
        (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime(),
      ),
    [clockRecords],
  );

  const onsiteCount = useMemo(() => {
    const seen = new Set<string>();
    let count = 0;
    sorted.forEach((r) => {
      if (seen.has(r.employeeId)) return;
      seen.add(r.employeeId);
      if (r.type === 'in') count += 1;
    });
    return count;
  }, [sorted]);

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header title="Clock ins" subtitle="Attendance record for every role" />
        <StatTile icon="people" tint="primary" label="Currently on the clock" value={onsiteCount} />
      </View>

      <FlatList
        refreshControl={refreshControl}
        data={sorted}
        keyExtractor={(r) => r.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.xs }} />}
        ListEmptyComponent={
          <EmptyState
            icon="time-outline"
            title="No clock records yet"
            message="Clock-in/out activity from Employee and Receptionist home screens will appear here."
          />
        }
        renderItem={({ item }) => (
          <Card padded={false} style={{ marginHorizontal: spacing.md }}>
            <View style={styles.row}>
              <Avatar name={item.employeeName || 'Unknown'} size={40} />
              <View style={{ flex: 1, marginLeft: spacing.sm }}>
                <Text variant="bodySemibold" numberOfLines={1}>
                  {item.employeeName || 'Unknown'}
                </Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {fmtDate(item.timestamp)}
                </Text>
              </View>
              <View style={{ alignItems: 'flex-end' }}>
                <Badge
                  label={item.type === 'in' ? 'Clocked in' : 'Clocked out'}
                  status={item.type === 'in' ? 'success' : 'neutral'}
                  size="sm"
                />
                <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
                  {fmtTime(item.timestamp)}
                </Text>
              </View>
            </View>
          </Card>
        )}
      />
    </Screen>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: spacing.sm, gap: spacing.sm },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  row: { flexDirection: 'row', alignItems: 'center', padding: spacing.sm },
});

'@
$path = Join-Path (Get-Location) 'src\screens\ManagerClockInsScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/ManagerClockInsScreen.tsx'

$content = @'
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
              {item.status === 'pending' && (
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

'@
$path = Join-Path (Get-Location) 'src\screens\VisitorVisitsScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/VisitorVisitsScreen.tsx'

$content = @'
import React, { useMemo, useState } from 'react';
import { View, SectionList, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Badge, Input, Segmented, EmptyState } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtDateTime, splitRecentOlder } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';
import type { Call, StatusKey } from '../types';
import { usePullToRefresh } from '../components/usePullToRefresh';

interface CallLogScreenProps {
  navigation: RootStackNavigation;
}

type CallFilter = 'all' | 'incoming' | 'outgoing' | 'missed';

// CallLogScreen -- every incoming / outgoing / missed call.
// Fields per the User Guide: date+time, caller name+phone, host, duration, purpose.
export default function CallLogScreen({ navigation }: CallLogScreenProps) {
  const refreshControl = usePullToRefresh();
  const { colors } = useTheme();
  const { calls, employeeById } = useData();
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState<CallFilter>('all');

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
      .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
  }, [calls, query, filter, employeeById]);

  const sections = useMemo(() => splitRecentOlder(filtered, (c) => c.timestamp), [filtered]);

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

      <SectionList
        refreshControl={refreshControl}
        sections={sections}
        keyExtractor={(c) => c.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        renderSectionHeader={({ section }) => (
          <Text
            variant="eyebrow"
            color={colors.textMuted}
            style={[styles.sectionHeader, { backgroundColor: colors.background }]}
          >
            {section.title}
          </Text>
        )}
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

function CallRow({ call }: { call: Call }) {
  const { colors } = useTheme();
  const { employeeById } = useData();
  const host = employeeById(call.hostId);
  const icon: 'call' | 'call-outline' | 'call-sharp' =
    call.callType === 'Incoming'
      ? 'call'
      : call.callType === 'Outgoing'
        ? 'call-outline'
        : 'call-sharp';
  const badgeStatus: StatusKey =
    call.callType === 'Missed' ? 'rejected' : call.callType === 'Incoming' ? 'success' : 'info';

  return (
    <Card padded={false} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <View style={[styles.iconWrap, { backgroundColor: colors.status[badgeStatus].bg }]}>
          <Ionicons name={icon} size={18} color={colors.status[badgeStatus].solid} />
        </View>
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <View style={styles.rowTop}>
            <Text variant="bodySemibold" numberOfLines={1}>
              {call.callerName}
            </Text>
            <Badge label={call.callType} status={badgeStatus} size="sm" dot={false} />
          </View>
          <Text variant="caption" color={colors.textSecondary} numberOfLines={1}>
            {call.callerPhone} - Host: {host?.name || 'Unassigned'}
          </Text>
          <Text variant="caption" color={colors.textMuted}>
            {fmtDateTime(call.timestamp)} - {call.durationMinutes}m - {call.purpose}
          </Text>
          {call.notes ? (
            <Text
              variant="caption"
              color={colors.textSecondary}
              style={{ marginTop: 2 }}
              numberOfLines={2}
            >
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
  sectionHeader: { paddingVertical: spacing.xs },
  row: { flexDirection: 'row', alignItems: 'flex-start', padding: spacing.md },
  iconWrap: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rowTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: 8 },
});

'@
$path = Join-Path (Get-Location) 'src\screens\CallLogScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/CallLogScreen.tsx'

$content = @'
import React, { useMemo, useState } from 'react';
import { View, SectionList, StyleSheet, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen,
  Header,
  Text,
  Card,
  Badge,
  Input,
  Segmented,
  EmptyState,
  Avatar,
  ExportModal,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtTime, fmtDateTime, fmtDuration, splitRecentOlder } from '../data/format';
import {
  toCsv,
  toHtmlTable,
  exportCsvFile,
  exportPdfFile,
  type ExportColumn,
} from '../data/export';
import type { RootStackNavigation } from '../types/navigation';
import type { Visitor } from '../types';
import { usePullToRefresh } from '../components/usePullToRefresh';

interface VisitorsScreenProps {
  navigation: RootStackNavigation;
}

type StatusFilter = 'all' | 'onsite' | 'completed';

// VisitorsScreen -- the live visitor log.
// Implements the "Visitor Logs" page from the User Guide:
// - search by name, badge number, or host
// - status filter: All / On-site / Completed
// - badge IDs are auto-generated (VIS-YYYY-NNN)
// - each row links into a detail page where check-out happens
// A floating "Register" button opens the registration modal.
export default function VisitorsScreen({ navigation }: VisitorsScreenProps) {
  const refreshControl = usePullToRefresh();
  const { colors } = useTheme();
  const { visitors, employeeById } = useData();
  const [query, setQuery] = useState('');
  const [status, setStatus] = useState<StatusFilter>('all');
  const [exporting, setExporting] = useState(false);

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

  const sections = useMemo(() => splitRecentOlder(filtered, (v) => v.checkInAt), [filtered]);

  // Exports whatever the search/status filters currently show, so
  // "export" always matches what's on screen rather than the whole log.
  const exportColumns: ExportColumn<Visitor>[] = [
    { header: 'Name', get: (v) => v.fullName },
    { header: 'Badge', get: (v) => v.badgeId },
    { header: 'Status', get: (v) => (v.status === 'onsite' ? 'On-site' : 'Completed') },
    { header: 'Purpose', get: (v) => v.purpose },
    { header: 'Host', get: (v) => employeeById(v.hostId)?.name || '' },
    { header: 'Company', get: (v) => v.company },
    { header: 'Check-in', get: (v) => fmtDateTime(v.checkInAt) },
    { header: 'Check-out', get: (v) => (v.checkOutAt ? fmtDateTime(v.checkOutAt) : '') },
  ];
  const onExportCsv = () =>
    exportCsvFile(`visitors-${Date.now()}.csv`, toCsv(filtered, exportColumns));
  const onExportPdf = () =>
    exportPdfFile(
      `visitors-${Date.now()}.pdf`,
      toHtmlTable('Visitor log', filtered, exportColumns),
    );

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Visitors"
          subtitle="Live visitor log & check-in"
          onBackPress={() => navigation.goBack()}
          rightActions={[
            { icon: 'download-outline', onPress: () => setExporting(true) },
            { icon: 'person-add', onPress: () => navigation.navigate('RegisterVisitor') },
          ]}
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

      <SectionList
        refreshControl={refreshControl}
        sections={sections}
        keyExtractor={(v) => v.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        renderSectionHeader={({ section }) => (
          <Text
            variant="eyebrow"
            color={colors.textMuted}
            style={[styles.sectionHeader, { backgroundColor: colors.background }]}
          >
            {section.title}
          </Text>
        )}
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

      <ExportModal
        visible={exporting}
        title="Export visitor log"
        onClose={() => setExporting(false)}
        onExportCsv={onExportCsv}
        onExportPdf={onExportPdf}
      />
    </Screen>
  );
}

// Single row inside the visitor list. Status drives the card's accent
// stripe (on the leading edge) AND a pill badge on the right.
function VisitorRow({
  visitor,
  hostName,
  onPress,
}: {
  visitor: Visitor;
  hostName?: string;
  onPress: () => void;
}) {
  const { colors } = useTheme();
  const isOnsite = visitor.status === 'onsite';
  const accent = isOnsite ? 'onsite' : 'neutral';
  return (
    <Card accent={accent} padded={false} onPress={onPress} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <Avatar name={visitor.fullName} size={44} />
        <View style={styles.middle}>
          <View style={styles.titleRow}>
            <Text variant="bodySemibold" numberOfLines={1}>
              {visitor.fullName}
            </Text>
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
            <View style={[styles.dot, { backgroundColor: colors.textMuted }]} />
            <Ionicons name="time-outline" size={12} color={colors.textMuted} />
            <Text variant="caption" color={colors.textMuted} style={{ marginLeft: 4 }}>
              {isOnsite
                ? `In - ${fmtTime(visitor.checkInAt)} - ${fmtDuration(visitor.checkInAt)}`
                : `${fmtTime(visitor.checkInAt)} - ${fmtTime(visitor.checkOutAt)}`}
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
  sectionHeader: { paddingVertical: spacing.xs },
  row: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  middle: { flex: 1, marginLeft: spacing.sm },
  titleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 8,
  },
  metaRow: { flexDirection: 'row', alignItems: 'center', marginTop: 4 },
  dot: {
    width: 3,
    height: 3,
    borderRadius: 2,
    marginHorizontal: 8,
  },
});

'@
$path = Join-Path (Get-Location) 'src\screens\VisitorsScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/VisitorsScreen.tsx'

Write-Host ''
Write-Host 'Done. 18 files written.'
Write-Host 'Next: run   npx tsc --noEmit'
