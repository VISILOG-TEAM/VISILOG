# VisiLog frontend - CSV import, booking header, red close, location readout, alert wording
# Run from the repository root.
$ErrorActionPreference = 'Stop'

$content = @'
// Minimal CSV parsing for bulk-import (staff roster, meeting rooms).
// Handles quoted fields (with "" escaping and embedded commas/
// newlines) and both \r\n and \n line endings -- not a full RFC 4180
// implementation, but enough for the plain exports a spreadsheet
// produces.

// Which character actually separates the columns. Excel writes
// semicolons in a lot of European locales, "Save as tab-delimited"
// writes tabs, and some exports use pipes -- all of which used to parse
// as ONE giant column, so every row arrived with no recognisable fields
// and the import rejected the entire file. Picks whichever candidate
// appears most often on the header line.
function detectDelimiter(headerLine: string): string {
  const candidates = [',', ';', '\t', '|'];
  let best = ',';
  let bestCount = 0;
  candidates.forEach((c) => {
    const count = headerLine.split(c).length - 1;
    if (count > bestCount) {
      best = c;
      bestCount = count;
    }
  });
  return best;
}

export function parseCsv(text: string): string[][] {
  const rows: string[][] = [];
  let row: string[] = [];
  let field = '';
  let inQuotes = false;
  let i = 0;
  const s = text
    // A UTF-8 BOM is invisible but glues itself to the first header,
    // turning "code" into a key nothing matches. Excel adds one by
    // default, so this is the single most likely reason a perfectly
    // good file imports zero rows.
    .replace(/^\uFEFF/, '')
    .replace(/\r\n/g, '\n')
    .replace(/\r/g, '\n');
  const delimiter = detectDelimiter(s.split('\n')[0] || '');

  while (i < s.length) {
    const c = s[i];
    if (inQuotes) {
      if (c === '"') {
        if (s[i + 1] === '"') {
          field += '"';
          i += 2;
          continue;
        }
        inQuotes = false;
        i += 1;
        continue;
      }
      field += c;
      i += 1;
      continue;
    }
    if (c === '"') {
      inQuotes = true;
      i += 1;
      continue;
    }
    if (c === delimiter) {
      row.push(field);
      field = '';
      i += 1;
      continue;
    }
    if (c === '\n') {
      row.push(field);
      rows.push(row);
      row = [];
      field = '';
      i += 1;
      continue;
    }
    field += c;
    i += 1;
  }
  row.push(field);
  rows.push(row);

  return rows.filter((r) => r.length > 1 || r[0].trim() !== '');
}

// Turns parsed rows (first row = header) into case-insensitive
// header - value maps, one per data row -- so callers can look up
// `record['email']` regardless of how the header was capitalized.
export function csvRowsToRecords(rows: string[][]): Record<string, string>[] {
  if (rows.length === 0) return [];
  const headers = rows[0].map((h) => h.trim().toLowerCase());
  return rows.slice(1).map((r) => {
    const record: Record<string, string> = {};
    headers.forEach((h, i) => {
      const value = (r[i] || '').trim();
      record[h] = value;
      // Also stored under a squashed key, so a caller can look up
      // 'employeeid' and match a column headed "Employee ID",
      // "employee_id" or "Employee-Id" without listing every spelling.
      const squashed = h.replace(/[^a-z0-9]/g, '');
      if (squashed && !(squashed in record)) record[squashed] = value;
    });
    return record;
  });
}

'@
$path = Join-Path (Get-Location) 'src\data\csv.ts'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/data/csv.ts'

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
        columnsHint="Needs a name and an email for each person. Staff ID, department, phone and role\nare used if your file has them -- a missing staff ID is generated, and a missing or\nunrecognised role becomes employee."
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
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/DirectoryScreen.tsx'

$content = @'
import React from 'react';
import { Screen, Header, Text, BookMeetingForm } from '../components';
import { spacing } from '../theme/spacing';
import type { RootStackNavigation } from '../types/navigation';

interface EmployeeBookScreenProps {
  navigation: RootStackNavigation;
}

// EmployeeBookScreen -- self-service booking for the signed-in user's
// own meeting (interview, planning session, client meeting, etc.).
// Shared by the Employee and Manager tab sets -- an Administrator can
// invite anyone from the directory here too, not just their own team,
// and can book either a meeting room or an outside location.
export default function EmployeeBookScreen({ navigation }: EmployeeBookScreenProps) {
  return (
    <Screen>
      {/* No subtitle and no footnote: the four-step form below now says
          what it does as you go (the location toggle offers "Meeting
          room" or "Outside location" on step one), and the reschedule
          hint was advice about a different screen entirely -- it just
          pushed the form further down the page. */}
      <Header eyebrow="Self-service" title="Book a meeting" />

      <BookMeetingForm onDone={() => navigation.navigate('Home')} />
    </Screen>
  );
}

'@
$path = Join-Path (Get-Location) 'src\screens\EmployeeBookScreen.tsx'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/EmployeeBookScreen.tsx'

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
      {/* Close is red, like every other way out of a screen or the app. */}
      <Header
        title="Settings"
        subtitle="Profile, preferences & administration"
        rightActions={[{ icon: 'close', onPress: () => navigation.goBack(), danger: true }]}
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
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/SettingsScreen.tsx'

$content = @'
import React, { useState } from 'react';
import { View, StyleSheet, Pressable, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Button } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import type { RootStackScreenProps } from '../types/navigation';

// LegalAgreementScreen has two modes, driven by whether `pending` (the
// not-yet-submitted company registration form) was passed in:
//
// - Registration flow: RegisterCompanyScreen collects the form, then
// pushes here with `pending` set. A company can't use VisiLog until
// this screen's subscription is agreed to and "paid" for -- there's
// no real payment processor in this build, so this is a placeholder
// checkout step, but registerCompany() (the call that actually
// creates the org and hands back a company code) only fires from
// the button on *this* screen, never from the form screen itself.
// - Review flow: reachable anytime afterwards from Company Setup (the
// paying manager's own screen), with no `pending` data -- read-only,
// no checkbox or payment section, just the terms.
// Every self-serve signup lands on the Starter plan (see
// AuthService.registerCompany) -- match its real price so this isn't a
// disconnected placeholder figure. Administrators can switch plans
// afterwards from Billing & subscription.
const STARTER_PRICE = 400;
const TERM_YEARS = 2;
const CURRENCY = 'GHS';

const TERMS_TEXT = `VisiLog Subscription Agreement

1. Term & Renewal
VisiLog is licensed on a minimum two-year subscription term. Your subscription begins on the date of activation and automatically covers your organization for the full term shown below. You will be notified before renewal.

2. What's included
Your subscription covers unlimited visitor check-ins, staff roster management, meeting room booking, NFC badge issuance, and all Company Setup administration tools for your organization, billed at the plan tier your Administrator selects afterwards.

3. Data & Privacy
Visitor and staff data you enter is stored for your organization only and is never shared with other tenants. You are responsible for obtaining any consent required by your local data protection laws before collecting visitor information.

4. Administrator responsibility
The person completing this agreement is designated the organization's initial Administrator (Manager role) and is responsible for configuring the staff roster, office location, and branding in Company Setup, and for managing who else on their team has administrative access.

5. Cancellation
You may cancel future renewals at any time from Billing & Subscription in Settings. Cancelling does not refund the current term.

By continuing, you confirm you have the authority to enter into this agreement on behalf of your organization.`;

export default function LegalAgreementScreen({
  navigation,
  route,
}: RootStackScreenProps<'LegalAgreement'>) {
  const { colors } = useTheme();
  const { registerCompany } = useAuth();
  const pending = route?.params?.pending || null;
  const viewOnly = !pending;

  const [agreed, setAgreed] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  const onConfirm = async () => {
    if (!agreed || submitting || !pending) return;
    setSubmitting(true);
    const result = await registerCompany(
      pending.companyName,
      pending.adminName,
      pending.adminEmail,
      pending.password,
    );
    setSubmitting(false);
    if (!result.ok) {
      Alert.alert('Could not register your company', result.error);
      return;
    }
    Alert.alert(
      "You're all set",
      `${result.organization!.name} is registered and active for the next ${TERM_YEARS} years. Your company code is ${result.organization!.code}. Share it with your staff and visitors so they can sign up. You can find it again anytime in Company Setup.`,
      [
        {
          text: 'Continue',
          onPress: () => {
            // The root navigator swaps to the signed-in stack once `user` is
            // set, but "LegalAgreement" is a valid screen name in *both*
            // stacks (it's also reachable from Company Setup post-login), so
            // React Navigation has no reason to redirect on its own -- it just
            // keeps rendering the same screen name across the swap. Reset
            // explicitly to the new stack's actual landing screen instead of
            // relying on that swap to also navigate.
            navigation.reset({ index: 0, routes: [{ name: 'ManagerTabs' }] });
          },
        },
      ],
    );
  };

  return (
    <Screen>
      <Header
        eyebrow={viewOnly ? 'Company Setup' : 'Before you activate'}
        title="Legal agreement"
        subtitle={
          viewOnly
            ? 'The terms your organization agreed to when it registered.'
            : "Read and agree to continue -- you're a couple of taps from a company code."
        }
        onBackPress={() => navigation.goBack()}
      />

      <Card>
        <Text variant="bodyMd" color={colors.textPrimary} style={styles.terms}>
          {TERMS_TEXT}
        </Text>
      </Card>

      {!viewOnly ? (
        <>
          <Card style={{ marginTop: spacing.sm }}>
            <View style={styles.planRow}>
              <View>
                <Text variant="bodySemibold">VisiLog subscription</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {TERM_YEARS}-year term - billed once
                </Text>
              </View>
              <Text variant="h2" color={colors.brand}>
                {CURRENCY} {STARTER_PRICE}
              </Text>
            </View>
            <Text variant="caption" color={colors.textMuted} style={{ marginTop: spacing.xs }}>
              This is a demo build -- no real payment is processed and no card details are
              collected. Agreeing below activates your subscription immediately.
            </Text>
          </Card>

          <Pressable onPress={() => setAgreed((a) => !a)} style={styles.agreeRow}>
            <View
              style={[
                styles.checkbox,
                { borderColor: colors.borderStrong },
                agreed && { backgroundColor: colors.primary, borderColor: colors.primary },
              ]}
            >
              {agreed ? <Ionicons name="checkmark" size={14} color="#FFF" /> : null}
            </View>
            <Text variant="bodyMd" style={{ flex: 1, marginLeft: spacing.xs }}>
              I have read and agree to the VisiLog Subscription Agreement above.
            </Text>
          </Pressable>

          <Button
            label={submitting ? 'Activating...' : `Agree & activate (${TERM_YEARS}-year term)`}
            icon="shield-checkmark-outline"
            onPress={onConfirm}
            disabled={!agreed || submitting}
            style={{ marginTop: spacing.md }}
          />
        </>
      ) : null}
    </Screen>
  );
}

const styles = StyleSheet.create({
  terms: { lineHeight: 20 },
  planRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  agreeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing.md,
    paddingVertical: spacing.xs,
  },
  checkbox: {
    width: 20,
    height: 20,
    borderRadius: 6,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

'@
$path = Join-Path (Get-Location) 'src\screens\LegalAgreementScreen.tsx'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/LegalAgreementScreen.tsx'

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

// A raw GPS reading carries about 14 decimal places, which is both
// unreadable and false precision. 5 places is roughly a metre.
function trimCoord(value: string): string {
  const n = parseFloat(value);
  return Number.isNaN(n) ? value : n.toFixed(5);
}

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
            {/* Shows the actual coordinates once set, not just "Location
                set". A bare confirmation is useless for the one thing an
                admin needs to check -- whether the pin landed on their
                office or on wherever the phone happened to think it was.
                Trimmed to 5 decimal places, roughly a metre. */}
            <Text variant="bodyMd" color={colors.textSecondary} style={{ marginLeft: 8, flex: 1 }}>
              {latitude.trim() && longitude.trim()
                ? `Location set: ${trimCoord(latitude)}, ${trimCoord(longitude)}`
                : 'No location set yet'}
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
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/CompanySetupScreen.tsx'

Write-Host ''
Write-Host 'Done. 6 files written.'
Write-Host 'Next: run   npx tsc --noEmit'
