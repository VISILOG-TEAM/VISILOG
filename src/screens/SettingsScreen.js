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

// SettingsScreen
// Per the VisiLog spec: profile info, password change, notification
// preferences, organisation branding, sign-out.
export default function SettingsScreen({ navigation }) {
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
              placeholder="New password" icon="key-outline" secureTextEntry />
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

      {/* Notifications */}
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

      {/* Organisation */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Organisation
      </Text>
      <Card padded={false}>
        {user?.role === 'manager' ? (
          <>
            <LinkRow icon="card-outline" title="Billing & subscription"
              sub={`${user.organizationName} · manage plan & invoices`}
              onPress={() => navigation.navigate('Billing')} />
            <Divider />
          </>
        ) : null}
        <LinkRow icon="business-outline" title="Company branding"
          sub="Logo, primary colour, badge layout" />
        <Divider />
        <LinkRow icon="card-outline" title="Badge template"
          sub="Customise badge ID format & print layout" />
        <Divider />
        <LinkRow icon="globe-outline" title="Languages"
          sub="English (default)" />
      </Card>

      {/* About */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        About
      </Text>
      <Card padded={false}>
        <LinkRow icon="information-circle-outline" title="VisiLog 2.0"
          sub="Build 1.0.0 - Reception + NFC" />
        <Divider />
        <LinkRow icon="help-circle-outline" title="Help & support"
          sub="Contact your VisiLog administrator" />
        <Divider />
        <LinkRow icon="document-text-outline" title="Privacy policy"
          sub="How visitor data is collected & stored" />
      </Card>

      <Button
        label="Sign out"
        variant="danger"
        icon="log-out-outline"
        onPress={onLogout}
        style={{ marginTop: spacing.xl }}
      />
    </Screen>
  );
}

function ToggleRow({ label, sub, value, onChange }) {
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

function LinkRow({ icon, title, sub, onPress }) {
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
