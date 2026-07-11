import React from 'react';
import { View, StyleSheet, Pressable, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Avatar, Badge,
} from '../components';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';

// MoreScreen — the "everything else" tab.
// Holds links to the modules that don't fit in the bottom tab bar:
// Call Log, Reports, Settings, NFC Cards, Attendance, Room Bookings,
// Visitor Pre-Registration, plus sign out.
export default function MoreScreen({ navigation }) {
  const { user, logout } = useAuth();

  const onLogout = () => {
    Alert.alert('Sign out?', 'You\u2019ll need to sign in again to access VisiLog.', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Sign out', style: 'destructive', onPress: () => logout() },
    ]);
  };

  return (
    <Screen>
      <Header title="More" subtitle="Reports, settings & extras" />

      {/* Profile preview */}
      <Card padded={false} onPress={() => navigation.navigate('Settings')}>
        <View style={styles.profile}>
          <Avatar name={user?.name || 'You'} size={48} />
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="bodySemibold">{user?.name || 'Receptionist'}</Text>
            <Text variant="caption" color={colors.textSecondary}>{user?.email}</Text>
          </View>
          <Badge label={user?.role || 'Receptionist'} status="info" size="sm" dot={false} />
        </View>
      </Card>

      {/* Operations */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Operations
      </Text>
      <Card padded={false}>
        <Link icon="scan-outline" title="NFC lookup"
          sub="Enter a visitor's code to view their booking"
          onPress={() => navigation.navigate('NFCLookup')} />
        <Divider />
        <Link icon="call-outline" title="Call log"
          sub="Incoming, outgoing & missed"
          onPress={() => navigation.navigate('CallLog')} />
        <Divider />
        <Link icon="calendar-outline" title="Visitor pre-registration"
          sub="Self-service booking on behalf of a visitor"
          onPress={() => navigation.navigate('VisitorBooking')} />
        <Divider />
        <Link icon="document-text-outline" title="Reports"
          sub="Visit summaries & exports"
          onPress={() => navigation.navigate('Reports')} />
      </Card>

      {/* NFC 2.0 */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        NFC 2.0
      </Text>
      <Card padded={false}>
        <Link icon="card-outline" title="NFC cards"
          sub="Issued credentials & access tokens"
          onPress={() => navigation.navigate('NFCCards')} />
        <Divider />
        <Link icon="finger-print-outline" title="Attendance"
          sub="NFC tap log & punctuality"
          onPress={() => navigation.navigate('Attendance')} />
        <Divider />
        <Link icon="business-outline" title="Room bookings"
          sub="Meeting rooms & NFC access"
          onPress={() => navigation.navigate('RoomBookings')} />
      </Card>

      {/* Account */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Account
      </Text>
      <Card padded={false}>
        <Link icon="settings-outline" title="Settings"
          sub="Profile, security & preferences"
          onPress={() => navigation.navigate('Settings')} />
        <Divider />
        <Link icon="log-out-outline" title="Sign out"
          sub="End this session"
          danger
          onPress={onLogout} />
      </Card>

      <Text variant="caption" color={colors.textMuted} align="center" style={{ marginTop: spacing.lg }}>
        VisiLog 2.0 - Build 1.0.0
      </Text>
    </Screen>
  );
}

function Link({ icon, title, sub, onPress, danger }) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [styles.row, pressed && { backgroundColor: colors.surfaceAlt }]}
    >
      <View style={[styles.icon, danger && { backgroundColor: colors.status.error.bg }]}>
        <Ionicons
          name={icon}
          size={18}
          color={danger ? colors.status.error.solid : colors.brand}
        />
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="bodySemibold" color={danger ? colors.status.error.solid : colors.textPrimary}>
          {title}
        </Text>
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
  profile: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  row: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  icon: {
    width: 32, height: 32, borderRadius: 10,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center', justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, backgroundColor: colors.border, marginLeft: spacing.md + 32 + spacing.sm },
});
