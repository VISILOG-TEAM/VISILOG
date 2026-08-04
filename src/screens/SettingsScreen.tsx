import React, { useState } from 'react';
import { View, StyleSheet, Switch, Alert, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Button, Avatar, Badge } from '../components';
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
  const { user, logout } = useAuth();
  const { plans, billing } = useData();

  // Priority support is just a listed perk on the Pro/Enterprise plan's
  // features array (see V20 migration) -- no separate enforcement
  // needed since nothing is being blocked, just a different badge and
  // help message shown below.
  const currentPlan = plans.find((p) => p.id === billing?.planId);
  const hasPrioritySupport = !!currentPlan?.features.includes('Priority support');

  const [notifyAppts, setNotifyAppts] = useState(true);
  const [notifyCalls, setNotifyCalls] = useState(true);

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

      {/* Profile -- tapping through opens ProfileScreen, which holds
          display name, password and (for staff) employee ID. */}
      <Card padded={false}>
        <Pressable
          onPress={() => navigation.navigate('Profile')}
          style={[styles.profileRow, { padding: spacing.md }]}
        >
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
          <Ionicons name="chevron-forward" size={20} color={colors.textMuted} />
        </Pressable>
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
