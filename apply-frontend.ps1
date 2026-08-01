# VisiLog frontend - Parts 1-8 (email verification, dark mode, auth screens, account settings, empty states, multi-step booking, pickers, manager tour)
# Generated for VisiLog. Run from the repository root.
$ErrorActionPreference = 'Stop'
$written = 0

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
  signOutText: { fontFamily: fonts.regular, fontSize: 12, color: 'rgba(255,255,255,0.75)' },
});

'@
$path = Join-Path (Get-Location) 'src\screens\VerifyEmailScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/VerifyEmailScreen.tsx'
$written = $written + 1

$content = @'
import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import { useAuth } from '../context/AuthContext';
import SplashScreen from '../screens/SplashScreen';

// Auth / onboarding screens
import LoginScreen from '../screens/LoginScreen';
import SignupScreen from '../screens/SignupScreen';
import ForgotPasswordScreen from '../screens/ForgotPasswordScreen';
import RegisterCompanyScreen from '../screens/RegisterCompanyScreen';
import LegalAgreementScreen from '../screens/LegalAgreementScreen';
import VerifyEmailScreen from '../screens/VerifyEmailScreen';

// Per-role app shells (each is its own bottom-tab navigator)
import TabNavigator from './TabNavigator';
import VisitorTabNavigator from './VisitorTabNavigator';
import EmployeeTabNavigator from './EmployeeTabNavigator';
import ManagerTabNavigator from './ManagerTabNavigator';

// Detail & modal screens (pushed on top of the tab bar)
import VisitorsScreen from '../screens/VisitorsScreen';
import DirectoryScreen from '../screens/DirectoryScreen';
import NFCLookupScreen from '../screens/NFCLookupScreen';
import RegisterVisitorScreen from '../screens/RegisterVisitorScreen';
import VisitorDetailScreen from '../screens/VisitorDetailScreen';
import EmployeeDetailScreen from '../screens/EmployeeDetailScreen';
import AddEmployeeScreen from '../screens/AddEmployeeScreen';
import LogCallScreen from '../screens/LogCallScreen';
import CallLogScreen from '../screens/CallLogScreen';
import ReportsScreen from '../screens/ReportsScreen';
import NFCCardsScreen from '../screens/NFCCardsScreen';
import AttendanceScreen from '../screens/AttendanceScreen';
import HistoryScreen from '../screens/HistoryScreen';
import BillingScreen from '../screens/BillingScreen';
import CompanySetupScreen from '../screens/CompanySetupScreen';
import MeetingRoomsScreen from '../screens/MeetingRoomsScreen';
import NotificationsScreen from '../screens/NotificationsScreen';
import type { RootStackParamList } from '../types/navigation';

const Stack = createNativeStackNavigator<RootStackParamList>();

// Root navigator. Role is fixed server-side at signup (matched against
// the company's staff roster, or visitor if there's no match), so a
// signed-in user goes straight to their role's tab shell -- no picker,
// no ID-verify step. `initializing` covers the one-time check for a
// previously-stored session on cold start.
export default function RootNavigator() {
  const { user, initializing } = useAuth();

  if (initializing) {
    return <SplashScreen />;
  }

  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {!user ? (
        // ---------- Signed-out stack ----------
        <Stack.Group>
          <Stack.Screen name="Login" component={LoginScreen} />
          <Stack.Screen name="Signup" component={SignupScreen} />
          <Stack.Screen name="ForgotPassword" component={ForgotPasswordScreen} />
          <Stack.Screen name="RegisterCompany" component={RegisterCompanyScreen} />
          <Stack.Screen name="LegalAgreement" component={LegalAgreementScreen} />
        </Stack.Group>
      ) : !user.emailVerified ? (
        // ---------- Signed in, but email not confirmed yet ----------
        // Registering an account gets you a token, not the app: until
        // the code we emailed is entered, this is the only screen in
        // the stack, so there is nowhere else to navigate to. The
        // backend enforces the same thing independently (JwtAuthFilter
        // refuses that token everywhere but the verify endpoints), so
        // this is the visible half of a real gate rather than a screen
        // that merely hides the app.
        <Stack.Group>
          <Stack.Screen name="VerifyEmail" component={VerifyEmailScreen} />
        </Stack.Group>
      ) : (
        // ---------- Signed-in, role-resolved stack ----------
        <Stack.Group>
          {user.role === 'receptionist' && <Stack.Screen name="Tabs" component={TabNavigator} />}
          {user.role === 'visitor' && (
            <Stack.Screen name="VisitorTabs" component={VisitorTabNavigator} />
          )}
          {user.role === 'employee' && (
            <Stack.Screen name="EmployeeTabs" component={EmployeeTabNavigator} />
          )}
          {user.role === 'manager' && (
            <Stack.Screen name="ManagerTabs" component={ManagerTabNavigator} />
          )}

          {/* Modal-style screens (forms) */}
          <Stack.Group screenOptions={{ presentation: 'modal' }}>
            <Stack.Screen name="RegisterVisitor" component={RegisterVisitorScreen} />
            <Stack.Screen name="AddEmployee" component={AddEmployeeScreen} />
            <Stack.Screen name="LogCall" component={LogCallScreen} />
          </Stack.Group>

          {/* Pushed detail / sub-module screens, reachable from Quick
 Actions and various rows rather than living in a tab bar */}
          <Stack.Screen name="Visitors" component={VisitorsScreen} />
          <Stack.Screen name="Directory" component={DirectoryScreen} />
          <Stack.Screen name="VisitorDetail" component={VisitorDetailScreen} />
          <Stack.Screen name="EmployeeDetail" component={EmployeeDetailScreen} />
          <Stack.Screen name="CallLog" component={CallLogScreen} />
          <Stack.Screen name="Reports" component={ReportsScreen} />
          <Stack.Screen name="NFCCards" component={NFCCardsScreen} />
          <Stack.Screen name="NFCLookup" component={NFCLookupScreen} />
          <Stack.Screen name="Attendance" component={AttendanceScreen} />
          <Stack.Screen name="History" component={HistoryScreen} />
          <Stack.Screen name="Billing" component={BillingScreen} />
          <Stack.Screen name="CompanySetup" component={CompanySetupScreen} />
          <Stack.Screen name="MeetingRooms" component={MeetingRoomsScreen} />
          <Stack.Screen name="Notifications" component={NotificationsScreen} />
          <Stack.Screen name="LegalAgreement" component={LegalAgreementScreen} />
        </Stack.Group>
      )}
    </Stack.Navigator>
  );
}

'@
$path = Join-Path (Get-Location) 'src\navigation\RootNavigator.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/navigation/RootNavigator.tsx'
$written = $written + 1

$content = @'
import type {
  NativeStackNavigationProp,
  NativeStackScreenProps,
} from '@react-navigation/native-stack';

// Route param types for the single root native-stack navigator (see
// navigation/RootNavigator.tsx). Every per-role tab navigator
// (VisitorTabNavigator, EmployeeTabNavigator, ManagerTabNavigator,
// TabNavigator) is itself mounted as one screen in this stack, and
// React Navigation merges the stack's navigation prop into every
// nested tab screen -- so typing screens against this one param list
// (rather than a separate list per tab navigator) matches how
// `navigation.navigate(...)` actually resolves at runtime across the
// whole app.
export type RootStackParamList = {
  // Signed-out stack
  Login: undefined;
  Signup: undefined;
  ForgotPassword: undefined;
  RegisterCompany: undefined;

  // Signed in but unverified -- the whole stack is just this one
  // screen (see RootNavigator).
  VerifyEmail: undefined;

  LegalAgreement:
    | {
        pending?: {
          companyName: string;
          adminName: string;
          adminEmail: string;
          password: string;
        };
      }
    | undefined;

  // Per-role tab shells
  Tabs: undefined;
  VisitorTabs: undefined;
  EmployeeTabs: undefined;
  ManagerTabs: undefined;

  // Tab screens (registered by name inside each tab navigator)
  Home: undefined;
  Book: undefined;
  Appointments: undefined;
  Settings: undefined;
  Visits: undefined;
  'Clock ins': undefined;
  Logs: undefined;

  // Modal-style screens
  RegisterVisitor: undefined;
  AddEmployee: undefined;
  LogCall: undefined;

  // Pushed detail / sub-module screens
  Visitors: undefined;
  Directory: undefined;
  VisitorDetail: { visitorId: string };
  EmployeeDetail: { employeeId: string };
  CallLog: undefined;
  Reports: undefined;
  NFCCards: undefined;
  NFCLookup: undefined;
  Attendance: undefined;
  History: { tab?: 'appointments' | 'meetings' | 'clock' } | undefined;
  Billing: undefined;
  CompanySetup: undefined;
  MeetingRooms: undefined;
  Notifications: undefined;
};

export type RootStackScreenName = keyof RootStackParamList;

// Reusable prop types for screen components. Most screens only care
// about `navigation` (no route params); use RootStackScreenProps for
// the handful that read route.params (VisitorDetail, EmployeeDetail,
// LegalAgreement).
export type RootStackNavigation = NativeStackNavigationProp<RootStackParamList>;
export type RootStackScreenProps<T extends RootStackScreenName> = NativeStackScreenProps<
  RootStackParamList,
  T
>;

'@
$path = Join-Path (Get-Location) 'src\types\navigation.ts'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/types/navigation.ts'
$written = $written + 1

$content = @'
// Core domain types shared across the app. These describe the *mapped*
// (frontend-normalized, lowercase-enum) shapes produced by context/*.tsx --
// not the raw backend DTOs, which arrive with UPPERCASE enum strings and
// get normalized at the DataContext/AuthContext boundary (see mapVisitor,
// mapAppointment, etc.) so every screen can work with one consistent case.

import type { ComponentProps } from 'react';
import type { Ionicons } from '@expo/vector-icons';
import type { BrandTheme, StatusKey } from '../theme/colors';

export type { BrandTheme, StatusKey };

export type IoniconName = ComponentProps<typeof Ionicons>['name'];

export interface Option<T = string> {
  label: string;
  value: T;
  sublabel?: string;
}

export type Role = 'visitor' | 'receptionist' | 'employee' | 'manager';

export interface User {
  id: string;
  email: string;
  name: string;
  role: Role;
  employeeId: string | null;
  organizationId: string;
  organizationName: string;
  // False between signing up and entering the 6-digit code emailed to
  // this address. RootNavigator holds such an account on the verify
  // screen, and the backend refuses its token everywhere else.
  emailVerified: boolean;
}

// A named GPS point + radius the clock-in/visitor-check-in geofence
// check (locationCheck.ts) can be satisfied against -- an org can have
// more than one (see DataContext.officeLocations); the first is free
// on any plan, a second+ requires the enterprise plan.
export interface OfficeLocation {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
}

export interface Organization {
  id: string;
  code: string;
  name: string;
  logoUrl: string | null;
  theme: BrandTheme;
  wifiNetworkName: string | null;
  // The org's current plan id -- lets every role (not just managers,
  // who alone can see full Billing) do client-side plan-feature checks
  // like SettingsScreen's priority-support badge.
  planId: string | null;
}

export interface Employee {
  id: string;
  employeeId: string;
  name: string;
  department: string;
  phone: string;
  email: string;
  role: Role;
  // Whether this employee's clock-ins are locked to a phone yet -- see
  // ClockRecordService.checkDeviceBinding on the backend.
  deviceBound: boolean;
}

export type VisitorStatus = 'onsite' | 'completed';

export interface Visitor {
  id: string;
  badgeId: string;
  firstName: string;
  lastName: string;
  fullName: string;
  phone: string;
  email: string;
  company: string;
  purpose: string;
  hostId: string;
  checkInAt: string;
  checkOutAt: string | null;
  status: VisitorStatus;
  notes: string;
}

export type AppointmentStatus = 'pending' | 'admitted' | 'rejected';

export interface Appointment {
  id: string;
  visitorName: string;
  visitorPhone: string;
  visitorEmail: string;
  visitorCompany: string;
  purpose: string;
  hostId: string;
  scheduledAt: string;
  status: AppointmentStatus;
  nfcCode: string | null;
  bookedByEmail?: string | null;
  rescheduleReason?: string | null;
  rescheduledAt?: string | null;
  rejectReason?: string | null;
}

export type CallType = 'Incoming' | 'Outgoing' | 'Missed';

export interface Call {
  id: string;
  callerName: string;
  callerPhone: string;
  hostId: string;
  callType: CallType;
  purpose: string;
  durationMinutes: number;
  notes: string;
  timestamp: string;
}

export interface MeetingRoom {
  id: string;
  name: string;
  capacity: number | null;
  floor: string;
  photoUrl: string | null;
  description: string | null;
}

export type ClockType = 'in' | 'out';

export interface ClockRecord {
  id: string;
  employeeId: string;
  employeeName: string;
  type: ClockType;
  timestamp: string;
}

export type MeetingPriority = 'normal' | 'important' | 'urgent';
export type MeetingResponseStatus = 'pending' | 'acknowledged' | 'declined';

export interface RoomBookingResponse {
  employeeId: string;
  status: MeetingResponseStatus;
  declineReason: string | null;
  respondedAt: string | null;
  absent: boolean;
}

export interface ExternalGuest {
  name: string | null;
  email: string | null;
  phone: string | null;
}

export interface RoomBooking {
  id: string;
  roomId: string | null;
  location: string;
  organiserId: string;
  title: string;
  startTime: string;
  endTime: string;
  participantIds: string[];
  externalGuests: ExternalGuest[];
  priority: MeetingPriority;
  responses: RoomBookingResponse[];
}

export type NotificationType =
  | 'meeting_invite'
  | 'meeting_declined'
  | 'visit_admitted'
  | 'visit_rejected'
  | 'visit_checked_out'
  | 'appointment_requested'
  | 'appointment_rescheduled'
  | 'call_logged'
  | 'participant_absent';

export interface AppNotification {
  id: string;
  type: NotificationType;
  title: string;
  body: string;
  relatedId: string | null;
  read: boolean;
  createdAt: string;
}

export interface Plan {
  id: string;
  name: string;
  price: number;
  seatLimit: number;
  features: string[];
}

export type BillingStatus = 'active' | 'trial' | 'past_due';

export interface Billing {
  planId: string;
  status: BillingStatus;
  seatsUsed: number;
  renewalDate: string;
  paymentLast4: string | null;
}

export type InvoiceStatus = 'paid' | 'failed';

export interface Invoice {
  id: string;
  date: string;
  amount: number;
  status: InvoiceStatus;
}

// ---- operation input shapes ----

export interface RegisterVisitorInput {
  firstName: string;
  lastName: string;
  phone: string;
  email?: string;
  company?: string;
  purpose: string;
  hostId: string;
  notes?: string;
}

export interface BookVisitInput {
  visitorName: string;
  visitorPhone: string;
  visitorEmail?: string;
  visitorCompany?: string;
  purpose: string;
  hostId: string;
  scheduledAt: string;
}

export interface LogCallInput {
  callerName: string;
  callerPhone: string;
  hostId: string;
  callType: string;
  purpose: string;
  durationMinutes: number | string;
  notes?: string;
}

export interface EmployeeInput {
  employeeId?: string;
  name: string;
  department?: string;
  phone?: string;
  email?: string;
  role?: Role;
}

export interface BulkImportRowError {
  row: number;
  message: string;
}

export interface BulkImportResult<T> {
  created: T[];
  errors: BulkImportRowError[];
}

export interface OfficeLocationInput {
  name: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
}

export interface MeetingRoomInput {
  name: string;
  capacity?: number | string | null;
  floor?: string;
  photoUrl?: string | null;
  description?: string | null;
}

export interface BookRoomInput {
  roomId?: string | null;
  location?: string;
  title?: string;
  startTime: string;
  endTime: string;
  participantIds?: string[];
  externalGuests?: ExternalGuest[];
  priority?: MeetingPriority;
}

// No backend model exists for standalone NFC cards yet (the per-visit
// NFC code lives on Appointment.nfcCode) -- DataContext seeds this as an
// always-empty array, but NFCCardsScreen is written against this shape
// so it's ready once/if a real NfcCard endpoint exists.
export type NfcCardStatus = 'active' | 'revoked';
export type NfcHolderType = 'employee' | 'visitor';

export interface NfcCard {
  id: string;
  holderId: string;
  holderType: NfcHolderType;
  tokenHash: string;
  issuedAt: string;
  expiresAt: string;
  status: NfcCardStatus;
}

export interface AuthResult {
  ok: boolean;
  error?: string;
  organization?: Organization;
}

'@
$path = Join-Path (Get-Location) 'src\types\index.ts'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/types/index.ts'
$written = $written + 1

$content = @'
import React, { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { apiClient, ApiError } from '../api/client';
import { setToken, clearToken, loadStoredToken } from '../api/tokenStore';
import { saveRememberedLogin, clearRememberedLogin } from '../api/rememberedLogin';
import { useTheme } from '../theme/ThemeContext';
import type { AuthResult, Organization, Role, User } from '../types';

// AuthContext talks to the real VisiLog backend (see server/). Role is
// decided once, server-side, at signup time (by matching the signing-up
// email against the company's staff roster) -- there is no more
// role-picker or employee-ID-verify step on the frontend.

interface UserDto {
  id: string;
  email: string;
  name: string;
  role: string;
  employeeId: string | null;
  organizationId: string;
  organizationName: string;
  emailVerified: boolean;
}

interface AuthResponse {
  token: string;
  user: UserDto;
  organization: Organization;
}

interface OrganizationPatch {
  name?: string;
  logoUrl?: string | null;
  theme?: Organization['theme'];
  wifiNetworkName?: string | null;
}

interface MessageResult {
  ok: boolean;
  message: string;
}

interface AuthContextValue {
  user: User | null;
  organization: Organization | null;
  initializing: boolean;
  login: (
    email: string,
    password: string,
    companyCode: string,
    remember?: boolean,
  ) => Promise<AuthResult>;
  signup: (
    companyCode: string,
    email: string,
    password: string,
    name: string,
  ) => Promise<AuthResult>;
  loginWithGoogle: (companyCode: string, idToken: string) => Promise<AuthResult>;
  forgotPassword: (companyCode: string, email: string) => Promise<MessageResult>;
  resetPassword: (
    companyCode: string,
    email: string,
    code: string,
    newPassword: string,
  ) => Promise<MessageResult>;
  registerCompany: (
    companyName: string,
    adminName: string,
    adminEmail: string,
    adminPassword: string,
  ) => Promise<AuthResult>;
  verifyEmail: (code: string) => Promise<{ ok: boolean; error?: string }>;
  resendVerification: () => Promise<MessageResult>;
  logout: () => Promise<void>;
  verifyPassword: (password: string) => Promise<{ ok: boolean; error?: string }>;
  updateOrganization: (patch: OrganizationPatch) => Promise<AuthResult>;
  updateProfile: (name: string) => Promise<{ ok: boolean; error?: string }>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

// Backend roles are uppercase enum names (VISITOR/RECEPTIONIST/EMPLOYEE/
// MANAGER); every screen in this app was built against lowercase.
const mapUser = (userDto: UserDto): User => ({
  id: userDto.id,
  email: userDto.email,
  name: userDto.name,
  role: userDto.role.toLowerCase() as Role,
  employeeId: userDto.employeeId,
  organizationId: userDto.organizationId,
  organizationName: userDto.organizationName,
  // Accounts created before email verification existed were backfilled
  // as verified server-side; the `!== false` guard covers a response
  // from an older backend build that doesn't send the field at all,
  // which would otherwise strand everyone on the verify screen.
  emailVerified: userDto.emailVerified !== false,
});

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null); // null = signed out
  const [organization, setOrganization] = useState<Organization | null>(null);
  // True until a previously-stored session (if any) has been checked
  // against the backend, so RootNavigator can hold the splash screen
  // rather than flash the login screen for a signed-in user.
  const [initializing, setInitializing] = useState(true);
  const { setOrgTheme } = useTheme();

  // Keep the color palette in sync with whichever org is currently
  // signed in -- covers login/signup/registerCompany and boot-restore
  // in one place instead of every screen calling setOrgTheme itself.
  useEffect(() => {
    setOrgTheme(organization ? organization.theme : null);
  }, [organization, setOrgTheme]);

  useEffect(() => {
    (async () => {
      const token = await loadStoredToken();
      if (!token) {
        setInitializing(false);
        return;
      }
      // The backend's free-tier host spins down when idle and takes up
      // to a minute to wake, so the first request after a quiet spell
      // often fails with a network error or 5xx -- NOT because the
      // stored session is bad. Retry through that window, and only
      // clear the token when the server itself rejects it (401/403).
      // Clearing on any failure -- what this used to do -- silently
      // logged people out whenever the app opened against a sleeping
      // backend, which reads as "the app forgot everything".
      for (let attempt = 0; attempt < 4; attempt++) {
        try {
          const [userDto, org] = await Promise.all([
            apiClient.get<UserDto>('/api/v1/auth/me'),
            apiClient.get<Organization>('/api/v1/org'),
          ]);
          setUser(mapUser(userDto));
          setOrganization(org);
          break;
        } catch (err) {
          if (err instanceof ApiError && (err.status === 401 || err.status === 403)) {
            // Genuinely stale/invalid token -- sign out quietly.
            await clearToken();
            break;
          }
          if (attempt < 3) {
            await new Promise((resolve) => setTimeout(resolve, (attempt + 1) * 5000));
          }
          // After the last attempt: keep the token (the backend may
          // just be waking up) and land on Login -- signing in again
          // once it's awake works, and the next app open restores the
          // session normally.
        }
      }
      setInitializing(false);
    })();
  }, []);

  // `persist` (default true) controls whether the token is written to
  // AsyncStorage -- LoginScreen's "Remember me" toggles this. false
  // keeps the token in memory only, so the session doesn't survive an
  // app restart even though it works normally until then.
  const applyAuthResponse = async (res: AuthResponse, persist = true) => {
    await setToken(res.token, persist);
    setUser(mapUser(res.user));
    setOrganization(res.organization);
  };

  // `companyCode` resolves which paying organization (tenant) this
  // login belongs to -- required since VisiLog serves several
  // companies, each with their own data and brand colors.
  const login = async (
    email: string,
    password: string,
    companyCode: string,
    remember = true,
  ): Promise<AuthResult> => {
    if (!email || !password || !companyCode) {
      return { ok: false, error: 'Enter your company code, email and password.' };
    }
    try {
      const res = await apiClient.post<AuthResponse>('/api/v1/auth/login', {
        companyCode: companyCode.trim(),
        email: email.trim(),
        password,
      });
      await applyAuthResponse(res, remember);
      if (remember) {
        await saveRememberedLogin({ companyCode: companyCode.trim(), email: email.trim() });
      } else {
        await clearRememberedLogin();
      }
      return { ok: true, organization: res.organization };
    } catch (err) {
      return { ok: false, error: err instanceof ApiError ? err.message : 'Login failed.' };
    }
  };

  // Creates a login account under an existing company. Role is decided
  // server-side: matches `email` against the company's staff roster
  // (that role) or falls back to visitor if there's no match.
  const signup = async (
    companyCode: string,
    email: string,
    password: string,
    name: string,
  ): Promise<AuthResult> => {
    if (!companyCode || !email || !password || !name) {
      return { ok: false, error: 'Please fill in every field above.' };
    }
    try {
      const res = await apiClient.post<AuthResponse>('/api/v1/auth/signup', {
        companyCode: companyCode.trim(),
        email: email.trim(),
        password,
        name: name.trim(),
      });
      await applyAuthResponse(res);
      return { ok: true, organization: res.organization };
    } catch (err) {
      return { ok: false, error: err instanceof ApiError ? err.message : 'Signup failed.' };
    }
  };

  // Self-serve "sign your company up" -- creates the Organization, its
  // first Administrator (Manager) account, and hands back a company
  // code the admin can then share with their staff/visitors.
  const registerCompany = async (
    companyName: string,
    adminName: string,
    adminEmail: string,
    adminPassword: string,
  ): Promise<AuthResult> => {
    if (!companyName || !adminName || !adminEmail || !adminPassword) {
      return { ok: false, error: 'Please fill in every field above.' };
    }
    try {
      const res = await apiClient.post<AuthResponse>('/api/v1/companies/register', {
        companyName: companyName.trim(),
        adminName: adminName.trim(),
        adminEmail: adminEmail.trim(),
        adminPassword,
      });
      await applyAuthResponse(res);
      return { ok: true, organization: res.organization };
    } catch (err) {
      return {
        ok: false,
        error: err instanceof ApiError ? err.message : 'Could not register your company.',
      };
    }
  };

  // Google sign-in. The frontend never sees or checks the ID token
  // itself -- it hands the raw token Google issued straight to the
  // backend, which verifies it against Google's own servers (see
  // GoogleTokenService) before trusting anything in it. Same as
  // signup, an existing account for that email logs straight in; a new
  // one gets its role resolved from the staff roster.
  const loginWithGoogle = async (companyCode: string, idToken: string): Promise<AuthResult> => {
    if (!companyCode || !idToken) {
      return { ok: false, error: 'Enter your company code first.' };
    }
    try {
      const res = await apiClient.post<AuthResponse>('/api/v1/auth/google', {
        companyCode: companyCode.trim(),
        idToken,
      });
      await applyAuthResponse(res);
      return { ok: true, organization: res.organization };
    } catch (err) {
      return { ok: false, error: err instanceof ApiError ? err.message : 'Google sign-in failed.' };
    }
  };

  // Forgot Password: request a numeric reset code by email, then submit
  // it alongside a new password. Neither call touches the signed-in
  // session -- both work from the signed-out Login screen.
  const forgotPassword = async (companyCode: string, email: string): Promise<MessageResult> => {
    try {
      const res = await apiClient.post<{ message: string }>('/api/v1/auth/forgot-password', {
        companyCode: companyCode.trim(),
        email: email.trim(),
      });
      return { ok: true, message: res.message };
    } catch (err) {
      return {
        ok: false,
        message: err instanceof ApiError ? err.message : 'Could not send a reset code.',
      };
    }
  };

  const resetPassword = async (
    companyCode: string,
    email: string,
    code: string,
    newPassword: string,
  ): Promise<MessageResult> => {
    try {
      const res = await apiClient.post<{ message: string }>('/api/v1/auth/reset-password', {
        companyCode: companyCode.trim(),
        email: email.trim(),
        code: code.trim(),
        newPassword,
      });
      return { ok: true, message: res.message };
    } catch (err) {
      return {
        ok: false,
        message: err instanceof ApiError ? err.message : 'Could not reset your password.',
      };
    }
  };

  // Email verification. Both calls run on the token handed out at
  // signup -- which the backend deliberately restricts to these two
  // endpoints plus /auth/me until the code is entered.
  //
  // A successful verify returns a *replacement* token: the one we're
  // holding has "unverified" signed into it and would keep being
  // refused. applyAuthResponse swaps it in and updates `user`, which
  // is what lets RootNavigator move on to the real app.
  const verifyEmail = async (code: string): Promise<{ ok: boolean; error?: string }> => {
    if (!code.trim()) {
      return { ok: false, error: 'Enter the 6-digit code from your email.' };
    }
    try {
      const res = await apiClient.post<AuthResponse>('/api/v1/auth/verify-email', {
        code: code.trim(),
      });
      await applyAuthResponse(res);
      return { ok: true };
    } catch (err) {
      return {
        ok: false,
        error: err instanceof ApiError ? err.message : 'Could not verify that code.',
      };
    }
  };

  const resendVerification = async (): Promise<MessageResult> => {
    try {
      const res = await apiClient.post<{ message: string }>('/api/v1/auth/resend-verification', {});
      return { ok: true, message: res.message };
    } catch (err) {
      return {
        ok: false,
        message: err instanceof ApiError ? err.message : 'Could not send a new code.',
      };
    }
  };

  // Step-up confirmation before a sensitive action on the *current*
  // session -- currently just clock-in (see ClockCard). Re-checks the
  // signed-in user's own password without touching the stored token.
  const verifyPassword = async (password: string): Promise<{ ok: boolean; error?: string }> => {
    try {
      await apiClient.post('/api/v1/auth/verify-password', { password });
      return { ok: true };
    } catch (err) {
      return {
        ok: false,
        error: err instanceof ApiError ? err.message : 'Could not verify your password.',
      };
    }
  };

  const logout = async (): Promise<void> => {
    await clearToken();
    setUser(null);
    setOrganization(null);
  };

  // Company Setup > branding (manager only). `theme`, if present, is
  // sent as a whole object -- see UpdateOrgRequest on the backend.
  const updateOrganization = async (patch: OrganizationPatch): Promise<AuthResult> => {
    try {
      const org = await apiClient.patch<Organization>('/api/v1/org', patch);
      setOrganization(org);
      return { ok: true, organization: org };
    } catch (err) {
      return {
        ok: false,
        error: err instanceof ApiError ? err.message : 'Could not save your changes.',
      };
    }
  };

  // Settings > "Your profile" -- rename yourself. The JWT doesn't carry
  // the display name (see the backend's JwtService), so the existing
  // session stays valid and we just swap our own copy of the user.
  const updateProfile = async (name: string): Promise<{ ok: boolean; error?: string }> => {
    if (!name.trim()) {
      return { ok: false, error: 'Enter a name.' };
    }
    try {
      const dto = await apiClient.patch<UserDto>('/api/v1/auth/me', { name: name.trim() });
      setUser(mapUser(dto));
      return { ok: true };
    } catch (err) {
      return {
        ok: false,
        error: err instanceof ApiError ? err.message : 'Could not update your name.',
      };
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        organization,
        initializing,
        login,
        signup,
        loginWithGoogle,
        registerCompany,
        verifyEmail,
        resendVerification,
        logout,
        verifyPassword,
        forgotPassword,
        resetPassword,
        updateOrganization,
        updateProfile,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = (): AuthContextValue => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider');
  return ctx;
};

'@
$path = Join-Path (Get-Location) 'src\context\AuthContext.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/context/AuthContext.tsx'
$written = $written + 1

$content = @'
import React, {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { apiClient } from '../api/client';
import { getDeviceId } from '../api/deviceId';
import { useAuth } from './AuthContext';
import type {
  Appointment,
  AppointmentStatus,
  AppNotification,
  Billing,
  BookRoomInput,
  BookVisitInput,
  BulkImportResult,
  Call,
  ClockRecord,
  ClockType,
  Employee,
  EmployeeInput,
  Invoice,
  LogCallInput,
  MeetingPriority,
  MeetingResponseStatus,
  MeetingRoom,
  MeetingRoomInput,
  NfcCard,
  NotificationType,
  OfficeLocation,
  OfficeLocationInput,
  Plan,
  RegisterVisitorInput,
  Role,
  RoomBooking,
  RoomBookingResponse,
  Visitor,
  VisitorStatus,
} from '../types';

// DataContext talks to the real VisiLog backend (see server/). Every
// collection below is fetched for the signed-in user's own organization
// (the backend derives that from the JWT, never from anything we send)
// and kept in local state, updated from each mutation's response so the
// UI doesn't need a full refetch after every action.
//
// Backend enums come back as UPPERCASE strings (VisitorStatus, Role,
// etc.) -- every screen in this app was built against the mock data's
// lowercase/Capitalized casing, so the map* helpers below normalize at
// the boundary and every screen keeps working unchanged.

// ---- raw backend DTO shapes (UPPERCASE enums, as they arrive on the wire) ----

interface VisitorDto extends Omit<Visitor, 'status'> {
  status: string;
}
interface AppointmentDto extends Omit<Appointment, 'status'> {
  status: string;
}
interface CallDto extends Omit<Call, 'callType'> {
  callType: string;
}
interface EmployeeDto {
  id: string;
  employeeCode: string;
  name: string;
  department?: string | null;
  phone?: string | null;
  email?: string | null;
  role: string;
  deviceBound: boolean;
}
interface ClockRecordDto extends Omit<ClockRecord, 'type'> {
  type: string;
}
interface RoomBookingResponseDto extends Omit<RoomBookingResponse, 'status'> {
  status: string;
}
interface RoomBookingDto extends Omit<
  RoomBooking,
  'location' | 'participantIds' | 'priority' | 'responses'
> {
  location?: string | null;
  participantIds?: string[] | null;
  priority?: string | null;
  responses?: RoomBookingResponseDto[] | null;
}
interface PlanDto extends Omit<Plan, 'price'> {
  price: string | number;
}
interface NotificationDto extends Omit<AppNotification, 'type'> {
  type: string;
}
interface BillingDto {
  plan: PlanDto;
  status: string;
  seatsUsed: number;
  renewalDate: string;
  paymentLast4: string | null;
}
interface InvoiceDto extends Omit<Invoice, 'amount' | 'status'> {
  amount: string | number;
  status: string;
}

const cap = (s: string): string => (s ? s.charAt(0) + s.slice(1).toLowerCase() : s);

const mapVisitor = (d: VisitorDto): Visitor => ({
  ...d,
  status: d.status.toLowerCase() as VisitorStatus,
});
const mapAppointment = (d: AppointmentDto): Appointment => ({
  ...d,
  status: d.status.toLowerCase() as AppointmentStatus,
});
const mapCall = (d: CallDto): Call => ({ ...d, callType: cap(d.callType) as Call['callType'] });
const mapEmployee = (d: EmployeeDto): Employee => ({
  id: d.id,
  employeeId: d.employeeCode,
  name: d.name,
  department: d.department || '',
  phone: d.phone || '',
  email: d.email || '',
  role: d.role.toLowerCase() as Role,
  deviceBound: d.deviceBound,
});
const mapClockRecord = (d: ClockRecordDto): ClockRecord => ({
  ...d,
  type: d.type.toLowerCase() as ClockType,
});
const mapRoomBookingResponse = (d: RoomBookingResponseDto): RoomBookingResponse => ({
  ...d,
  status: d.status.toLowerCase() as MeetingResponseStatus,
});
const mapRoomBooking = (d: RoomBookingDto): RoomBooking => ({
  ...d,
  location: d.location || '',
  participantIds: d.participantIds || [],
  priority: (d.priority || 'normal').toLowerCase() as MeetingPriority,
  responses: (d.responses || []).map(mapRoomBookingResponse),
});
const mapPlan = (d: PlanDto): Plan => ({ ...d, price: Number(d.price) });
const mapBilling = (d: BillingDto): Billing => ({
  planId: d.plan.id,
  status: d.status.toLowerCase() as Billing['status'],
  seatsUsed: d.seatsUsed,
  renewalDate: d.renewalDate,
  paymentLast4: d.paymentLast4,
});
const mapInvoice = (d: InvoiceDto): Invoice => ({
  ...d,
  amount: Number(d.amount),
  status: d.status.toLowerCase() as Invoice['status'],
});
const mapNotification = (d: NotificationDto): AppNotification => ({
  ...d,
  type: d.type.toLowerCase() as NotificationType,
});

interface DataContextValue {
  // collections
  visitors: Visitor[];
  appointments: Appointment[];
  calls: Call[];
  nfcCards: NfcCard[];
  roomBookings: RoomBooking[];
  employees: Employee[];
  meetingRooms: MeetingRoom[];
  officeLocations: OfficeLocation[];
  // lookup helpers
  employeeById: (id: string) => Employee | undefined;
  roomById: (id: string) => MeetingRoom | undefined;
  // pull-to-refresh -- refetches every collection above in one go
  refreshAll: () => Promise<void>;
  // operations
  registerAndCheckIn: (input: RegisterVisitorInput) => Promise<Visitor>;
  checkOutVisitor: (visitorId: string, notes?: string) => Promise<Visitor>;
  updateAppointmentStatus: (
    id: string,
    status: AppointmentStatus,
    reason?: string,
  ) => Promise<Appointment>;
  admitAppointment: (appointment: Appointment) => Promise<Visitor>;
  logCall: (input: LogCallInput) => Promise<Call>;
  addEmployee: (input: EmployeeInput) => Promise<Employee>;
  updateEmployee: (id: string, input: EmployeeInput) => Promise<Employee>;
  bulkImportEmployees: (rows: EmployeeInput[]) => Promise<BulkImportResult<Employee>>;
  removeEmployee: (id: string) => Promise<void>;
  addMeetingRoom: (input: MeetingRoomInput) => Promise<MeetingRoom>;
  updateMeetingRoom: (id: string, input: MeetingRoomInput) => Promise<MeetingRoom>;
  bulkImportMeetingRooms: (rows: MeetingRoomInput[]) => Promise<BulkImportResult<MeetingRoom>>;
  removeMeetingRoom: (id: string) => Promise<void>;
  addOfficeLocation: (input: OfficeLocationInput) => Promise<OfficeLocation>;
  updateOfficeLocation: (id: string, input: OfficeLocationInput) => Promise<OfficeLocation>;
  removeOfficeLocation: (id: string) => Promise<void>;
  bookVisit: (input: BookVisitInput) => Promise<Appointment>;
  findAppointmentByCode: (code: string) => Promise<Appointment | null>;
  // work attendance (clock in/out) + appointment rescheduling
  clockRecords: ClockRecord[];
  clockIn: (employeeId: string, employeeName: string) => Promise<ClockRecord>;
  clockOut: (employeeId: string, employeeName: string) => Promise<ClockRecord>;
  isClockedIn: (employeeId: string) => boolean;
  hasClockedInToday: (employeeId: string) => boolean;
  refreshClockRecords: () => Promise<void>;
  resetEmployeeDevice: (employeeId: string) => Promise<void>;
  refreshEmployees: () => Promise<void>;
  rescheduleAppointment: (
    id: string,
    newScheduledAt: string,
    reason?: string,
  ) => Promise<Appointment>;
  // self-service room booking
  bookRoom: (input: BookRoomInput) => Promise<RoomBooking>;
  refreshRoomBookings: () => Promise<void>;
  respondToMeeting: (
    bookingId: string,
    status: 'acknowledged' | 'declined',
    reason?: string,
  ) => Promise<void>;
  markParticipantAbsent: (bookingId: string, employeeId: string, absent: boolean) => Promise<void>;
  // billing / subscriptions
  plans: Plan[];
  billing: Billing | null;
  invoices: Invoice[];
  changePlan: (planId: string) => Promise<Billing>;
  // in-app notifications (meeting invites, etc.)
  notifications: AppNotification[];
  unreadNotificationCount: number;
  refreshNotifications: () => Promise<void>;
  markNotificationRead: (id: string) => Promise<void>;
  // derived
  stats: {
    visitorsToday: number;
    onsite: number;
    callsToday: number;
    visitorsThisMonth: number;
    pendingApprovals: number;
  };
}

const DataContext = createContext<DataContextValue | null>(null);

export function DataProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();

  const [visitors, setVisitors] = useState<Visitor[]>([]);
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [calls, setCalls] = useState<Call[]>([]);
  // No backend model for standalone NFC cards in this pass -- the
  // per-visit NFC code lives on the appointment itself (see nfcCode).
  const [nfcCards] = useState<NfcCard[]>([]);
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [meetingRooms, setMeetingRooms] = useState<MeetingRoom[]>([]);
  const [officeLocations, setOfficeLocations] = useState<OfficeLocation[]>([]);
  const [clockRecords, setClockRecords] = useState<ClockRecord[]>([]);
  const [roomBookings, setRoomBookings] = useState<RoomBooking[]>([]);
  const [billing, setBilling] = useState<Billing | null>(null);
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [plans, setPlans] = useState<Plan[]>([]);
  const [notifications, setNotifications] = useState<AppNotification[]>([]);

  // Fetches every collection for the signed-in user. Used both for the
  // one-time load on sign-in and as the shared pull-to-refresh action
  // every screen calls -- previously the only way to see something
  // that changed server-side (e.g. a new pending appointment someone
  // else booked) was to sign out and back in, since nothing ever
  // refetched on its own. Billing/invoices are manager-only on the
  // backend, so non-managers skip those calls entirely rather than
  // getting a 403.
  //
  // Each fetch applies (or fails) INDEPENDENTLY. This used to be one
  // Promise.all, which meant a single failing endpoint -- a backend
  // deploy that's a version behind the app, a Render free-tier cold
  // start timing out one request -- rejected the whole batch before
  // any setter ran, and every list in the app just showed empty. That
  // presented as "all our employees and meeting rooms vanished" when
  // the data was sitting safely in the database the entire time.
  const loadOne = async <T,>(path: string, apply: (data: T) => void): Promise<void> => {
    try {
      apply(await apiClient.get<T>(path));
    } catch (err) {
      // Keep whatever we already have for this collection rather than
      // blanking it -- stale beats empty for every screen we render.
      console.warn(`[DataContext] failed to load ${path}`, err);
    }
  };

  const loadAll = async (): Promise<void> => {
    // An account that hasn't confirmed its email yet holds a token the
    // backend refuses everywhere but the verify endpoints, so firing
    // these off would just log a dozen 403s for no benefit -- it can't
    // see any of this data until it's through VerifyEmailScreen.
    if (!user || !user.emailVerified) return;
    const isManager = user.role === 'manager';
    const appointmentsPath =
      user.role === 'visitor' ? '/api/v1/appointments?mine=true' : '/api/v1/appointments';

    await Promise.all([
      loadOne<VisitorDto[]>('/api/v1/visitors', (v) => setVisitors(v.map(mapVisitor))),
      loadOne<AppointmentDto[]>(appointmentsPath, (a) => setAppointments(a.map(mapAppointment))),
      loadOne<CallDto[]>('/api/v1/calls', (c) => setCalls(c.map(mapCall))),
      loadOne<EmployeeDto[]>('/api/v1/employees', (e) => setEmployees(e.map(mapEmployee))),
      loadOne<MeetingRoom[]>('/api/v1/meeting-rooms', (r) => setMeetingRooms(r)),
      loadOne<ClockRecordDto[]>('/api/v1/clock-records', (cr) =>
        setClockRecords(cr.map(mapClockRecord)),
      ),
      loadOne<RoomBookingDto[]>('/api/v1/room-bookings', (rb) =>
        setRoomBookings(rb.map(mapRoomBooking)),
      ),
      loadOne<PlanDto[]>('/api/v1/plans', (p) => setPlans(p.map(mapPlan))),
      loadOne<OfficeLocation[]>('/api/v1/office-locations', (ol) => setOfficeLocations(ol)),
      ...(isManager
        ? [
            loadOne<BillingDto>('/api/v1/billing', (b) => setBilling(mapBilling(b))),
            loadOne<InvoiceDto[]>('/api/v1/billing/invoices', (inv) =>
              setInvoices(inv.map(mapInvoice)),
            ),
          ]
        : []),
      // Visitors have no employeeId, so there's nothing for them to be
      // notified about (meeting invites only ever target staff).
      ...(user.employeeId
        ? [
            loadOne<NotificationDto[]>('/api/v1/notifications', (n) =>
              setNotifications(n.map(mapNotification)),
            ),
          ]
        : []),
    ]);
  };

  useEffect(() => {
    if (!user) {
      setVisitors([]);
      setAppointments([]);
      setCalls([]);
      setEmployees([]);
      setMeetingRooms([]);
      setClockRecords([]);
      setRoomBookings([]);
      setBilling(null);
      setInvoices([]);
      setPlans([]);
      setNotifications([]);
      return;
    }
    loadAll().catch(() => {});
  }, [user?.id]);

  const refreshAll = async (): Promise<void> => {
    await loadAll();
  };

  // ---- lookup helpers ----
  const employeeById = (id: string) => employees.find((e) => e.id === id);
  const roomById = (id: string) => meetingRooms.find((r) => r.id === id);

  // ---- visitor operations ----

  const registerAndCheckIn = async (input: RegisterVisitorInput): Promise<Visitor> => {
    const dto = await apiClient.post<VisitorDto>('/api/v1/visitors', {
      firstName: input.firstName,
      lastName: input.lastName,
      phone: input.phone,
      email: input.email,
      company: input.company,
      purpose: input.purpose,
      hostId: input.hostId,
      notes: input.notes,
    });
    const visitor = mapVisitor(dto);
    setVisitors((vs) => [visitor, ...vs]);
    return visitor;
  };

  const checkOutVisitor = async (visitorId: string, notes = ''): Promise<Visitor> => {
    const dto = await apiClient.patch<VisitorDto>(`/api/v1/visitors/${visitorId}/check-out`, {
      notes,
    });
    const visitor = mapVisitor(dto);
    setVisitors((vs) => vs.map((v) => (v.id === visitorId ? visitor : v)));
    return visitor;
  };

  // ---- appointment operations ----

  const bookVisit = async (input: BookVisitInput): Promise<Appointment> => {
    const dto = await apiClient.post<AppointmentDto>('/api/v1/appointments', {
      visitorName: input.visitorName,
      visitorPhone: input.visitorPhone,
      visitorEmail: input.visitorEmail,
      visitorCompany: input.visitorCompany,
      purpose: input.purpose,
      hostId: input.hostId,
      scheduledAt: input.scheduledAt,
    });
    const appointment = mapAppointment(dto);
    setAppointments((as) => [appointment, ...as]);
    return appointment;
  };

  const findAppointmentByCode = async (code: string): Promise<Appointment | null> => {
    const clean = (code || '').trim().toUpperCase();
    if (!clean) return null;
    try {
      const dto = await apiClient.get<AppointmentDto>(
        `/api/v1/appointments/by-code/${encodeURIComponent(clean)}`,
      );
      return mapAppointment(dto);
    } catch {
      return null;
    }
  };

  const updateAppointmentStatus = async (
    id: string,
    status: AppointmentStatus,
    reason?: string,
  ): Promise<Appointment> => {
    const dto = await apiClient.patch<AppointmentDto>(`/api/v1/appointments/${id}/status`, {
      status,
      reason,
    });
    const appointment = mapAppointment(dto);
    setAppointments((as) => as.map((a) => (a.id === id ? appointment : a)));
    return appointment;
  };

  // Admitting also registers + checks in the visitor server-side. The
  // admit response is only the updated appointment, so we refetch the
  // visitor list (newest-first) and hand back that just-created record.
  const admitAppointment = async (appointment: Appointment): Promise<Visitor> => {
    const apptDto = await apiClient.post<AppointmentDto>(
      `/api/v1/appointments/${appointment.id}/admit`,
    );
    const updated = mapAppointment(apptDto);
    setAppointments((as) => as.map((a) => (a.id === updated.id ? updated : a)));

    const visitorDtos = await apiClient.get<VisitorDto[]>('/api/v1/visitors');
    const mapped = visitorDtos.map(mapVisitor);
    setVisitors(mapped);
    return mapped[0];
  };

  // ---- call log operations ----

  const logCall = async (input: LogCallInput): Promise<Call> => {
    const dto = await apiClient.post<CallDto>('/api/v1/calls', {
      callerName: input.callerName,
      callerPhone: input.callerPhone,
      hostId: input.hostId,
      callType: input.callType,
      purpose: input.purpose,
      durationMinutes: Number(input.durationMinutes) || 0,
      notes: input.notes,
    });
    const call = mapCall(dto);
    setCalls((cs) => [call, ...cs]);
    return call;
  };

  // ---- directory (staff roster) operations -- manager only ----

  const addEmployee = async (input: EmployeeInput): Promise<Employee> => {
    const dto = await apiClient.post<EmployeeDto>('/api/v1/employees', {
      employeeCode: input.employeeId,
      name: input.name,
      department: input.department,
      phone: input.phone,
      email: input.email,
      role: input.role || 'employee',
    });
    const employee = mapEmployee(dto);
    setEmployees((es) => [...es, employee]);
    return employee;
  };

  // CSV bulk import -- parsed rows come in already shaped like
  // EmployeeInput (see DirectoryScreen's mapRow); the backend still
  // validates and reports back per-row, since a CSV can have typos a
  // single-add form would never let through.
  const bulkImportEmployees = async (
    rows: EmployeeInput[],
  ): Promise<BulkImportResult<Employee>> => {
    const res = await apiClient.post<{
      created: EmployeeDto[];
      errors: BulkImportResult<never>['errors'];
    }>('/api/v1/employees/bulk', {
      employees: rows.map((r) => ({
        employeeCode: r.employeeId,
        name: r.name,
        department: r.department,
        phone: r.phone,
        email: r.email,
        role: r.role || 'employee',
      })),
    });
    const created = res.created.map(mapEmployee);
    setEmployees((es) => [...es, ...created]);
    return { created, errors: res.errors };
  };

  const updateEmployee = async (id: string, input: EmployeeInput): Promise<Employee> => {
    const dto = await apiClient.patch<EmployeeDto>(`/api/v1/employees/${id}`, {
      employeeCode: input.employeeId,
      name: input.name,
      department: input.department,
      phone: input.phone,
      email: input.email,
      role: input.role,
    });
    const employee = mapEmployee(dto);
    setEmployees((es) => es.map((e) => (e.id === id ? employee : e)));
    return employee;
  };

  const removeEmployee = async (id: string): Promise<void> => {
    await apiClient.delete(`/api/v1/employees/${id}`);
    setEmployees((es) => es.filter((e) => e.id !== id));
  };

  // ---- meeting rooms (Company Setup, manager only) ----

  const addMeetingRoom = async (input: MeetingRoomInput): Promise<MeetingRoom> => {
    const room = await apiClient.post<MeetingRoom>('/api/v1/meeting-rooms', {
      name: input.name,
      capacity: Number(input.capacity) || null,
      floor: input.floor,
      photoUrl: input.photoUrl || null,
      description: input.description || null,
    });
    setMeetingRooms((rs) => [...rs, room]);
    return room;
  };

  // CSV bulk import -- see bulkImportEmployees above for the pattern.
  const bulkImportMeetingRooms = async (
    rows: MeetingRoomInput[],
  ): Promise<BulkImportResult<MeetingRoom>> => {
    const res = await apiClient.post<{
      created: MeetingRoom[];
      errors: BulkImportResult<never>['errors'];
    }>('/api/v1/meeting-rooms/bulk', {
      rooms: rows.map((r) => ({
        name: r.name,
        capacity: Number(r.capacity) || null,
        floor: r.floor,
        photoUrl: r.photoUrl || null,
        description: r.description || null,
      })),
    });
    setMeetingRooms((rs) => [...rs, ...res.created]);
    return res;
  };

  const updateMeetingRoom = async (id: string, input: MeetingRoomInput): Promise<MeetingRoom> => {
    const room = await apiClient.patch<MeetingRoom>(`/api/v1/meeting-rooms/${id}`, {
      name: input.name,
      capacity: Number(input.capacity) || null,
      floor: input.floor,
      photoUrl: input.photoUrl || null,
      description: input.description || null,
    });
    setMeetingRooms((rs) => rs.map((r) => (r.id === id ? room : r)));
    return room;
  };

  const removeMeetingRoom = async (id: string): Promise<void> => {
    await apiClient.delete(`/api/v1/meeting-rooms/${id}`);
    setMeetingRooms((rs) => rs.filter((r) => r.id !== id));
  };

  // ---- office locations (clock-in/visitor geofence) ----
  // The first is free on any plan; a second+ requires the enterprise
  // plan (backend 409s with an upgrade message -- see
  // OfficeLocationService, CompanySetupScreen surfaces that message
  // as-is rather than pre-checking the plan client-side).

  const addOfficeLocation = async (input: OfficeLocationInput): Promise<OfficeLocation> => {
    const loc = await apiClient.post<OfficeLocation>('/api/v1/office-locations', input);
    setOfficeLocations((ls) => [...ls, loc]);
    return loc;
  };

  const updateOfficeLocation = async (
    id: string,
    input: OfficeLocationInput,
  ): Promise<OfficeLocation> => {
    const loc = await apiClient.patch<OfficeLocation>(`/api/v1/office-locations/${id}`, input);
    setOfficeLocations((ls) => ls.map((l) => (l.id === id ? loc : l)));
    return loc;
  };

  const removeOfficeLocation = async (id: string): Promise<void> => {
    await apiClient.delete(`/api/v1/office-locations/${id}`);
    setOfficeLocations((ls) => ls.filter((l) => l.id !== id));
  };

  // ---- clock in/out (work attendance) ----

  const clockIn = async (employeeId: string, employeeName: string): Promise<ClockRecord> => {
    const deviceId = await getDeviceId();
    const dto = await apiClient.post<ClockRecordDto>('/api/v1/clock-records/in', {
      employeeId,
      employeeName,
      deviceId,
    });
    const record = mapClockRecord(dto);
    setClockRecords((cs) => [record, ...cs]);
    return record;
  };

  const clockOut = async (employeeId: string, employeeName: string): Promise<ClockRecord> => {
    const deviceId = await getDeviceId();
    const dto = await apiClient.post<ClockRecordDto>('/api/v1/clock-records/out', {
      employeeId,
      employeeName,
      deviceId,
    });
    const record = mapClockRecord(dto);
    setClockRecords((cs) => [record, ...cs]);
    return record;
  };

  // Manager-only -- clears the phone link so the next clock-in from any
  // device re-binds fresh. See ClockCard's "different phone" error and
  // EmployeeDetailScreen's reset button.
  const resetEmployeeDevice = async (id: string): Promise<void> => {
    const dto = await apiClient.post<EmployeeDto>(`/api/v1/employees/${id}/reset-device`, {});
    const employee = mapEmployee(dto);
    setEmployees((es) => es.map((e) => (e.id === id ? employee : e)));
  };

  // clockIn() only updates the clockRecords ledger, not the employees
  // list -- so a staff member's deviceBound flag (set server-side the
  // moment they first clock in) wouldn't show up here until the next
  // full reload. EmployeeDetailScreen calls this on focus so reopening
  // a profile after a clock-in reflects the real lock state.
  const refreshEmployees = async (): Promise<void> => {
    const es = await apiClient.get<EmployeeDto[]>('/api/v1/employees');
    setEmployees(es.map(mapEmployee));
  };

  // Everything above only reflects actions taken in *this* signed-in
  // session -- a receptionist clocking in on their own phone doesn't
  // push anything to a manager's already-open app (no websockets/
  // polling in this build). ManagerClockInsScreen calls this whenever
  // it comes into focus so it actually picks up everyone else's
  // clock-ins/outs instead of showing whatever was loaded at login.
  const refreshClockRecords = async (): Promise<void> => {
    const cr = await apiClient.get<ClockRecordDto[]>('/api/v1/clock-records');
    setClockRecords(cr.map(mapClockRecord));
  };

  // Records are newest-first -- these stay synchronous, derived from the
  // locally-held ledger, so ClockCard's render logic doesn't change.
  const isClockedIn = (employeeId: string): boolean => {
    const mine = clockRecords.find((c) => c.employeeId === employeeId);
    return !!mine && mine.type === 'in';
  };

  const hasClockedInToday = (employeeId: string): boolean => {
    const todayKey = new Date().toDateString();
    return clockRecords.some(
      (c) =>
        c.employeeId === employeeId &&
        c.type === 'in' &&
        new Date(c.timestamp).toDateString() === todayKey,
    );
  };

  // ---- self-service meeting booking ----

  const bookRoom = async (input: BookRoomInput): Promise<RoomBooking> => {
    const dto = await apiClient.post<RoomBookingDto>('/api/v1/room-bookings', {
      roomId: input.roomId || null,
      location: input.roomId ? null : input.location || '',
      title: input.title || 'Meeting',
      startTime: input.startTime,
      endTime: input.endTime,
      participantIds: input.participantIds || [],
      externalGuests: input.externalGuests || [],
      priority: input.priority || 'normal',
    });
    const booking = mapRoomBooking(dto);
    setRoomBookings((rs) => [booking, ...rs]);
    return booking;
  };

  // A participant acknowledging ("seen it") or declining (with a
  // reason) their invite to someone else's meeting.
  const respondToMeeting = async (
    bookingId: string,
    status: 'acknowledged' | 'declined',
    reason?: string,
  ): Promise<void> => {
    const dto = await apiClient.patch<RoomBookingDto>(
      `/api/v1/room-bookings/${bookingId}/respond`,
      {
        status,
        reason,
      },
    );
    const updated = mapRoomBooking(dto);
    setRoomBookings((rs) => rs.map((b) => (b.id === bookingId ? updated : b)));
  };

  // Organiser marking who actually showed up to their own meeting,
  // after the fact -- independent of whether that person acknowledged
  // or declined beforehand.
  const markParticipantAbsent = async (
    bookingId: string,
    employeeId: string,
    absent: boolean,
  ): Promise<void> => {
    const dto = await apiClient.patch<RoomBookingDto>(
      `/api/v1/room-bookings/${bookingId}/participants/${employeeId}/absent`,
      { absent },
    );
    const updated = mapRoomBooking(dto);
    setRoomBookings((rs) => rs.map((b) => (b.id === bookingId ? updated : b)));
  };

  // Same cross-session staleness issue as clock records: roomBookings
  // is only loaded once at login, so a meeting booked in a different
  // signed-in session (e.g. Manager books on their phone, Receptionist
  // is already looking at the Meetings tab on theirs) wouldn't appear
  // without this. AppointmentsScreen calls it on focus.
  const refreshRoomBookings = async (): Promise<void> => {
    const rb = await apiClient.get<RoomBookingDto[]>('/api/v1/room-bookings');
    setRoomBookings(rb.map(mapRoomBooking));
  };

  // ---- appointment rescheduling (Employee & Visitor only) ----

  const rescheduleAppointment = async (
    id: string,
    newScheduledAt: string,
    reason?: string,
  ): Promise<Appointment> => {
    const dto = await apiClient.patch<AppointmentDto>(`/api/v1/appointments/${id}/reschedule`, {
      newScheduledAt,
      reason: reason || '',
    });
    const appointment = mapAppointment(dto);
    setAppointments((as) => as.map((a) => (a.id === id ? appointment : a)));
    return appointment;
  };

  // ---- billing (manager only) ----

  const changePlan = async (planId: string): Promise<Billing> => {
    const dto = await apiClient.patch<BillingDto>('/api/v1/billing/plan', { planId });
    const next = mapBilling(dto);
    setBilling(next);
    return next;
  };

  // ---- in-app notifications ----

  const refreshNotifications = async (): Promise<void> => {
    const n = await apiClient.get<NotificationDto[]>('/api/v1/notifications');
    setNotifications(n.map(mapNotification));
  };

  const markNotificationRead = async (id: string): Promise<void> => {
    const dto = await apiClient.patch<NotificationDto>(`/api/v1/notifications/${id}/read`);
    const updated = mapNotification(dto);
    setNotifications((ns) => ns.map((n) => (n.id === id ? updated : n)));
  };

  const unreadNotificationCount = notifications.filter((n) => !n.read).length;

  // ---- derived stats for the dashboard ----
  const stats = useMemo(() => {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).getTime();

    const todayVisitors = visitors.filter((v) => new Date(v.checkInAt).getTime() >= startOfDay);
    const onsite = visitors.filter((v) => v.status === 'onsite');
    const callsToday = calls.filter((c) => new Date(c.timestamp).getTime() >= startOfDay);
    const monthVisitors = visitors.filter((v) => new Date(v.checkInAt).getTime() >= startOfMonth);
    const pendingApprovals = appointments.filter((a) => a.status === 'pending');

    return {
      visitorsToday: todayVisitors.length,
      onsite: onsite.length,
      callsToday: callsToday.length,
      visitorsThisMonth: monthVisitors.length,
      pendingApprovals: pendingApprovals.length,
    };
  }, [visitors, calls, appointments]);

  return (
    <DataContext.Provider
      value={{
        // collections
        visitors,
        appointments,
        calls,
        nfcCards,
        roomBookings,
        employees,
        meetingRooms,
        officeLocations,
        // lookup helpers
        employeeById,
        roomById,
        // pull-to-refresh
        refreshAll,
        // operations
        registerAndCheckIn,
        checkOutVisitor,
        updateAppointmentStatus,
        admitAppointment,
        logCall,
        addEmployee,
        updateEmployee,
        bulkImportEmployees,
        removeEmployee,
        addMeetingRoom,
        updateMeetingRoom,
        bulkImportMeetingRooms,
        removeMeetingRoom,
        addOfficeLocation,
        updateOfficeLocation,
        removeOfficeLocation,
        bookVisit,
        findAppointmentByCode,
        // work attendance (clock in/out) + appointment rescheduling
        clockRecords,
        clockIn,
        clockOut,
        isClockedIn,
        hasClockedInToday,
        refreshClockRecords,
        resetEmployeeDevice,
        refreshEmployees,
        rescheduleAppointment,
        // self-service room booking
        bookRoom,
        refreshRoomBookings,
        respondToMeeting,
        markParticipantAbsent,
        // billing / subscriptions
        plans,
        billing,
        invoices,
        changePlan,
        // in-app notifications
        notifications,
        unreadNotificationCount,
        refreshNotifications,
        markNotificationRead,
        // derived
        stats,
      }}
    >
      {children}
    </DataContext.Provider>
  );
}

export const useData = (): DataContextValue => {
  const ctx = useContext(DataContext);
  if (!ctx) throw new Error('useData must be used within a DataProvider');
  return ctx;
};

'@
$path = Join-Path (Get-Location) 'src\context\DataContext.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/context/DataContext.tsx'
$written = $written + 1

$content = @'
// VisiLog color system
// -------------------------------------------------------------
// Brand identity: a deep institutional emerald green paired with a
// gold accent (the "access-granted / tap" colour) -- VRA's default.
// Functional status colours stay conventional (green / amber / red)
// so a receptionist can never misread a visitor's state at a glance
// -- kept distinct from any brand colour so the two don't get confused.
//
// buildColors(brandTheme, dark) makes this both multi-tenant and
// light/dark-aware: each Organization carries its own {brand, primary,
// ...} shades, and ThemeContext calls this factory with the signed-in
// user's org (and the current light/dark mode) to produce that org's
// full colors object. Status hues and the brand shades themselves stay
// the same hex in both modes (they're already saturated enough to read
// on a dark background); only neutrals/surfaces and the tint-derived
// primarySurface/primarySurfaceStrong swap per mode.

// An organization's brand shades, as returned by the backend's
// OrganizationDto.theme (see AuthContext) or one of Company Setup's
// preset palettes. These are computed for a light background --
// buildColors derives dark-mode-appropriate tinted surfaces from
// `primary` rather than using primarySurface/primarySurfaceStrong
// as-is when dark=true (see mix() below).
export interface BrandTheme {
  brand: string;
  brandDark: string;
  brandTint: string;
  primary: string;
  primaryPressed: string;
  primarySurface: string;
  primarySurfaceStrong: string;
}

export interface StatusColorSet {
  solid: string;
  bg: string;
  fg: string;
}

export type StatusKey =
  | 'onsite'
  | 'success'
  | 'pending'
  | 'rejected'
  | 'error'
  | 'info'
  | 'neutral';

export interface Colors extends BrandTheme {
  background: string;
  surface: string;
  surfaceAlt: string;

  textPrimary: string;
  textSecondary: string;
  textMuted: string;
  textInverse: string;

  border: string;
  borderStrong: string;

  status: Record<StatusKey, StatusColorSet>;

  palette: typeof palette;
}

const palette = {
  // Brand emerald green (VRA default)
  emerald900: '#0A2A1D', // deepest -- primary text on light surfaces
  emerald800: '#0F3D2A', // brand ink -- nav bars, dark surfaces, logo
  emerald700: '#155636',
  emerald600: '#1D7248',

  // Gold accent (VRA default)
  gold600: '#C9A227', // primary action colour
  gold500: '#D4AF37', // pressed / hover
  gold100: '#F5E6BC',
  gold050: '#FBF3DE',

  // Cool, lobby-clean neutrals (light mode)
  slate900: '#0F172A',
  slate700: '#334155',
  slate500: '#64748B',
  slate400: '#94A3B8',
  slate300: '#CBD5E1',
  slate200: '#E2E8F0',
  slate100: '#EEF2F7',
  slate050: '#F5F7FA',

  white: '#FFFFFF',
  black: '#000000',

  // Status families (high-clarity, conventional) -- solid/fg shared by
  // both modes, bg differs (see LIGHT_STATUS_BG/DARK_STATUS_BG below).
  green600: '#16A34A',
  green100: '#DCFCE7',
  greenDarkBg: '#123322',
  greenDarkFg: '#4ADE80',
  amber600: '#D97706',
  amber100: '#FEF3C7',
  amberDarkBg: '#3A2A0C',
  amberDarkFg: '#FBBF24',
  red600: '#DC2626',
  red100: '#FEE2E2',
  redDarkBg: '#3A1414',
  redDarkFg: '#F87171',
  blue600: '#2563EB',
  blue100: '#DBEAFE',
  blueDarkBg: '#122A4A',
  blueDarkFg: '#60A5FA',

  // Deep, near-black neutrals (dark mode). Deliberately neutral slate,
  // NOT brand-tinted: an earlier green-tinted set made the whole app
  // read as "dark green UI" rather than a dark theme. Brand identity in
  // dark mode comes from the gold/primary accents on buttons, chips and
  // highlights -- the surfaces underneath stay neutral so those accents
  // actually pop instead of blending into a green wash.
  ink900: '#0F1214', // background
  ink800: '#171B1F', // surface
  ink700: '#20262B', // surfaceAlt
  ink600: '#2C333A', // border
  ink500: '#3D454E', // borderStrong
  mist100: '#F2F4F6', // textPrimary
  mist300: '#AEB6BF', // textSecondary
  mist500: '#7C858F', // textMuted
};

// VRA's own brand shades, used when no organization theme is supplied
// (e.g. before login) or as the fallback for the default tenant.
const DEFAULT_BRAND_THEME: BrandTheme = {
  brand: palette.emerald800,
  brandDark: palette.emerald900,
  brandTint: palette.emerald700,
  primary: palette.gold600,
  primaryPressed: palette.gold500,
  primarySurface: palette.gold050,
  primarySurfaceStrong: palette.gold100,
};

// Blends two "#RRGGBB" hexes -- weight is how much of `hexA` to use
// (1 = all hexA, 0 = all hexB). Used to derive a dark-mode-appropriate
// tinted surface from an org's own `primary` color, since the stored
// primarySurface/primarySurfaceStrong are pale tints computed for a
// light background and would look wrong (a near-white chip) on a dark
// one -- this way the tint always scales with whatever brand color the
// org picked, without needing a separate dark value from the backend.
const mix = (hexA: string, hexB: string, weight: number): string => {
  const a = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hexA);
  const b = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hexB);
  if (!a || !b) return hexA;
  const blend = (i: number) => {
    const av = parseInt(a[i], 16);
    const bv = parseInt(b[i], 16);
    return Math.round(av * weight + bv * (1 - weight))
      .toString(16)
      .padStart(2, '0');
  };
  return `#${blend(1)}${blend(2)}${blend(3)}`;
};

export const buildColors = (brandTheme?: BrandTheme | null, dark = false): Colors => {
  const b = brandTheme || DEFAULT_BRAND_THEME;
  return {
    // Brand + primary action -- same hex in both modes (already
    // saturated enough to read on a dark background).
    brand: b.brand,
    brandDark: b.brandDark,
    brandTint: b.brandTint,
    primary: b.primary,
    primaryPressed: b.primaryPressed,

    // Tinted "chip" surfaces behind icons/badges -- derived from the
    // org's own primary color against the current mode's surface, not
    // used as-is in dark mode (see mix() above).
    primarySurface: dark ? mix(b.primary, palette.ink700, 0.18) : b.primarySurface,
    primarySurfaceStrong: dark ? mix(b.primary, palette.ink700, 0.32) : b.primarySurfaceStrong,

    // Surfaces
    background: dark ? palette.ink900 : palette.slate050,
    surface: dark ? palette.ink800 : palette.white,
    surfaceAlt: dark ? palette.ink700 : palette.slate100,

    // Text
    textPrimary: dark ? palette.mist100 : palette.emerald900,
    textSecondary: dark ? palette.mist300 : palette.slate500,
    textMuted: dark ? palette.mist500 : palette.slate400,
    textInverse: palette.white,

    // Lines
    border: dark ? palette.ink600 : palette.slate200,
    borderStrong: dark ? palette.ink500 : palette.slate300,

    // Status: each key carries a fill (solid), a soft surface (bg) and a
    // readable foreground (fg) for text/icons on that surface. `solid`
    // stays the same vivid hue in both modes; `bg`/`fg` swap for
    // contrast against a dark background.
    status: {
      onsite: {
        solid: palette.green600,
        bg: dark ? palette.greenDarkBg : palette.green100,
        fg: dark ? palette.greenDarkFg : '#0B6B33',
      },
      success: {
        solid: palette.green600,
        bg: dark ? palette.greenDarkBg : palette.green100,
        fg: dark ? palette.greenDarkFg : '#0B6B33',
      },
      pending: {
        solid: palette.amber600,
        bg: dark ? palette.amberDarkBg : palette.amber100,
        fg: dark ? palette.amberDarkFg : '#92400E',
      },
      rejected: {
        solid: palette.red600,
        bg: dark ? palette.redDarkBg : palette.red100,
        fg: dark ? palette.redDarkFg : '#991B1B',
      },
      error: {
        solid: palette.red600,
        bg: dark ? palette.redDarkBg : palette.red100,
        fg: dark ? palette.redDarkFg : '#991B1B',
      },
      info: {
        solid: palette.blue600,
        bg: dark ? palette.blueDarkBg : palette.blue100,
        fg: dark ? palette.blueDarkFg : '#1E40AF',
      },
      neutral: {
        solid: palette.slate500,
        bg: dark ? palette.ink700 : palette.slate100,
        fg: dark ? palette.mist300 : palette.slate700,
      },
    },

    // Escape hatch for raw values
    palette,
  };
};

// Default/back-compat static export -- VRA's own colors, light mode.
// Used by pre-login screens before ThemeProvider has resolved the
// device's actual light/dark setting, and as the context's fallback.
export const colors = buildColors();

// "#RRGGBB" -> "r,g,b", for building rgba() strings from a org's brand
// hex shades (e.g. AuthBackground's accent glow on post-login screens).
export const hexToRgb = (hex?: string | null): string => {
  const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex || '');
  if (!m) return '212,175,55';
  return [m[1], m[2], m[3]].map((h) => parseInt(h, 16)).join(',');
};

'@
$path = Join-Path (Get-Location) 'src\theme\colors.ts'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/theme/colors.ts'
$written = $written + 1

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

                {/* Company code -- resolves which organization this login is for */}
                <View style={styles.fieldRow}>
                  <Ionicons name="business-outline" size={18} color="rgba(255,255,255,0.85)" />
                  <TextInput
                    value={companyCode}
                    onChangeText={setCompanyCode}
                    placeholder="Company code"
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
$written = $written + 1

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
                  placeholder="Company code"
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
$written = $written + 1

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
import type { RootStackNavigation } from '../types/navigation';
import type { IoniconName } from '../types';

interface RegisterCompanyScreenProps {
  navigation: RootStackNavigation;
}

// RegisterCompanyScreen -- the self-serve "sign your company up" entry
// point. Only *collects* the form here -- a company can't actually use
// VisiLog (and doesn't get a company code) until the admin has agreed
// to the legal terms and gone through the subscription step on
// LegalAgreementScreen, which is what actually calls registerCompany().
export default function RegisterCompanyScreen({ navigation }: RegisterCompanyScreenProps) {
  const [companyName, setCompanyName] = useState('');
  const [adminName, setAdminName] = useState('');
  const [adminEmail, setAdminEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');

  const onSubmit = () => {
    if (!companyName.trim() || !adminName.trim() || !adminEmail.trim() || !password) {
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
    navigation.navigate('LegalAgreement', {
      pending: {
        companyName: companyName.trim(),
        adminName: adminName.trim(),
        adminEmail: adminEmail.trim(),
        password,
      },
    });
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
            <Pressable onPress={() => navigation.goBack()} style={styles.back} hitSlop={8}>
              <Ionicons name="chevron-back" size={22} color="#FFFFFF" />
            </Pressable>

            <BlurView intensity={25} tint="light" style={styles.card}>
              <View style={styles.cardInner}>
                <Text style={styles.wordmark}>VisiLog</Text>
                <Text style={styles.heading}>Register your company</Text>

                <Field
                  icon="business-outline"
                  placeholder="Company name"
                  value={companyName}
                  onChangeText={setCompanyName}
                />
                <Field
                  icon="person-outline"
                  placeholder="Your full name"
                  value={adminName}
                  onChangeText={setAdminName}
                />
                <Field
                  icon="mail-outline"
                  placeholder="Your work email"
                  value={adminEmail}
                  onChangeText={setAdminEmail}
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
                  style={({ pressed }) => [{ opacity: pressed ? 0.85 : 1 }]}
                >
                  <LinearGradient
                    colors={['#5ECFC9', '#1B8A82', '#0B4A47']}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={styles.submitBtn}
                  >
                    <Text style={styles.submitBtnText}>Continue</Text>
                  </LinearGradient>
                </Pressable>

                <View style={styles.loginRow}>
                  <Text style={styles.loginHint}>Already have a company code? </Text>
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

  submitBtn: {
    height: 50,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: spacing.sm,
  },
  submitBtnText: { fontFamily: fonts.bold, fontSize: 16, color: '#FFFFFF', letterSpacing: 0.3 },

  loginRow: { flexDirection: 'row', justifyContent: 'center', marginTop: spacing.lg },
  loginHint: { fontFamily: fonts.regular, fontSize: 13, color: 'rgba(255,255,255,0.85)' },
  loginLink: { fontFamily: fonts.bold, fontSize: 13, color: '#FFFFFF' },
});

'@
$path = Join-Path (Get-Location) 'src\screens\RegisterCompanyScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/RegisterCompanyScreen.tsx'
$written = $written + 1

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
                        placeholder="Company code"
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
$written = $written + 1

$content = @'
import React, { useState } from 'react';
import { View, StyleSheet, Switch, Alert, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Button, Input, Avatar, Badge } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import type { RootStackNavigation } from '../types/navigation';
import type { IoniconName } from '../types';

interface SettingsScreenProps {
  navigation: RootStackNavigation;
}

// SettingsScreen
// Per the VisiLog spec: profile info, password change, notification
// preferences, organisation branding, sign-out.
export default function SettingsScreen({ navigation }: SettingsScreenProps) {
  const { colors, dark, setOrgTheme, setDarkOverride } = useTheme();
  const { user, logout, updateProfile } = useAuth();
  const { plans, billing } = useData();

  // Priority support is just a listed perk on the Pro/Enterprise plan's
  // features array (see V20 migration) -- no separate enforcement
  // needed since nothing is being blocked, just a different badge and
  // help message shown below.
  const currentPlan = plans.find((p) => p.id === billing?.planId);
  const hasPrioritySupport = !!currentPlan?.features.includes('Priority support');

  const [notifyAppts, setNotifyAppts] = useState(true);
  const [notifyCalls, setNotifyCalls] = useState(true);

  const [editingName, setEditingName] = useState(false);
  const [nameDraft, setNameDraft] = useState(user?.name || '');
  const [savingName, setSavingName] = useState(false);

  const onSaveName = async () => {
    setSavingName(true);
    const result = await updateProfile(nameDraft);
    setSavingName(false);
    if (!result.ok) {
      Alert.alert('Could not update your name', result.error || 'Something went wrong.');
      return;
    }
    setEditingName(false);
  };

  const [editingPassword, setEditingPassword] = useState(false);
  const [currentPw, setCurrentPw] = useState('');
  const [newPw, setNewPw] = useState('');
  const [confirmPw, setConfirmPw] = useState('');

  const onSavePassword = () => {
    if (!currentPw || !newPw || !confirmPw) {
      Alert.alert('Missing fields', 'Fill in all three password fields.');
      return;
    }
    if (newPw.length < 8) {
      Alert.alert('Too short', 'New password must be at least 8 characters.');
      return;
    }
    if (newPw !== confirmPw) {
      Alert.alert('Mismatch', "New passwords don't match.");
      return;
    }
    Alert.alert('Password updated', 'Your password has been changed.');
    setCurrentPw('');
    setNewPw('');
    setConfirmPw('');
    setEditingPassword(false);
  };

  const onLogout = () => {
    Alert.alert('Sign out?', "You'll need to sign in again to access VisiLog.", [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Sign out',
        style: 'destructive',
        onPress: () => {
          logout();
          setOrgTheme(null);
        },
      },
    ]);
  };

  return (
    <Screen>
      <Header
        title="Settings"
        subtitle="Profile, preferences & administration"
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      {/* Profile */}
      <Card>
        <View style={styles.profileRow}>
          <Avatar name={user?.name || 'You'} size={56} />
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="h3">{user?.name || 'Receptionist'}</Text>
            <Text variant="caption" color={colors.textSecondary}>
              {user?.email || ''}
            </Text>
            <View style={{ flexDirection: 'row', marginTop: 4 }}>
              <Badge label={user?.role || 'Receptionist'} status="info" size="sm" dot={false} />
            </View>
          </View>
        </View>

        {/* Only the display name is editable here: email is the login
            identity, and role is fixed at signup from the staff roster
            (see AuthService.signup), so neither belongs behind a
            self-service edit. */}
        {editingName ? (
          <View style={{ marginTop: spacing.md }}>
            <Input
              label="Display name"
              value={nameDraft}
              onChangeText={setNameDraft}
              placeholder="Your name"
              icon="person-outline"
            />
            <View style={{ flexDirection: 'row' }}>
              <Button
                label="Cancel"
                variant="ghost"
                onPress={() => {
                  setEditingName(false);
                  setNameDraft(user?.name || '');
                }}
                style={{ flex: 1, marginRight: spacing.xs }}
              />
              <Button
                label={savingName ? 'Saving...' : 'Save'}
                onPress={onSaveName}
                disabled={savingName}
                style={{ flex: 1, marginLeft: spacing.xs }}
              />
            </View>
          </View>
        ) : (
          <Button
            label="Change display name"
            variant="secondary"
            icon="create-outline"
            onPress={() => {
              setNameDraft(user?.name || '');
              setEditingName(true);
            }}
            style={{ marginTop: spacing.md }}
          />
        )}
      </Card>

      {/* Password */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Security
      </Text>
      <Card>
        {editingPassword ? (
          <>
            <Input
              label="Current password"
              value={currentPw}
              onChangeText={setCurrentPw}
              placeholder="Current password"
              icon="lock-closed-outline"
              secureTextEntry
            />
            <Input
              label="New password"
              value={newPw}
              onChangeText={setNewPw}
              placeholder="New password"
              icon="key-outline"
              secureTextEntry
              hint="Must be at least 8 characters."
            />
            <Input
              label="Confirm new password"
              value={confirmPw}
              onChangeText={setConfirmPw}
              placeholder="Repeat new password"
              icon="shield-checkmark-outline"
              secureTextEntry
            />
            <View style={{ flexDirection: 'row' }}>
              <Button
                label="Cancel"
                variant="ghost"
                onPress={() => setEditingPassword(false)}
                style={{ flex: 1, marginRight: spacing.xs }}
              />
              <Button
                label="Save"
                onPress={onSavePassword}
                style={{ flex: 1, marginLeft: spacing.xs }}
              />
            </View>
          </>
        ) : (
          <Pressable onPress={() => setEditingPassword(true)} style={styles.linkRow}>
            <View style={[styles.linkIcon, { backgroundColor: colors.surfaceAlt }]}>
              <Ionicons name="key-outline" size={18} color={colors.brand} />
            </View>
            <View style={{ flex: 1 }}>
              <Text variant="bodySemibold">Change password</Text>
              <Text variant="caption" color={colors.textSecondary}>
                Update the password used to sign in.
              </Text>
            </View>
            <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
          </Pressable>
        )}
      </Card>

      {/* Appearance */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Appearance
      </Text>
      <Card padded={false}>
        <ToggleRow
          label="Dark mode"
          sub="Use a dark color scheme throughout the app."
          value={dark}
          onChange={setDarkOverride}
        />
      </Card>

      {/* Notifications -- these toggles are about staff workflow (someone
 else pre-booking, missing a call, a card being tapped), which
 means nothing to a visitor account, so this whole section is
 staff-only. */}
      {user?.role !== 'visitor' ? (
        <>
          <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
            Notifications
          </Text>
          <Card padded={false}>
            <ToggleRow
              label="New appointment alerts"
              sub="Notify me when a visitor pre-books."
              value={notifyAppts}
              onChange={setNotifyAppts}
            />
            <Divider />
            <ToggleRow
              label="Missed call alerts"
              sub="Push a reminder for unreturned calls."
              value={notifyCalls}
              onChange={setNotifyCalls}
            />
            {/* No "NFC access events" toggle: standalone NFC cards have
                no backend model yet (the per-visit pass code lives on the
                appointment), so there are no card-tap events to notify
                about. Re-add this alongside real card issuance. */}
          </Card>
        </>
      ) : null}

      {/* Organisation -- administration for the whole tenant, so only the
 Manager/Administrator who owns that org sees it. Everyone else's
 settings are about their own account, not the company's. */}
      {user?.role === 'manager' ? (
        <>
          <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
            Organisation
          </Text>
          <Card padded={false}>
            <LinkRow
              icon="card-outline"
              title="Billing & subscription"
              sub={`${user.organizationName} - manage plan & invoices`}
              onPress={() => navigation.navigate('Billing')}
            />
            <Divider />
            <LinkRow
              icon="business-outline"
              title="Company Setup"
              sub="Branding, office location, staff & rooms"
              onPress={() => navigation.navigate('CompanySetup')}
            />
            <Divider />
            <LinkRow icon="globe-outline" title="Languages" sub="English (default)" />
          </Card>
        </>
      ) : null}

      {/* About */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        About
      </Text>
      <Card padded={false}>
        <LinkRow
          icon="information-circle-outline"
          title="VisiLog"
          sub="Build 1.0.0 - Reception + NFC"
          onPress={() =>
            Alert.alert(
              'VisiLog',
              'Build 1.0.0 -- Reception + NFC\n\nVisitor management, staff attendance, and meeting-room booking for ' +
                (user?.organizationName || 'your organization') +
                '.',
            )
          }
        />
        <Divider />
        <LinkRow
          icon="help-circle-outline"
          title="Help & support"
          badge={user?.role === 'manager' && hasPrioritySupport ? 'Priority' : undefined}
          sub={
            user?.role === 'manager'
              ? hasPrioritySupport
                ? 'Priority line to the VisiLog team'
                : 'Contact the VisiLog help desk'
              : 'Contact your VisiLog administrator'
          }
          onPress={() =>
            Alert.alert(
              'Help & support',
              user?.role === 'manager'
                ? hasPrioritySupport
                  ? 'Your plan includes priority support -- reach the VisiLog team directly for a faster response:\n\nPhone: 0509343709\nEmail: voldyabbey@gmail.com'
                  : "As the Administrator, reach the VisiLog help desk directly for anything you can't resolve in Company Setup:\n\nPhone: 0509343709\nEmail: voldyabbey@gmail.com"
                : "For access issues, incorrect roster entries, or anything else you need changed, contact your organization's Administrator -- they manage your staff roster and company settings in Company Setup.",
            )
          }
        />
        <Divider />
        <LinkRow
          icon="document-text-outline"
          title="Privacy policy"
          sub="How visitor data is collected & stored"
          onPress={() =>
            Alert.alert(
              'Privacy policy',
              'Visitor and staff data you enter (name, phone, purpose of visit, badge/NFC activity) is stored for ' +
                (user?.organizationName || 'your organization') +
                ' only, and is never shared with other companies using VisiLog. ' +
                "It's used solely to run reception, attendance, and meeting-room booking for your organization.",
            )
          }
        />
      </Card>

      <Button
        label="Sign out"
        variant="dangerSubtle"
        icon="log-out-outline"
        onPress={onLogout}
        style={{ marginTop: spacing.xl }}
      />
    </Screen>
  );
}

function ToggleRow({
  label,
  sub,
  value,
  onChange,
}: {
  label: string;
  sub: string;
  value: boolean;
  onChange: (value: boolean) => void;
}) {
  const { colors } = useTheme();
  return (
    <View style={styles.toggleRow}>
      <View style={{ flex: 1, marginRight: spacing.sm }}>
        <Text variant="bodySemibold">{label}</Text>
        <Text variant="caption" color={colors.textSecondary}>
          {sub}
        </Text>
      </View>
      <Switch
        value={value}
        onValueChange={onChange}
        trackColor={{ false: colors.borderStrong, true: colors.primary }}
        thumbColor="#FFFFFF"
      />
    </View>
  );
}

function LinkRow({
  icon,
  title,
  sub,
  badge,
  onPress,
}: {
  icon: IoniconName;
  title: string;
  sub?: string;
  badge?: string;
  onPress?: () => void;
}) {
  const { colors } = useTheme();
  return (
    <Pressable style={styles.linkRow} onPress={onPress}>
      <View style={[styles.linkIcon, { backgroundColor: colors.surfaceAlt }]}>
        <Ionicons name={icon} size={18} color={colors.brand} />
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="bodySemibold">{title}</Text>
        {sub ? (
          <Text variant="caption" color={colors.textSecondary}>
            {sub}
          </Text>
        ) : null}
      </View>
      {badge ? (
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: spacing.xs }}>
          <Badge label={badge} status="info" size="sm" dot={false} />
          <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
        </View>
      ) : (
        <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
      )}
    </Pressable>
  );
}

function Divider() {
  const { colors } = useTheme();
  return <View style={[styles.divider, { backgroundColor: colors.border }]} />;
}

const styles = StyleSheet.create({
  profileRow: { flexDirection: 'row', alignItems: 'center' },
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  toggleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing.md,
  },
  linkRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing.md,
  },
  linkIcon: {
    width: 32,
    height: 32,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, marginLeft: spacing.md + 32 + spacing.sm },
});

'@
$path = Join-Path (Get-Location) 'src\screens\SettingsScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/SettingsScreen.tsx'
$written = $written + 1

$content = @'
import React from 'react';
import {
  Pressable,
  ActivityIndicator,
  View,
  StyleSheet,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import type { IoniconName } from '../types';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';

const HEIGHTS = { sm: 40, md: 48, lg: 56 };

type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger' | 'dangerSubtle';
type ButtonSize = keyof typeof HEIGHTS;

interface ButtonProps {
  label: string;
  onPress?: () => void;
  variant?: ButtonVariant;
  size?: ButtonSize;
  icon?: IoniconName;
  iconPosition?: 'left' | 'right';
  loading?: boolean;
  disabled?: boolean;
  fullWidth?: boolean;
  style?: StyleProp<ViewStyle>;
}

// Active-voice labels please: "Register visitor", not "Submit".
export default function Button({
  label,
  onPress,
  variant = 'primary',
  size = 'md',
  icon,
  iconPosition = 'left',
  loading = false,
  disabled = false,
  fullWidth = true,
  style,
}: ButtonProps) {
  const { colors } = useTheme();
  // Built per-render (cheap, a handful of keys) so a signed-in org's
  // brand color flows straight into every button without a reload.
  const VARIANTS = {
    primary: {
      bg: colors.primary,
      fg: colors.textInverse,
      border: 'transparent',
      pressed: colors.primaryPressed,
    },
    secondary: {
      bg: colors.surface,
      fg: colors.brand,
      border: colors.border,
      pressed: colors.surfaceAlt,
    },
    ghost: {
      bg: 'transparent',
      fg: colors.primary,
      border: 'transparent',
      pressed: colors.primarySurface,
    },
    danger: {
      bg: colors.status.error.solid,
      fg: colors.textInverse,
      border: 'transparent',
      pressed: '#B91C1C',
    },
    // Red-tinted rather than solid red: for destructive actions that
    // sit among ordinary rows (Sign out) where a full red slab would
    // shout louder than it deserves. Label AND icon both take the red
    // foreground -- on the solid `danger` variant the icon has to be
    // white to stay legible, so a genuinely red icon needs this.
    dangerSubtle: {
      bg: colors.status.error.bg,
      fg: colors.status.error.fg,
      border: colors.status.error.fg,
      pressed: colors.status.error.solid,
    },
  };
  const v = VARIANTS[variant] || VARIANTS.primary;
  const isDisabled = disabled || loading;
  const height = HEIGHTS[size] || HEIGHTS.md;
  const labelVariant = size === 'sm' ? 'label' : 'bodySemibold';

  return (
    <Pressable
      onPress={onPress}
      disabled={isDisabled}
      accessibilityRole="button"
      accessibilityState={{ disabled: isDisabled, busy: loading }}
      style={({ pressed }) => [
        styles.base,
        {
          height,
          backgroundColor: pressed && !isDisabled ? v.pressed : v.bg,
          borderColor: v.border,
        },
        v.border !== 'transparent' && styles.bordered,
        fullWidth && styles.fullWidth,
        isDisabled && styles.disabled,
        style,
      ]}
    >
      {loading ? (
        <ActivityIndicator color={v.fg} />
      ) : (
        <View style={styles.content}>
          {icon && iconPosition === 'left' ? (
            <Ionicons name={icon} size={18} color={v.fg} style={styles.iconLeft} />
          ) : null}
          <Text variant={labelVariant} color={v.fg}>
            {label}
          </Text>
          {icon && iconPosition === 'right' ? (
            <Ionicons name={icon} size={18} color={v.fg} style={styles.iconRight} />
          ) : null}
        </View>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.lg,
  },
  bordered: { borderWidth: 1 },
  fullWidth: { alignSelf: 'stretch' },
  disabled: { opacity: 0.45 },
  content: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center' },
  iconLeft: { marginRight: 8 },
  iconRight: { marginLeft: 8 },
});

'@
$path = Join-Path (Get-Location) 'src\components\Button.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/Button.tsx'
$written = $written + 1

$content = @'
import React, { useState } from 'react';
import { View, Modal, Pressable, FlatList, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import type { IoniconName, Option } from '../types';

interface SelectProps<T> {
  label?: string;
  placeholder?: string;
  value?: T | null;
  options?: Option<T>[];
  onChange?: (value: T) => void;
  icon?: IoniconName;
  error?: string;
  /** Shown inside the picker when `options` is empty, so the user
   * learns WHY there's nothing to choose (e.g. no rooms added yet)
   * instead of staring at a blank sheet. */
  emptyMessage?: string;
}

// A labelled "select"-style field. Tapping it opens a modal list of
// options. Use for: purpose of visit, host employee, call type, etc.
export default function Select<T>({
  label,
  placeholder = 'Select...',
  value,
  options = [],
  onChange,
  icon,
  error,
  emptyMessage,
}: SelectProps<T>) {
  const { colors } = useTheme();
  const [open, setOpen] = useState(false);
  const selected = options.find((o) => o.value === value);

  return (
    <View style={{ marginBottom: spacing.md }}>
      {label ? (
        <Text variant="label" color={colors.textSecondary} style={{ marginBottom: 6 }}>
          {label}
        </Text>
      ) : null}

      <Pressable
        onPress={() => setOpen(true)}
        style={[
          styles.field,
          { backgroundColor: colors.surface, borderColor: colors.border },
          error && { borderColor: colors.status.error.solid },
        ]}
      >
        {icon ? (
          <Ionicons name={icon} size={18} color={colors.textMuted} style={{ marginRight: 8 }} />
        ) : null}
        <Text
          variant="body"
          color={selected ? colors.textPrimary : colors.textMuted}
          style={{ flex: 1 }}
          numberOfLines={1}
        >
          {selected ? selected.label : placeholder}
        </Text>
        <Ionicons name="chevron-down" size={18} color={colors.textMuted} />
      </Pressable>

      {error ? (
        <Text variant="caption" color={colors.status.error.solid} style={{ marginTop: 4 }}>
          {error}
        </Text>
      ) : null}

      <Modal visible={open} transparent animationType="fade" onRequestClose={() => setOpen(false)}>
        <Pressable style={styles.backdrop} onPress={() => setOpen(false)}>
          <Pressable
            style={[styles.sheet, { backgroundColor: colors.surface }]}
            onPress={(e) => e.stopPropagation()}
          >
            <View style={[styles.handle, { backgroundColor: colors.borderStrong }]} />
            {label ? (
              <Text variant="h3" style={{ marginBottom: spacing.sm }}>
                {label}
              </Text>
            ) : null}

            <FlatList
              data={options}
              ListEmptyComponent={
                <View style={styles.empty}>
                  <Text variant="bodyMd" color={colors.textSecondary} style={{ textAlign: 'center' }}>
                    {emptyMessage || 'Nothing to choose from yet.'}
                  </Text>
                </View>
              }
              keyExtractor={(item) => String(item.value)}
              ItemSeparatorComponent={() => (
                <View style={[styles.sep, { backgroundColor: colors.border }]} />
              )}
              renderItem={({ item }) => {
                const active = item.value === value;
                return (
                  <Pressable
                    onPress={() => {
                      onChange?.(item.value);
                      setOpen(false);
                    }}
                    style={styles.row}
                  >
                    <View style={{ flex: 1 }}>
                      <Text variant="bodySemibold">{item.label}</Text>
                      {item.sublabel ? (
                        <Text variant="caption" color={colors.textSecondary}>
                          {item.sublabel}
                        </Text>
                      ) : null}
                    </View>
                    {active ? (
                      <Ionicons name="checkmark-circle" size={20} color={colors.primary} />
                    ) : null}
                  </Pressable>
                );
              }}
            />
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    height: 48,
  },
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(14, 27, 44, 0.45)',
    justifyContent: 'flex-end',
  },
  sheet: {
    borderTopLeftRadius: radius.xl,
    borderTopRightRadius: radius.xl,
    paddingHorizontal: spacing.md,
    paddingTop: spacing.sm,
    paddingBottom: spacing.xl,
    maxHeight: '70%',
  },
  handle: {
    width: 36,
    height: 4,
    borderRadius: 2,
    alignSelf: 'center',
    marginBottom: spacing.sm,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing.sm,
  },
  empty: { paddingVertical: spacing.xl, paddingHorizontal: spacing.md },
  sep: { height: 1 },
});

'@
$path = Join-Path (Get-Location) 'src\components\Select.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/Select.tsx'
$written = $written + 1

$content = @'
import React, { useState } from 'react';
import { View, Modal, Pressable, FlatList, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import Button from './Button';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import type { IoniconName, Option } from '../types';

interface MultiSelectProps<T> {
  label?: string;
  placeholder?: string;
  values?: T[];
  options?: Option<T>[];
  onChange?: (values: T[]) => void;
  icon?: IoniconName;
  /** Shown inside the picker when `options` is empty, explaining why. */
  emptyMessage?: string;
}

// Like Select, but lets the user tick more than one option before
// closing the sheet -- used for picking meeting attendees from the
// whole staff directory (not just a single host).
export default function MultiSelect<T>({
  label,
  placeholder = 'Select...',
  values = [],
  options = [],
  onChange,
  icon,
  emptyMessage,
}: MultiSelectProps<T>) {
  const { colors } = useTheme();
  const [open, setOpen] = useState(false);
  const selectedLabels = options.filter((o) => values.includes(o.value)).map((o) => o.label);

  const toggle = (value: T) => {
    if (values.includes(value)) {
      onChange?.(values.filter((v) => v !== value));
    } else {
      onChange?.([...values, value]);
    }
  };

  const summary =
    selectedLabels.length === 0
      ? placeholder
      : selectedLabels.length <= 2
        ? selectedLabels.join(', ')
        : `${selectedLabels.length} people selected`;

  return (
    <View style={{ marginBottom: spacing.md }}>
      {label ? (
        <Text variant="label" color={colors.textSecondary} style={{ marginBottom: 6 }}>
          {label}
        </Text>
      ) : null}

      <Pressable
        onPress={() => setOpen(true)}
        style={[styles.field, { backgroundColor: colors.surface, borderColor: colors.border }]}
      >
        {icon ? (
          <Ionicons name={icon} size={18} color={colors.textMuted} style={{ marginRight: 8 }} />
        ) : null}
        <Text
          variant="body"
          color={selectedLabels.length ? colors.textPrimary : colors.textMuted}
          style={{ flex: 1 }}
          numberOfLines={1}
        >
          {summary}
        </Text>
        <Ionicons name="chevron-down" size={18} color={colors.textMuted} />
      </Pressable>

      <Modal visible={open} transparent animationType="fade" onRequestClose={() => setOpen(false)}>
        <Pressable style={styles.backdrop} onPress={() => setOpen(false)}>
          <Pressable
            style={[styles.sheet, { backgroundColor: colors.surface }]}
            onPress={(e) => e.stopPropagation()}
          >
            <View style={[styles.handle, { backgroundColor: colors.borderStrong }]} />
            {label ? (
              <Text variant="h3" style={{ marginBottom: spacing.sm }}>
                {label}
              </Text>
            ) : null}

            <FlatList
              data={options}
              ListEmptyComponent={
                <View style={styles.empty}>
                  <Text variant="bodyMd" color={colors.textSecondary} style={{ textAlign: 'center' }}>
                    {emptyMessage || 'Nothing to choose from yet.'}
                  </Text>
                </View>
              }
              keyExtractor={(item) => String(item.value)}
              ItemSeparatorComponent={() => (
                <View style={[styles.sep, { backgroundColor: colors.border }]} />
              )}
              renderItem={({ item }) => {
                const active = values.includes(item.value);
                return (
                  <Pressable onPress={() => toggle(item.value)} style={styles.row}>
                    <View
                      style={[
                        styles.checkbox,
                        { borderColor: colors.borderStrong },
                        active && { backgroundColor: colors.primary, borderColor: colors.primary },
                      ]}
                    >
                      {active ? <Ionicons name="checkmark" size={14} color="#FFF" /> : null}
                    </View>
                    <View style={{ flex: 1, marginLeft: spacing.sm }}>
                      <Text variant="bodySemibold">{item.label}</Text>
                      {item.sublabel ? (
                        <Text variant="caption" color={colors.textSecondary}>
                          {item.sublabel}
                        </Text>
                      ) : null}
                    </View>
                  </Pressable>
                );
              }}
            />

            <Button label="Done" onPress={() => setOpen(false)} style={{ marginTop: spacing.sm }} />
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    height: 48,
  },
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(14, 27, 44, 0.45)',
    justifyContent: 'flex-end',
  },
  sheet: {
    borderTopLeftRadius: radius.xl,
    borderTopRightRadius: radius.xl,
    paddingHorizontal: spacing.md,
    paddingTop: spacing.sm,
    paddingBottom: spacing.xl,
    maxHeight: '70%',
  },
  handle: {
    width: 36,
    height: 4,
    borderRadius: 2,
    alignSelf: 'center',
    marginBottom: spacing.sm,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing.sm,
  },
  checkbox: {
    width: 20,
    height: 20,
    borderRadius: 6,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  empty: { paddingVertical: spacing.xl, paddingHorizontal: spacing.md },
  sep: { height: 1 },
});

'@
$path = Join-Path (Get-Location) 'src\components\MultiSelect.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/MultiSelect.tsx'
$written = $written + 1

$content = @'
import React from 'react';
import { View, StyleSheet } from 'react-native';
import Text from './Text';
import Button from './Button';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';

// Chrome for breaking one long form into a few short ones. Two pieces,
// used together but kept separate so a screen can put its own content
// between them:
//
//   <StepProgress steps={[...]} current={step} />
//   ...fields for the current step...
//   <StepNav ... />
//
// Deliberately NOT a wrapper component that owns the step state: the
// screen still decides what "valid enough to continue" means for each
// step, which differs a lot between forms (a booking can't advance
// without a room; Company Setup can skip almost anything).

interface StepProgressProps {
  /** Short labels, one per step, e.g. ['Details', 'People', 'When']. */
  steps: string[];
  /** Zero-based index of the step being shown. */
  current: number;
}

export function StepProgress({ steps, current }: StepProgressProps) {
  const { colors } = useTheme();
  return (
    <View style={styles.progressWrap}>
      <View style={styles.barRow}>
        {steps.map((label, i) => (
          <View
            key={label}
            style={[
              styles.barSegment,
              { backgroundColor: i <= current ? colors.primary : colors.border },
              i > 0 && { marginLeft: 4 },
            ]}
          />
        ))}
      </View>
      <Text variant="caption" color={colors.textSecondary}>
        Step {current + 1} of {steps.length} - {steps[current]}
      </Text>
    </View>
  );
}

interface StepNavProps {
  current: number;
  total: number;
  onBack: () => void;
  onNext: () => void;
  /** Label for the forward button on the LAST step (e.g. 'Book meeting'). */
  finishLabel: string;
  finishIcon?: React.ComponentProps<typeof Button>['icon'];
  loading?: boolean;
}

export function StepNav({
  current,
  total,
  onBack,
  onNext,
  finishLabel,
  finishIcon,
  loading = false,
}: StepNavProps) {
  const isLast = current === total - 1;
  return (
    <View style={styles.navRow}>
      {/* No Back on the first step -- there's nothing behind it, and a
          disabled button there just looks broken. */}
      {current > 0 ? (
        <Button
          label="Back"
          variant="secondary"
          icon="chevron-back"
          onPress={onBack}
          disabled={loading}
          style={{ flex: 1, marginRight: spacing.xs }}
        />
      ) : null}
      <Button
        label={isLast ? finishLabel : 'Next'}
        icon={isLast ? finishIcon : 'chevron-forward'}
        iconPosition="right"
        onPress={onNext}
        loading={loading}
        style={{ flex: 1, marginLeft: current > 0 ? spacing.xs : 0 }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  progressWrap: { marginBottom: spacing.md },
  barRow: { flexDirection: 'row', marginBottom: 6 },
  barSegment: { flex: 1, height: 4, borderRadius: radius.pill },
  navRow: { flexDirection: 'row', marginTop: spacing.md },
});

'@
$path = Join-Path (Get-Location) 'src\components\FormSteps.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/FormSteps.tsx'
$written = $written + 1

$content = @'
import React, { useRef, useState } from 'react';
import { View, Pressable, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Card from './Card';
import Button from './Button';
import Input from './Input';
import Select from './Select';
import MultiSelect from './MultiSelect';
import Segmented from './Segmented';
import Text from './Text';
import { DatePicker, TimePicker } from './QuickDateTime';
import { StepProgress, StepNav } from './FormSteps';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { ApiError } from '../api/client';
import type { ExternalGuest } from '../types';

type LocationType = 'room' | 'outside';
type Priority = 'normal' | 'important' | 'urgent';

interface BookMeetingFormProps {
  onDone?: () => void;
}

// BookMeetingForm -- self-service internal meeting booking. Shared by
// Employee, Manager (EmployeeBookScreen) and Receptionist (the
// "Internal meeting" pane on VisitorBookingScreen), so an
// Administrator or anyone else can invite whoever they need -- not
// just their own direct reports -- and can book either one of the
// company's meeting rooms or an outside location (a client's office,
// a restaurant, etc.) for meetings that don't happen on-site. The
// organiser is derived server-side from the signed-in user's own
// employee record -- see RoomBookingController.
//
// Split across four steps rather than one very long scroll: on a phone
// the single-page version ran well past two screenfuls, so the Book
// button was invisible from the top and it was genuinely unclear
// whether anything was still required. Order follows what has to be
// decided first -- you can't invite people to a meeting that doesn't
// have a subject or a place yet -- and the last step is a plain
// summary, because the one thing worth double-checking before
// committing is the details, not re-editing them.
const STEPS = ['Details', 'People', 'When', 'Review'];

export default function BookMeetingForm({ onDone }: BookMeetingFormProps) {
  const { colors } = useTheme();
  const { employees, meetingRooms, bookRoom } = useData();

  const [title, setTitle] = useState('');
  const [locationType, setLocationType] = useState<LocationType>('room');
  const [roomId, setRoomId] = useState<string | null>(null);
  const [outsideLocation, setOutsideLocation] = useState('');
  const [attendeeIds, setAttendeeIds] = useState<string[]>([]);
  const [externalGuests, setExternalGuests] = useState<ExternalGuest[]>([]);
  const [guestName, setGuestName] = useState('');
  const [guestEmail, setGuestEmail] = useState('');
  const [guestPhone, setGuestPhone] = useState('');
  const [priority, setPriority] = useState<Priority>('normal');
  const [date, setDate] = useState(formatDate(new Date()));
  const [startTime, setStartTime] = useState('10:00');
  const [endTime, setEndTime] = useState('11:00');
  const [submitting, setSubmitting] = useState(false);
  const submittingRef = useRef(false);
  const [step, setStep] = useState(0);

  const onAddGuest = () => {
    if (!guestName.trim()) {
      Alert.alert('Almost there', "Give the guest's name.");
      return;
    }
    if (!guestEmail.trim() && !guestPhone.trim()) {
      Alert.alert(
        'Almost there',
        'Add an email or phone number so the guest can actually be reached.',
      );
      return;
    }
    setExternalGuests((gs) => [
      ...gs,
      {
        name: guestName.trim(),
        email: guestEmail.trim() || null,
        phone: guestPhone.trim() || null,
      },
    ]);
    setGuestName('');
    setGuestEmail('');
    setGuestPhone('');
  };

  const onRemoveGuest = (index: number) => {
    setExternalGuests((gs) => gs.filter((_, i) => i !== index));
  };

  // Step 1 is the only one with anything mandatory: a meeting needs a
  // subject and somewhere to happen. Attendees are optional (a solo
  // room booking is legitimate) and the times always have a value.
  const detailsProblem = (): string | null => {
    if (!title.trim()) return 'Give the meeting a title.';
    if (locationType === 'room' && !roomId) return 'Pick a meeting room.';
    if (locationType === 'outside' && !outsideLocation.trim()) return 'Enter a location.';
    return null;
  };

  const onNext = () => {
    if (step === 0) {
      const problem = detailsProblem();
      if (problem) {
        Alert.alert('Almost there', problem);
        return;
      }
    }
    if (step === STEPS.length - 1) {
      onSubmit();
      return;
    }
    setStep((s) => s + 1);
  };

  const onSubmit = async () => {
    if (submittingRef.current) return;
    // Re-checked here rather than trusting that step 1 was passed --
    // this is what actually guards the API call.
    const problem = detailsProblem();
    if (problem) {
      Alert.alert('Almost there', problem);
      setStep(0);
      return;
    }
    submittingRef.current = true;
    setSubmitting(true);
    try {
      await bookRoom({
        title: title.trim(),
        roomId: locationType === 'room' ? roomId : null,
        location: locationType === 'outside' ? outsideLocation.trim() : '',
        startTime: toInstant(date, startTime),
        endTime: toInstant(date, endTime),
        participantIds: attendeeIds,
        externalGuests,
        priority,
      });
      Alert.alert('Booked', `${title} is on the calendar.`, [{ text: 'Done', onPress: onDone }]);
    } catch (err) {
      Alert.alert(
        'Could not book meeting',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
    } finally {
      submittingRef.current = false;
      setSubmitting(false);
    }
  };

  const placeLabel =
    locationType === 'room'
      ? meetingRooms.find((r) => r.id === roomId)?.name || 'No room picked'
      : outsideLocation.trim() || 'No location entered';
  const peopleCount = attendeeIds.length + externalGuests.length;

  return (
    <>
      <Card>
        <StepProgress steps={STEPS} current={step} />

        {step === 0 ? (
          <>
        <Input
          label="Meeting title"
          value={title}
          onChangeText={setTitle}
          placeholder="e.g. Candidate interview"
          icon="briefcase-outline"
        />

        <Segmented
          value={locationType}
          onChange={(v) => {
            setLocationType(v);
            setRoomId(null);
            setOutsideLocation('');
          }}
          options={[
            { label: 'Meeting room', value: 'room' },
            { label: 'Outside location', value: 'outside' },
          ]}
          style={{ marginBottom: spacing.md }}
        />

        <Segmented
          value={priority}
          onChange={setPriority}
          options={[
            { label: 'Normal', value: 'normal' },
            { label: 'Important', value: 'important' },
            { label: 'Urgent', value: 'urgent' },
          ]}
          style={{ marginBottom: spacing.md }}
        />

        {locationType === 'room' ? (
          <Select
            label="Room"
            placeholder="Pick a room..."
            value={roomId}
            onChange={setRoomId}
            icon="business-outline"
            options={meetingRooms.map((r) => ({
              label: r.name,
              value: r.id,
              sublabel: `${r.floor} - Capacity ${r.capacity}`,
            }))}
            emptyMessage={
              'No meeting rooms have been set up yet.\n\n' +
              'Ask your Administrator to add one in Company Setup > Meeting rooms, ' +
              'or switch to "Outside location" above to book somewhere else.'
            }
          />
        ) : (
          <Input
            label="Location"
            value={outsideLocation}
            onChangeText={setOutsideLocation}
            placeholder="e.g. Client's office, Accra Mall"
            icon="location-outline"
          />
        )}
          </>
        ) : null}

        {step === 1 ? (
          <>
        <MultiSelect
          label="Invite staff (optional)"
          placeholder="Anyone from the staff directory..."
          values={attendeeIds}
          onChange={setAttendeeIds}
          icon="people-outline"
          options={employees.map((e) => ({
            label: e.name,
            value: e.id,
            sublabel: e.department,
          }))}
          emptyMessage={
            'No staff have been added to the directory yet.\n\n' +
            'Ask your Administrator to add them in Company Setup > Staff roster. ' +
            'You can still invite outside guests below.'
          }
        />

        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>
          Outside guests (optional)
        </Text>
        {externalGuests.map((g, i) => (
          <View key={i} style={[styles.guestRow, { borderColor: colors.border }]}>
            <View style={{ flex: 1 }}>
              <Text variant="bodySemibold">{g.name}</Text>
              <Text variant="caption" color={colors.textSecondary}>
                {[g.email, g.phone].filter(Boolean).join(' - ')}
              </Text>
            </View>
            <Pressable onPress={() => onRemoveGuest(i)} hitSlop={8}>
              <Ionicons name="close-circle" size={20} color={colors.textMuted} />
            </Pressable>
          </View>
        ))}
        <Input
          label="Guest name"
          value={guestName}
          onChangeText={setGuestName}
          placeholder="e.g. Kwame Mensah (client)"
          icon="person-add-outline"
        />
        <View style={styles.guestContactRow}>
          <View style={{ flex: 1 }}>
            <Input
              label="Email"
              value={guestEmail}
              onChangeText={setGuestEmail}
              placeholder="them@example.com"
              icon="mail-outline"
              autoCapitalize="none"
              keyboardType="email-address"
            />
          </View>
          <View style={{ width: spacing.sm }} />
          <View style={{ flex: 1 }}>
            <Input
              label="Phone"
              value={guestPhone}
              onChangeText={setGuestPhone}
              placeholder="Optional"
              icon="call-outline"
              keyboardType="phone-pad"
            />
          </View>
        </View>
        <Pressable
          onPress={onAddGuest}
          style={[styles.addGuestBtn, { borderColor: colors.primary }]}
        >
          <Ionicons name="add-circle-outline" size={18} color={colors.primary} />
          <Text variant="bodySemibold" color={colors.primary} style={{ marginLeft: 6 }}>
            Add guest
          </Text>
        </Pressable>
          </>
        ) : null}

        {step === 2 ? (
          <>
        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>
          Date
        </Text>
        <DatePicker value={date} onChange={setDate} />
        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>
          Start time
        </Text>
        <TimePicker value={startTime} onChange={setStartTime} />
        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>
          End time
        </Text>
        <TimePicker value={endTime} onChange={setEndTime} />
          </>
        ) : null}

        {step === 3 ? (
          <>
            <Text variant="h3" style={{ marginBottom: spacing.sm }}>
              {title.trim() || 'Untitled meeting'}
            </Text>
            <SummaryRow icon="location-outline" label="Where" value={placeLabel} />
            <SummaryRow icon="calendar-outline" label="Date" value={date} />
            <SummaryRow icon="time-outline" label="Time" value={`${startTime} - ${endTime}`} />
            <SummaryRow
              icon="people-outline"
              label="People"
              value={
                peopleCount === 0
                  ? 'Just you'
                  : `${peopleCount} invited` +
                    (externalGuests.length ? ` (${externalGuests.length} outside)` : '')
              }
            />
            <SummaryRow
              icon="flag-outline"
              label="Priority"
              value={priority.charAt(0).toUpperCase() + priority.slice(1)}
            />
            <Text variant="caption" color={colors.textSecondary} style={{ marginTop: spacing.sm }}>
              Tap Back to change anything. Everyone invited gets a notification, and outside
              guests are emailed an invitation.
            </Text>
          </>
        ) : null}
      </Card>

      <StepNav
        current={step}
        total={STEPS.length}
        onBack={() => setStep((s) => Math.max(0, s - 1))}
        onNext={onNext}
        finishLabel="Book meeting"
        finishIcon="checkmark-circle-outline"
        loading={submitting}
      />
    </>
  );
}

function SummaryRow({
  icon,
  label,
  value,
}: {
  icon: React.ComponentProps<typeof Ionicons>['name'];
  label: string;
  value: string;
}) {
  const { colors } = useTheme();
  return (
    <View style={styles.summaryRow}>
      <Ionicons name={icon} size={16} color={colors.textMuted} />
      <Text variant="caption" color={colors.textSecondary} style={styles.summaryLabel}>
        {label}
      </Text>
      <Text variant="bodyMd" style={{ flex: 1, textAlign: 'right' }} numberOfLines={2}>
        {value}
      </Text>
    </View>
  );
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

// The backend expects a full ISO instant (with seconds + timezone);
// "YYYY-MM-DDTHH:MM" alone isn't parseable as one and was silently
// failing every booking with a generic "Something went wrong" error.
// Routing through a real Date and toISOString() also correctly
// converts from the device's local time to UTC.
function toInstant(dateStr: string, timeStr: string): string {
  return new Date(`${dateStr}T${timeStr}:00`).toISOString();
}

const styles = StyleSheet.create({
  chipsLabel: { marginBottom: spacing.xs },
  summaryRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 6 },
  summaryLabel: { marginLeft: 8, width: 68 },
  guestRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.sm,
    marginBottom: spacing.sm,
  },
  guestContactRow: { flexDirection: 'row' },
  addGuestBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderRadius: radius.md,
    borderStyle: 'dashed',
    height: 44,
    marginBottom: spacing.md,
  },
});

'@
$path = Join-Path (Get-Location) 'src\components\BookMeetingForm.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/BookMeetingForm.tsx'
$written = $written + 1

$content = @'
// Single import point: `import { Button, Card, Badge } from '../components'`
export { default as Text } from './Text';
export { default as Screen } from './Screen';
export { default as Header } from './Header';
export { default as Button } from './Button';
export { default as Card } from './Card';
export { default as Badge } from './Badge';
export { default as Input } from './Input';
export { default as Avatar } from './Avatar';
export { default as EmptyState } from './EmptyState';
export { default as StatTile } from './StatTile';
export { default as Segmented } from './Segmented';
export { default as Select } from './Select';
export { default as ListItem } from './ListItem';
export { default as CompanyMapSection } from './CompanyMapSection';
export { default as ClockCard } from './ClockCard';
export { default as RescheduleModal } from './RescheduleModal';
export { default as MultiSelect } from './MultiSelect';
export { default as BookMeetingForm } from './BookMeetingForm';
export { default as CsvImportModal } from './CsvImportModal';
export { default as ExportModal } from './ExportModal';
export { DatePicker, TimePicker } from './QuickDateTime';
export { StepProgress, StepNav } from './FormSteps';

'@
$path = Join-Path (Get-Location) 'src\components\index.ts'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/index.ts'
$written = $written + 1

$content = @'
import React, { useState } from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import Input from './Input';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';

const pad = (n: number): string => String(n).padStart(2, '0');

interface DatePickerProps {
  value: string;
  onChange: (dateStr: string) => void;
}

// A single "Pick a date" control. This used to also show a scrolling row
// of quick-pick chips (Today / Tomorrow / Thu 30 ...) above the picker,
// which meant two competing ways to set one field and a very tall form
// -- the chips are gone and only the picker remains.
//
// Deliberately a plain text field rather than the OS date picker module:
// keeps this working in stock Expo Go instead of requiring a custom dev
// client build.
export function DatePicker({ value, onChange }: DatePickerProps) {
  const { colors } = useTheme();
  const [open, setOpen] = useState(false);
  const expanded = open || !!value;

  return (
    <View style={styles.wrap}>
      <Pressable
        onPress={() => setOpen((o) => !o)}
        style={[
          styles.toggle,
          { borderColor: colors.border, backgroundColor: colors.surface },
          expanded && { backgroundColor: colors.primary, borderColor: colors.primary },
        ]}
      >
        <Ionicons
          name="calendar-outline"
          size={16}
          color={expanded ? colors.textInverse : colors.textPrimary}
        />
        <Text
          variant="label"
          color={expanded ? colors.textInverse : colors.textPrimary}
          style={{ marginLeft: 6 }}
        >
          {value ? `Date: ${value}` : 'Pick a date'}
        </Text>
      </Pressable>
      {expanded ? (
        <Input
          value={value}
          onChangeText={onChange}
          placeholder="YYYY-MM-DD"
          icon="calendar-outline"
          style={{ marginTop: spacing.xs }}
        />
      ) : null}
    </View>
  );
}

interface TimePickerProps {
  value: string;
  onChange: (timeStr: string) => void;
}

// Single "Pick a time" control -- opens an hour/minute stepper. Same
// reasoning as DatePicker: the half-hour quick-pick chip row that used
// to sit above this has been removed.
export function TimePicker({ value, onChange }: TimePickerProps) {
  const { colors } = useTheme();
  const [open, setOpen] = useState(false);
  const expanded = open || !!value;

  return (
    <View style={styles.wrap}>
      <Pressable
        onPress={() => setOpen((o) => !o)}
        style={[
          styles.toggle,
          { borderColor: colors.border, backgroundColor: colors.surface },
          expanded && { backgroundColor: colors.primary, borderColor: colors.primary },
        ]}
      >
        <Ionicons
          name="time-outline"
          size={16}
          color={expanded ? colors.textInverse : colors.textPrimary}
        />
        <Text
          variant="label"
          color={expanded ? colors.textInverse : colors.textPrimary}
          style={{ marginLeft: 6 }}
        >
          {value ? `Time: ${value}` : 'Pick a time'}
        </Text>
      </Pressable>
      {expanded ? <TimeStepper value={value} onChange={onChange} /> : null}
    </View>
  );
}

function TimeStepper({ value, onChange }: { value: string; onChange: (t: string) => void }) {
  const { colors } = useTheme();
  const [hStr, mStr] = (value || '09:00').split(':');
  const h = Number(hStr) || 0;
  const m = Number(mStr) || 0;

  const setHour = (next: number) => onChange(`${pad(((next % 24) + 24) % 24)}:${pad(m)}`);
  const setMinute = (next: number) => onChange(`${pad(h)}:${pad(((next % 60) + 60) % 60)}`);

  return (
    <View style={[stepperStyles.wrap, { borderColor: colors.border }]}>
      <StepperColumn
        value={pad(h)}
        onUp={() => setHour(h + 1)}
        onDown={() => setHour(h - 1)}
        colors={colors}
      />
      <Text variant="h2" style={stepperStyles.colon}>
        :
      </Text>
      <StepperColumn
        value={pad(m)}
        onUp={() => setMinute(m + 5)}
        onDown={() => setMinute(m - 5)}
        colors={colors}
      />
    </View>
  );
}

function StepperColumn({
  value,
  onUp,
  onDown,
  colors,
}: {
  value: string;
  onUp: () => void;
  onDown: () => void;
  colors: { primarySurface: string; primary: string };
}) {
  return (
    <View style={stepperStyles.col}>
      <Pressable
        onPress={onUp}
        style={[stepperStyles.btn, { backgroundColor: colors.primarySurface }]}
      >
        <Ionicons name="chevron-up" size={18} color={colors.primary} />
      </Pressable>
      <Text variant="h2" style={stepperStyles.value}>
        {value}
      </Text>
      <Pressable
        onPress={onDown}
        style={[stepperStyles.btn, { backgroundColor: colors.primarySurface }]}
      >
        <Ionicons name="chevron-down" size={18} color={colors.primary} />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { marginBottom: spacing.md },
  toggle: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.pill,
    borderWidth: 1,
  },
});

const stepperStyles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingVertical: spacing.md,
    marginTop: spacing.xs,
  },
  col: { alignItems: 'center', width: 64 },
  btn: {
    width: 44,
    height: 32,
    borderRadius: radius.sm,
    alignItems: 'center',
    justifyContent: 'center',
  },
  value: { marginVertical: 4 },
  colon: { marginHorizontal: spacing.sm },
});

'@
$path = Join-Path (Get-Location) 'src\components\QuickDateTime.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/QuickDateTime.tsx'
$written = $written + 1

$content = @'
import React, { useRef, useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen,
  Header,
  Text,
  Card,
  Button,
  Input,
  Select,
  DatePicker,
  TimePicker,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { visitPurposes } from '../data/mockData';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';

interface VisitorBookScreenProps {
  navigation: RootStackNavigation;
}

// VisitorBookScreen -- the visitor's own "Book" tab. Same fields as the
// form that used to live on VisitorHomeScreen, given a more formal,
// sectioned treatment (distinct headers per group) since it's now a
// dedicated screen rather than embedded on the dashboard.
export default function VisitorBookScreen({ navigation }: VisitorBookScreenProps) {
  const { colors } = useTheme();
  const { user } = useAuth();
  const { employees, bookVisit } = useData();

  const [name, setName] = useState(user!.name || '');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState(user!.email || '');
  const [company, setCompany] = useState('');
  const [purpose, setPurpose] = useState('Official Business');
  const [otherPurpose, setOtherPurpose] = useState('');
  const [hostId, setHostId] = useState<string | null>(null);
  const [date, setDate] = useState(formatDate(new Date()));
  const [time, setTime] = useState('10:00');
  const [submitting, setSubmitting] = useState(false);
  const submittingRef = useRef(false);

  const onSubmit = async () => {
    if (submittingRef.current) {
      Alert.alert('Already booking', 'Your booking is already being submitted.');
      return;
    }
    if (!name.trim() || !phone.trim() || !hostId) {
      Alert.alert('Almost there', 'Name, phone and host are required.');
      return;
    }
    if (purpose === 'Other' && !otherPurpose.trim()) {
      Alert.alert('Almost there', 'Please describe the purpose of your visit.');
      return;
    }
    if (!date.trim() || !time.trim()) {
      Alert.alert('Almost there', 'Pick a date and time for your visit.');
      return;
    }
    submittingRef.current = true;
    setSubmitting(true);
    try {
      await bookVisit({
        visitorName: name,
        visitorPhone: phone,
        visitorEmail: email,
        visitorCompany: company,
        purpose: purpose === 'Other' ? otherPurpose.trim() : purpose,
        hostId,
        scheduledAt: toInstant(date, time),
      });
      Alert.alert(
        'Booked',
        "Your visit request has been sent. You'll get a notification with your pass code once your host approves it.",
        [{ text: 'Done', onPress: () => navigation.navigate('Home') }],
      );
    } catch (err) {
      Alert.alert(
        'Could not book visit',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
    } finally {
      submittingRef.current = false;
      setSubmitting(false);
    }
  };

  return (
    <Screen>
      <Header
        eyebrow="Pre-registration"
        title="Book a visit"
        subtitle="Complete each section below to request an appointment"
      />

      <Text variant="label" color={colors.brand} style={styles.sectionLabel}>
        1 - Your details
      </Text>
      <Card>
        <Input label="Full name" value={name} onChangeText={setName} icon="person-outline" />
        <Input
          label="Phone"
          value={phone}
          onChangeText={setPhone}
          icon="call-outline"
          keyboardType="phone-pad"
        />
        <Input
          label="Email (optional)"
          value={email}
          onChangeText={setEmail}
          icon="mail-outline"
          autoCapitalize="none"
          keyboardType="email-address"
        />
        <Input
          label="Company (optional)"
          value={company}
          onChangeText={setCompany}
          icon="business-outline"
        />
      </Card>

      <Text variant="label" color={colors.brand} style={styles.sectionLabel}>
        2 - Visit details
      </Text>
      <Card>
        <Select
          label="Purpose"
          value={purpose}
          onChange={setPurpose}
          icon="briefcase-outline"
          options={visitPurposes.map((p) => ({ label: p, value: p }))}
        />
        {purpose === 'Other' ? (
          <Input
            label="Please specify"
            value={otherPurpose}
            onChangeText={setOtherPurpose}
            placeholder="What's the purpose of your visit?"
            icon="create-outline"
          />
        ) : null}
        <Select
          label="Who are you visiting?"
          value={hostId}
          onChange={setHostId}
          icon="people-outline"
          placeholder="Pick a host..."
          options={employees.map((e) => ({
            label: e.name,
            value: e.id,
            sublabel: e.department,
          }))}
        />
      </Card>

      <Text variant="label" color={colors.brand} style={styles.sectionLabel}>
        3 - When
      </Text>
      <Card>
        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>
          Date
        </Text>
        <DatePicker value={date} onChange={setDate} />
        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>
          Time
        </Text>
        <TimePicker value={time} onChange={setTime} />
      </Card>

      <View style={[styles.notice, { backgroundColor: colors.primarySurface }]}>
        <Ionicons name="information-circle" size={18} color={colors.primary} />
        <Text variant="caption" color={colors.brand} style={{ marginLeft: 8, flex: 1 }}>
          You'll receive an NFC pass code once submitted -- show it at reception on arrival.
        </Text>
      </View>

      <Button
        label="Submit booking"
        icon="checkmark-circle-outline"
        onPress={onSubmit}
        loading={submitting}
        style={{ marginTop: spacing.sm }}
      />
    </Screen>
  );
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

// The backend expects a full ISO instant (with seconds + timezone);
// "YYYY-MM-DDTHH:MM" alone isn't parseable as one.
function toInstant(dateStr: string, timeStr: string): string {
  return new Date(`${dateStr}T${timeStr}:00`).toISOString();
}

const styles = StyleSheet.create({
  sectionLabel: { marginTop: spacing.lg, marginBottom: spacing.xs, textTransform: 'uppercase' },
  chipsLabel: { marginBottom: spacing.xs },
  notice: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    borderRadius: radius.md,
    padding: spacing.sm,
    marginTop: spacing.md,
  },
});

'@
$path = Join-Path (Get-Location) 'src\screens\VisitorBookScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/VisitorBookScreen.tsx'
$written = $written + 1

$content = @'
import React, { useState } from 'react';
import { View, Image, StyleSheet, Alert, Pressable, Share } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import * as Location from 'expo-location';
import { Screen, Header, Text, Card, Button, Input } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type { BrandTheme, IoniconName, OfficeLocation } from '../types';

// Resolves to null if `promise` hasn't settled within `ms`. Used to put
// a ceiling on a GPS fix, which has no built-in timeout.
function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T | null> {
  return Promise.race([
    promise,
    new Promise<null>((resolve) => setTimeout(() => resolve(null), ms)),
  ]);
}

interface CompanySetupScreenProps {
  navigation: RootStackNavigation;
}

// A handful of ready-made brand palettes, so a manager can restyle the
// app without needing a full color-picker UI.
const THEME_PRESETS: { id: string; label: string; theme: BrandTheme }[] = [
  {
    id: 'emerald',
    label: 'Emerald & gold',
    theme: {
      brand: '#0F3D2A',
      brandDark: '#0A2A1D',
      brandTint: '#155636',
      primary: '#C9A227',
      primaryPressed: '#D4AF37',
      primarySurface: '#FBF3DE',
      primarySurfaceStrong: '#F5E6BC',
    },
  },
  {
    id: 'navy',
    label: 'Navy & sky',
    theme: {
      brand: '#1B2A4A',
      brandDark: '#101A30',
      brandTint: '#25396B',
      primary: '#4F8EF7',
      primaryPressed: '#3B76DD',
      primarySurface: '#EAF1FE',
      primarySurfaceStrong: '#D3E3FD',
    },
  },
  {
    id: 'wine',
    label: 'Wine & gold',
    theme: {
      brand: '#5C1A1A',
      brandDark: '#3D1010',
      brandTint: '#7A2626',
      primary: '#E0A62B',
      primaryPressed: '#C48F20',
      primarySurface: '#FDF3DF',
      primarySurfaceStrong: '#F8E4B8',
    },
  },
  {
    id: 'plum',
    label: 'Plum & rose',
    theme: {
      brand: '#3B1D4A',
      brandDark: '#28132F',
      brandTint: '#512A66',
      primary: '#E0679F',
      primaryPressed: '#C74F86',
      primarySurface: '#FCEAF3',
      primarySurfaceStrong: '#F7D2E5',
    },
  },
];

// CompanySetupScreen -- Manager/Administrator only, reachable from
// Settings > Organisation > "Company branding". Covers everything the
// self-serve onboarding story needs after registration: sharing the
// company code, branding, and the office location that backs the
// clock-in geofence check. Staff roster (Directory) and meeting rooms
// each have their own dedicated screens, linked from here.
export default function CompanySetupScreen({ navigation }: CompanySetupScreenProps) {
  const { colors } = useTheme();
  const { organization, updateOrganization } = useAuth();
  const { officeLocations, addOfficeLocation, updateOfficeLocation, removeOfficeLocation } =
    useData();

  const [name, setName] = useState(organization?.name || '');
  const [logoUrl, setLogoUrl] = useState(organization?.logoUrl || '');
  const [wifiNetworkName, setWifiNetworkName] = useState(organization?.wifiNetworkName || '');
  const [savingBrand, setSavingBrand] = useState(false);
  const [pickingLogo, setPickingLogo] = useState(false);

  const onPickLogo = async () => {
    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) {
      Alert.alert('Permission needed', 'Allow photo library access to upload a logo.');
      return;
    }
    setPickingLogo(true);
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ['images'],
        allowsEditing: true,
        aspect: [1, 1],
        quality: 0.6,
        base64: true,
      });
      if (result.canceled) return;
      const asset = result.assets[0];
      if (!asset.base64) {
        Alert.alert('Could not read image', 'Please try a different photo.');
        return;
      }
      setLogoUrl(`data:${asset.mimeType || 'image/jpeg'};base64,${asset.base64}`);
    } finally {
      setPickingLogo(false);
    }
  };

  // Office locations -- an org can have more than one (see
  // DataContext.officeLocations); `editingId` is null while adding a
  // new one, or an existing location's id while editing it. The
  // backend allows one free on any plan and 409s with an upgrade
  // message on a second, which onSaveLocation surfaces as-is rather
  // than pre-checking the plan here.
  const [formOpen, setFormOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [locName, setLocName] = useState('');
  const [latitude, setLatitude] = useState('');
  const [longitude, setLongitude] = useState('');
  const [radiusMeters, setRadiusMeters] = useState('500');
  const [savingLocation, setSavingLocation] = useState(false);
  const [locating, setLocating] = useState(false);
  // Set once a GPS attempt has failed -- reveals the manual latitude/
  // longitude fields. They stay hidden until then on purpose: typing
  // coordinates is the fallback, not the way this is meant to be used.
  const [gpsFailed, setGpsFailed] = useState(false);

  const onStartAddLocation = () => {
    setEditingId(null);
    setLocName('');
    setLatitude('');
    setLongitude('');
    setRadiusMeters('500');
    // Each new form starts on the GPS-first path again -- a failure
    // last time doesn't mean this attempt will fail too.
    setGpsFailed(false);
    setFormOpen(true);
  };

  const onStartEditLocation = (loc: OfficeLocation) => {
    setEditingId(loc.id);
    setLocName(loc.name);
    setLatitude(String(loc.latitude));
    setLongitude(String(loc.longitude));
    setRadiusMeters(String(loc.radiusMeters));
    setGpsFailed(false);
    setFormOpen(true);
  };

  // Fills lat/lng from the phone's own GPS instead of making someone
  // look up coordinates manually -- stand at the office and tap this.
  //
  // Every failure path here ends by revealing the manual coordinate
  // fields (setGpsFailed). Without that, a manager whose phone can't
  // get a fix -- indoors, location services off, permission declined --
  // has no way at all to set an office location, and since clock-in is
  // gated on being inside one, that silently breaks attendance for the
  // whole company with nothing on screen explaining why.
  const onUseCurrentLocation = async () => {
    setLocating(true);
    try {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        setGpsFailed(true);
        Alert.alert(
          'Permission needed',
          'Allow location access to use your current position, or enter the coordinates yourself below.',
        );
        return;
      }

      // A fresh GPS fix indoors can take a very long time (or never
      // arrive) on Android, and getCurrentPositionAsync has no timeout
      // of its own -- left alone it spins forever and reads as a
      // broken button. Fall back to the last known fix, and give up
      // after 15 seconds either way.
      const position =
        (await Location.getLastKnownPositionAsync({ maxAge: 5 * 60 * 1000 })) ??
        (await withTimeout(
          Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced }),
          15000,
        ));

      if (!position) {
        setGpsFailed(true);
        Alert.alert(
          'Could not get location',
          'Your phone did not return a position in time. Try again outdoors, or enter the coordinates yourself below.',
        );
        return;
      }

      setLatitude(String(position.coords.latitude));
      setLongitude(String(position.coords.longitude));
      setGpsFailed(false);
    } catch {
      setGpsFailed(true);
      Alert.alert(
        'Could not get location',
        'Enable location services and try again, or enter the coordinates yourself below.',
      );
    } finally {
      setLocating(false);
    }
  };

  const onShareCode = () => {
    Share.share({
      message: `Join ${organization?.name} on VisiLog. Company code: ${organization?.code}`,
    }).catch(() => {});
  };

  const onSaveBrand = async () => {
    if (!name.trim()) {
      Alert.alert('Almost there', 'Give your company a name.');
      return;
    }
    setSavingBrand(true);
    const result = await updateOrganization({
      name: name.trim(),
      logoUrl: logoUrl.trim() || null,
      wifiNetworkName: wifiNetworkName.trim() || null,
    });
    setSavingBrand(false);
    if (!result.ok) Alert.alert('Could not save', result.error);
  };

  const onPickPreset = async (preset: (typeof THEME_PRESETS)[number]) => {
    setSavingBrand(true);
    const result = await updateOrganization({ theme: preset.theme });
    setSavingBrand(false);
    if (!result.ok) Alert.alert('Could not save', result.error);
  };

  const onSaveLocation = async () => {
    if (!locName.trim()) {
      Alert.alert('Almost there', 'Give this location a name (e.g. "Head Office").');
      return;
    }
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const radius = parseInt(radiusMeters, 10) || 500;
    if (Number.isNaN(lat) || Number.isNaN(lng)) {
      Alert.alert(
        'Almost there',
        'Tap "Use my current location" while standing at that office first.',
      );
      return;
    }
    setSavingLocation(true);
    try {
      const input = { name: locName.trim(), latitude: lat, longitude: lng, radiusMeters: radius };
      if (editingId) {
        await updateOfficeLocation(editingId, input);
      } else {
        await addOfficeLocation(input);
      }
      setFormOpen(false);
      Alert.alert('Saved', 'Staff will need to be within range of this location to clock in.');
    } catch (err) {
      Alert.alert(
        'Could not save',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
    } finally {
      setSavingLocation(false);
    }
  };

  const onRemoveLocation = (loc: OfficeLocation) => {
    Alert.alert(
      'Remove this location?',
      `Staff will no longer be able to clock in at ${loc.name}.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: () =>
            removeOfficeLocation(loc.id).catch((err) =>
              Alert.alert(
                'Could not remove location',
                err instanceof ApiError ? err.message : 'Something went wrong.',
              ),
            ),
        },
      ],
    );
  };

  return (
    <Screen>
      <Header
        title="Company Setup"
        subtitle="Branding, office location, staff & rooms"
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      {/* Company code */}
      <Card accent="info">
        <Text variant="caption" color={colors.textSecondary}>
          Company code
        </Text>
        <View style={styles.codeRow}>
          <Text style={[styles.code, { color: colors.brand }]}>{organization?.code}</Text>
          <Pressable
            onPress={onShareCode}
            style={[styles.shareBtn, { backgroundColor: colors.primarySurface }]}
          >
            <Ionicons name="share-outline" size={16} color={colors.primary} />
            <Text variant="caption" color={colors.brand} style={{ marginLeft: 4 }}>
              Share
            </Text>
          </Pressable>
        </View>
        <Text variant="caption" color={colors.textMuted}>
          Give this to your staff and post it wherever you invite visitors -- they enter it when
          they sign up.
        </Text>
      </Card>

      {/* Branding */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Branding
      </Text>
      <Card>
        <Input label="Company name" value={name} onChangeText={setName} icon="business-outline" />

        <Text variant="label" color={colors.textSecondary} style={styles.logoLabel}>
          Logo
        </Text>
        <Pressable onPress={onPickLogo} disabled={pickingLogo} style={styles.logoRow}>
          <View
            style={[
              styles.logoPreview,
              { borderColor: colors.border, backgroundColor: colors.surfaceAlt },
            ]}
          >
            {logoUrl ? (
              <Image source={{ uri: logoUrl }} style={styles.logoImage} resizeMode="cover" />
            ) : (
              <Ionicons name="image-outline" size={22} color={colors.textMuted} />
            )}
          </View>
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="bodySemibold" color={colors.brand}>
              {pickingLogo ? 'Opening photos...' : logoUrl ? 'Change logo' : 'Upload a logo'}
            </Text>
            <Text variant="caption" color={colors.textMuted}>
              From your device's photo library
            </Text>
          </View>
        </Pressable>

        <Input
          label="...or paste a logo URL"
          value={logoUrl}
          onChangeText={setLogoUrl}
          placeholder="https://..."
          icon="link-outline"
          autoCapitalize="none"
        />
        <Input
          label="WiFi network name"
          value={wifiNetworkName}
          onChangeText={setWifiNetworkName}
          placeholder="e.g. Office-WiFi"
          icon="wifi-outline"
        />
        <Text
          variant="caption"
          color={colors.textMuted}
          style={{ marginTop: -6, marginBottom: spacing.sm }}
        >
          Shown to staff as a reminder of which network to join before clocking in.
        </Text>
        <Button
          label={savingBrand ? 'Saving...' : 'Save'}
          onPress={onSaveBrand}
          disabled={savingBrand}
        />
      </Card>

      <Card style={{ marginTop: spacing.sm }}>
        <Text variant="bodySemibold" style={{ marginBottom: spacing.sm }}>
          Color theme
        </Text>
        <View style={styles.presetGrid}>
          {THEME_PRESETS.map((p) => (
            <Pressable key={p.id} onPress={() => onPickPreset(p)} style={styles.presetItem}>
              <View style={styles.presetSwatches}>
                <View style={[styles.swatch, { backgroundColor: p.theme.brand }]} />
                <View style={[styles.swatch, { backgroundColor: p.theme.primary }]} />
              </View>
              <Text variant="caption" color={colors.textSecondary}>
                {p.label}
              </Text>
            </Pressable>
          ))}
        </View>
      </Card>

      {/* Office locations -- the first is free on any plan; a second+
          requires the enterprise plan (see onSaveLocation, which just
          surfaces the backend's upgrade message if it's rejected). */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Office locations
      </Text>
      <Card padded={false}>
        {officeLocations.length === 0 ? (
          <View style={{ padding: spacing.md }}>
            <Text variant="caption" color={colors.textSecondary}>
              No locations set yet. Staff can clock in from anywhere until you add one.
            </Text>
          </View>
        ) : (
          officeLocations.map((loc, i) => (
            <View key={loc.id}>
              <View style={styles.linkRow}>
                <View style={[styles.linkIcon, { backgroundColor: colors.surfaceAlt }]}>
                  <Ionicons name="location-outline" size={18} color={colors.brand} />
                </View>
                <View style={{ flex: 1 }}>
                  <Text variant="bodySemibold">{loc.name}</Text>
                  <Text variant="caption" color={colors.textSecondary}>
                    {loc.radiusMeters}m radius
                  </Text>
                </View>
                <Pressable onPress={() => onStartEditLocation(loc)} style={{ padding: 6 }}>
                  <Ionicons name="create-outline" size={20} color={colors.textMuted} />
                </Pressable>
                <Pressable onPress={() => onRemoveLocation(loc)} style={{ padding: 6 }}>
                  <Ionicons name="trash-outline" size={20} color={colors.status.rejected.solid} />
                </Pressable>
              </View>
              {i < officeLocations.length - 1 && (
                <View style={[styles.divider, { backgroundColor: colors.border }]} />
              )}
            </View>
          ))
        )}
      </Card>

      {!formOpen && (
        <Button
          label="Add office location"
          icon="add-circle-outline"
          variant="secondary"
          onPress={onStartAddLocation}
          style={{ marginTop: spacing.sm }}
        />
      )}

      {formOpen && (
        <Card style={{ marginTop: spacing.sm }}>
          <Text variant="bodySemibold" style={{ marginBottom: spacing.sm }}>
            {editingId ? 'Edit location' : 'New location'}
          </Text>
          <Input
            label="Name"
            value={locName}
            onChangeText={setLocName}
            placeholder="e.g. Head Office"
            icon="business-outline"
          />
          <Button
            label={locating ? 'Getting your location...' : 'Use my current location'}
            icon="locate"
            variant="secondary"
            onPress={onUseCurrentLocation}
            disabled={locating}
            style={{ marginBottom: spacing.md }}
          />
          <View style={[styles.locationStatus, { backgroundColor: colors.surfaceAlt }]}>
            <Ionicons
              name={
                latitude.trim() && longitude.trim() ? 'checkmark-circle' : 'alert-circle-outline'
              }
              size={18}
              color={latitude.trim() && longitude.trim() ? colors.primary : colors.textMuted}
            />
            <Text variant="bodyMd" color={colors.textSecondary} style={{ marginLeft: 8 }}>
              {latitude.trim() && longitude.trim() ? 'Location set' : 'No location set yet'}
            </Text>
          </View>

          {/* Only appears once GPS has actually failed -- see gpsFailed.
              These fields were deliberately removed as the primary way
              to set a location (nobody should have to type coordinates
              normally), but with no fallback at all a phone that can't
              get a fix leaves the whole company unable to clock in. */}
          {gpsFailed ? (
            <View style={{ marginTop: spacing.sm }}>
              <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: 6 }}>
                Or enter the coordinates yourself: open Google Maps, press and hold on your
                office, and copy the two numbers it shows.
              </Text>
              <Input
                label="Latitude"
                value={latitude}
                onChangeText={setLatitude}
                placeholder="e.g. 5.6037"
                icon="navigate-outline"
                keyboardType="numbers-and-punctuation"
              />
              <Input
                label="Longitude"
                value={longitude}
                onChangeText={setLongitude}
                placeholder="e.g. -0.1870"
                icon="navigate-outline"
                keyboardType="numbers-and-punctuation"
              />
            </View>
          ) : null}

          <Input
            label="Radius (meters)"
            value={radiusMeters}
            onChangeText={setRadiusMeters}
            placeholder="e.g. 500"
            icon="radio-outline"
            keyboardType="number-pad"
          />
          <View style={{ flexDirection: 'row' }}>
            <Button
              label="Cancel"
              variant="ghost"
              onPress={() => setFormOpen(false)}
              style={{ flex: 1, marginRight: spacing.xs }}
            />
            <Button
              label={savingLocation ? 'Saving...' : 'Save'}
              onPress={onSaveLocation}
              disabled={savingLocation}
              style={{ flex: 1, marginLeft: spacing.xs }}
            />
          </View>
        </Card>
      )}

      {/* Staff & rooms */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Staff & rooms
      </Text>
      <Card padded={false}>
        <LinkRow
          icon="people-outline"
          title="Staff roster"
          sub="Add employees & set their roles"
          onPress={() => navigation.navigate('Directory')}
        />
        <View style={[styles.divider, { backgroundColor: colors.border }]} />
        <LinkRow
          icon="business-outline"
          title="Meeting rooms"
          sub="Add or remove bookable rooms"
          onPress={() => navigation.navigate('MeetingRooms')}
        />
        <View style={[styles.divider, { backgroundColor: colors.border }]} />
        <LinkRow
          icon="document-text-outline"
          title="Legal agreement"
          sub="The subscription terms your company agreed to"
          onPress={() => navigation.navigate('LegalAgreement')}
        />
      </Card>
    </Screen>
  );
}

function LinkRow({
  icon,
  title,
  sub,
  onPress,
}: {
  icon: IoniconName;
  title: string;
  sub: string;
  onPress: () => void;
}) {
  const { colors } = useTheme();
  return (
    <Pressable style={styles.linkRow} onPress={onPress}>
      <View style={[styles.linkIcon, { backgroundColor: colors.surfaceAlt }]}>
        <Ionicons name={icon} size={18} color={colors.brand} />
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="bodySemibold">{title}</Text>
        <Text variant="caption" color={colors.textSecondary}>
          {sub}
        </Text>
      </View>
      <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  logoLabel: { marginBottom: 6 },
  logoRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.md },
  logoPreview: {
    width: 56,
    height: 56,
    borderRadius: radius.md,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  logoImage: { width: '100%', height: '100%' },
  codeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginVertical: 4,
  },
  // fontFamily, never fontWeight: Android can't synthesize a bold face
  // for a loaded custom font -- a bare fontWeight here silently swaps
  // the whole run of text to the system font instead.
  code: { fontSize: 22, fontFamily: fonts.displayBold, letterSpacing: 1 },
  shareBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.sm,
    paddingVertical: 6,
    borderRadius: radius.pill,
  },
  presetGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.md },
  presetItem: { alignItems: 'center', width: 70 },
  presetSwatches: { flexDirection: 'row', marginBottom: 4 },
  swatch: {
    width: 22,
    height: 22,
    borderRadius: 11,
    marginHorizontal: -4,
    borderWidth: 2,
    borderColor: '#fff',
  },
  linkRow: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  linkIcon: {
    width: 32,
    height: 32,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, marginLeft: spacing.md + 32 + spacing.sm },
  locationStatus: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: radius.md,
    padding: spacing.sm,
    marginBottom: spacing.sm,
  },
});

'@
$path = Join-Path (Get-Location) 'src\screens\CompanySetupScreen.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/CompanySetupScreen.tsx'
$written = $written + 1

$content = @'
import AsyncStorage from '@react-native-async-storage/async-storage';

// Whether this Administrator has already been walked through the app.
// Stored per user id, not as one global flag: two managers sharing a
// tablet (or one signing in after the other on the same phone) should
// each get the tour once, and the first one through shouldn't silently
// skip it for the second.
const key = (userId: string): string => `visilog.hasSeenManagerTour.${userId}`;

export const hasSeenManagerTour = async (userId: string): Promise<boolean> => {
  try {
    return (await AsyncStorage.getItem(key(userId))) === 'true';
  } catch {
    // Storage unavailable -- assume it's been seen rather than
    // reopening the tour on every single app launch.
    return true;
  }
};

export const markManagerTourSeen = async (userId: string): Promise<void> => {
  try {
    await AsyncStorage.setItem(key(userId), 'true');
  } catch {
    // Not worth surfacing: the worst case is the tour appearing again.
  }
};

'@
$path = Join-Path (Get-Location) 'src\api\managerTour.ts'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/api/managerTour.ts'
$written = $written + 1

$content = @'
import React, { useEffect, useState } from 'react';
import { View, Modal, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import Button from './Button';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { hasSeenManagerTour, markManagerTourSeen } from '../api/managerTour';
import type { IoniconName } from '../types';

// First-run orientation for a newly registered Administrator. A company
// that has just signed up has no staff, no rooms and no office location
// yet, so the Manager home screen is almost entirely empty -- and
// nothing on it says which of those to do first, or that a company
// needs all three before anyone can actually clock in.
//
// Deliberately a sequence of cards over a dimmed screen rather than a
// true spotlight cut out around each real button: highlighting live
// elements means measuring their on-screen position at runtime, which
// breaks quietly whenever a layout, a tab order or a screen size
// changes -- and it would have to work across two navigators, since
// Company Setup and Billing aren't even on this screen. Naming where
// to go survives all of that, and is what the manager actually needs.
//
// Shown once per Administrator (see api/managerTour.ts) and skippable
// at any point.

interface TourStop {
  icon: IoniconName;
  title: string;
  body: string;
}

const STOPS: TourStop[] = [
  {
    icon: 'business-outline',
    title: 'Start in Company Setup',
    body:
      "Settings > Company Setup is where you set your company's name and logo, and mark your office location on the map. Staff can only clock in when they're physically inside that location, so this comes first.",
  },
  {
    icon: 'people-outline',
    title: 'Add your staff',
    body:
      'Company Setup > Staff roster is the list of everyone who works here. When someone signs up with your company code, VisiLog matches their work email against this list to decide whether they are a receptionist, an employee, a manager -- or a visitor. Anyone not on it becomes a visitor.',
  },
  {
    icon: 'easel-outline',
    title: 'Add your meeting rooms',
    body:
      'Company Setup > Meeting rooms fills the room picker your staff use when booking meetings. Until you add at least one, that picker has nothing in it.',
  },
  {
    icon: 'card-outline',
    title: 'Check your subscription',
    body:
      'Settings > Billing shows your plan, how many staff seats it covers and when it renews. Your plan also decides which features are switched on, so it is worth a look before you invite everybody.',
  },
  {
    icon: 'share-social-outline',
    title: 'Then share your company code',
    body:
      "Your company code is on the Company Setup screen. Send it to your staff and visitors -- it's the only thing they need to sign up and find your organisation.",
  },
];

export default function ManagerTour() {
  const { colors } = useTheme();
  const { user } = useAuth();
  const [visible, setVisible] = useState(false);
  const [index, setIndex] = useState(0);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      if (!user || user.role !== 'manager') return;
      const seen = await hasSeenManagerTour(user.id);
      if (!cancelled && !seen) setVisible(true);
    })();
    return () => {
      cancelled = true;
    };
  }, [user]);

  // Marked seen on *any* exit, including Skip: someone who dismissed it
  // chose not to read it, and showing it again next launch would read
  // as the app not listening rather than as a helpful reminder.
  const close = async () => {
    setVisible(false);
    if (user) await markManagerTourSeen(user.id);
  };

  const stop = STOPS[index];
  const isLast = index === STOPS.length - 1;

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={close}>
      <View style={styles.backdrop}>
        <View style={[styles.card, { backgroundColor: colors.surface }]}>
          <View style={[styles.iconRing, { backgroundColor: colors.primarySurface }]}>
            <Ionicons name={stop.icon} size={24} color={colors.primary} />
          </View>

          <Text variant="h3" align="center" style={{ marginBottom: spacing.xs }}>
            {stop.title}
          </Text>
          <Text variant="body" color={colors.textSecondary} align="center">
            {stop.body}
          </Text>

          <View style={styles.dots}>
            {STOPS.map((s, i) => (
              <View
                key={s.title}
                style={[
                  styles.dot,
                  { backgroundColor: i === index ? colors.primary : colors.border },
                ]}
              />
            ))}
          </View>

          <View style={styles.row}>
            {index > 0 ? (
              <Button
                label="Back"
                variant="secondary"
                onPress={() => setIndex((i) => i - 1)}
                style={{ flex: 1, marginRight: spacing.xs }}
              />
            ) : null}
            <Button
              label={isLast ? "Got it" : 'Next'}
              onPress={() => (isLast ? close() : setIndex((i) => i + 1))}
              style={{ flex: 1, marginLeft: index > 0 ? spacing.xs : 0 }}
            />
          </View>

          {!isLast ? (
            <Pressable onPress={close} style={styles.skip} hitSlop={8}>
              <Text variant="caption" color={colors.textMuted}>
                Skip this
              </Text>
            </Pressable>
          ) : null}
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(14, 27, 44, 0.6)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.lg,
  },
  card: {
    width: '100%',
    maxWidth: 420,
    borderRadius: radius.xl,
    padding: spacing.xl,
    alignItems: 'center',
  },
  iconRing: {
    width: 52,
    height: 52,
    borderRadius: 26,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.md,
  },
  dots: { flexDirection: 'row', marginVertical: spacing.lg },
  dot: { width: 7, height: 7, borderRadius: 4, marginHorizontal: 3 },
  row: { flexDirection: 'row', alignSelf: 'stretch' },
  skip: { marginTop: spacing.md, padding: 4 },
});

'@
$path = Join-Path (Get-Location) 'src\components\ManagerTour.tsx'
$dir = Split-Path $path -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/ManagerTour.tsx'
$written = $written + 1

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
          { icon: 'log-out-outline', onPress: onLogout },
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
$written = $written + 1

Write-Host ''
Write-Host "Done. $written files written."
Write-Host 'Next: run   npx tsc --noEmit   to confirm everything compiles.'
