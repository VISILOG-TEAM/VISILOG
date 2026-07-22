import React, { useState } from 'react';
import { View, StyleSheet, Switch, Alert, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Button, Input, Avatar, Badge,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import type { RootStackNavigation } from '../types/navigation';
import type { IoniconName } from '../types';

interface SettingsScreenProps {
  navigation: RootStackNavigation;
}

// SettingsScreen
// Per the VisiLog spec: profile info, password change, notification
// preferences, organisation branding, sign-out.
export default function SettingsScreen({ navigation }: SettingsScreenProps) {
  const { colors: themeColors, setOrgTheme } = useTheme();
  const { user, logout } = useAuth();

  const [notifyAppts, setNotifyAppts] = useState(true);
  const [notifyCalls, setNotifyCalls] = useState(true);
  const [notifyNfc, setNotifyNfc] = useState(false);

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
      Alert.alert('Mismatch', 'New passwords don\u2019t match.');
      return;
    }
    Alert.alert('Password updated', 'Your password has been changed.');
    setCurrentPw(''); setNewPw(''); setConfirmPw('');
    setEditingPassword(false);
  };

  const onLogout = () => {
    Alert.alert('Sign out?', 'You\u2019ll need to sign in again to access VisiLog.', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Sign out', style: 'destructive', onPress: () => { logout(); setOrgTheme(null); } },
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
      </Card>

      {/* Password */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Security
      </Text>
      <Card>
        {editingPassword ? (
          <>
            <Input label="Current password" value={currentPw} onChangeText={setCurrentPw}
              placeholder="Current password" icon="lock-closed-outline" secureTextEntry />
            <Input label="New password" value={newPw} onChangeText={setNewPw}
              placeholder="New password" icon="key-outline" secureTextEntry
              hint="Must be at least 8 characters." />
            <Input label="Confirm new password" value={confirmPw} onChangeText={setConfirmPw}
              placeholder="Repeat new password" icon="shield-checkmark-outline" secureTextEntry />
            <View style={{ flexDirection: 'row' }}>
              <Button label="Cancel" variant="ghost" onPress={() => setEditingPassword(false)}
                style={{ flex: 1, marginRight: spacing.xs }} />
              <Button label="Save" onPress={onSavePassword}
                style={{ flex: 1, marginLeft: spacing.xs }} />
            </View>
          </>
        ) : (
          <Pressable onPress={() => setEditingPassword(true)} style={styles.linkRow}>
            <View style={styles.linkIcon}>
              <Ionicons name="key-outline" size={18} color={themeColors.brand} />
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

      {/* Notifications — these toggles are about staff workflow (someone
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
              value={notifyAppts} onChange={setNotifyAppts}
            />
            <Divider />
            <ToggleRow
              label="Missed call alerts"
              sub="Push a reminder for unreturned calls."
              value={notifyCalls} onChange={setNotifyCalls}
            />
            <Divider />
            <ToggleRow
              label="NFC access events"
              sub="Notify on revoked or denied card taps."
              value={notifyNfc} onChange={setNotifyNfc}
            />
          </Card>
        </>
      ) : null}

      {/* Organisation — administration for the whole tenant, so only the
          Manager/Administrator who owns that org sees it. Everyone else's
          settings are about their own account, not the company's. */}
      {user?.role === 'manager' ? (
        <>
          <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
            Organisation
          </Text>
          <Card padded={false}>
            <LinkRow icon="card-outline" title="Billing & subscription"
              sub={`${user.organizationName} · manage plan & invoices`}
              onPress={() => navigation.navigate('Billing')} />
            <Divider />
            <LinkRow icon="business-outline" title="Company Setup"
              sub="Branding, office location, staff & rooms"
              onPress={() => navigation.navigate('CompanySetup')} />
            <Divider />
            <LinkRow icon="globe-outline" title="Languages"
              sub="English (default)" />
          </Card>
        </>
      ) : null}

      {/* About */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        About
      </Text>
      <Card padded={false}>
        <LinkRow icon="information-circle-outline" title="VisiLog"
          sub="Build 1.0.0 - Reception + NFC"
          onPress={() => Alert.alert(
            'VisiLog',
            'Build 1.0.0 -- Reception + NFC\n\nVisitor management, staff attendance, and meeting-room booking for ' +
            (user?.organizationName || 'your organization') + '.'
          )} />
        <Divider />
        <LinkRow icon="help-circle-outline" title="Help & support"
          sub={user?.role === 'manager' ? 'Contact the VisiLog help desk' : 'Contact your VisiLog administrator'}
          onPress={() => Alert.alert(
            'Help & support',
            user?.role === 'manager'
              ? "As the Administrator, reach the VisiLog help desk directly for anything you can't resolve in Company Setup:\n\nPhone: 0509343709\nEmail: voldyabbey@gmail.com"
              : "For access issues, incorrect roster entries, or anything else you need changed, contact your organization's Administrator -- they manage your staff roster and company settings in Company Setup."
          )} />
        <Divider />
        <LinkRow icon="document-text-outline" title="Privacy policy"
          sub="How visitor data is collected & stored"
          onPress={() => Alert.alert(
            'Privacy policy',
            'Visitor and staff data you enter (name, phone, purpose of visit, badge/NFC activity) is stored for ' +
            (user?.organizationName || 'your organization') + ' only, and is never shared with other companies using VisiLog. ' +
            "It's used solely to run reception, attendance, and meeting-room booking for your organization."
          )} />
      </Card>

      <Button
        label="Sign out"
        variant="secondary"
        icon="log-out-outline"
        onPress={onLogout}
        style={{ marginTop: spacing.xl }}
      />
    </Screen>
  );
}

function ToggleRow({
  label, sub, value, onChange,
}: { label: string; sub: string; value: boolean; onChange: (value: boolean) => void }) {
  const { colors: themeColors } = useTheme();
  return (
    <View style={styles.toggleRow}>
      <View style={{ flex: 1, marginRight: spacing.sm }}>
        <Text variant="bodySemibold">{label}</Text>
        <Text variant="caption" color={colors.textSecondary}>{sub}</Text>
      </View>
      <Switch
        value={value}
        onValueChange={onChange}
        trackColor={{ false: colors.borderStrong, true: themeColors.primary }}
        thumbColor="#FFFFFF"
      />
    </View>
  );
}

function LinkRow({
  icon, title, sub, onPress,
}: { icon: IoniconName; title: string; sub?: string; onPress?: () => void }) {
  const { colors: themeColors } = useTheme();
  return (
    <Pressable style={styles.linkRow} onPress={onPress}>
      <View style={styles.linkIcon}>
        <Ionicons name={icon} size={18} color={themeColors.brand} />
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="bodySemibold">{title}</Text>
        {sub ? <Text variant="caption" color={colors.textSecondary}>{sub}</Text> : null}
      </View>
      <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
    </Pressable>
  );
}

function Divider() {
  return <View style={styles.divider} />;
}

const styles = StyleSheet.create({
  profileRow: { flexDirection: 'row', alignItems: 'center' },
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  toggleRow: {
    flexDirection: 'row', alignItems: 'center',
    padding: spacing.md,
  },
  linkRow: {
    flexDirection: 'row', alignItems: 'center',
    padding: spacing.md,
  },
  linkIcon: {
    width: 32, height: 32, borderRadius: 10,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center', justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, backgroundColor: colors.border, marginLeft: spacing.md + 32 + spacing.sm },
});
