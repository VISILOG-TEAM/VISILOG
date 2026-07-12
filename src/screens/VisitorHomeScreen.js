import React from 'react';
import { View, StyleSheet, Pressable, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Text, Card, Badge, Avatar, CompanyMapSection,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';

// VisitorHomeScreen — the visitor's tab-bar landing page. The booking
// form itself now lives on its own "Book" tab (VisitorBookScreen); this
// screen is a dashboard: profile + notifications up top, an NFC-card
// preview (or a prompt to book, if there isn't one yet), and the
// company map/tour section.
export default function VisitorHomeScreen({ navigation }) {
  const { colors: themeColors } = useTheme();
  const { user } = useAuth();
  const { employees, appointments } = useData();

  const myBooking = appointments
    .filter((a) => a.bookedByEmail === user.email)
    .sort((a, b) => new Date(b.scheduledAt) - new Date(a.scheduledAt))[0];

  const onNotifications = () => {
    Alert.alert('Notifications', 'No new notifications right now.');
  };

  return (
    <Screen>
      <View style={styles.topRow}>
        <Pressable onPress={() => navigation.navigate('Settings')}>
          <Avatar name={user?.name || 'You'} size={44} />
        </Pressable>
        <Pressable onPress={onNotifications} style={[styles.bellBtn, { backgroundColor: themeColors.primarySurface }]} hitSlop={8}>
          <Ionicons name="notifications-outline" size={22} color={themeColors.brand} />
        </Pressable>
      </View>

      <Text style={styles.welcome}>
        {myBooking
          ? `Welcome back, ${user.name?.split(' ')[0] || 'there'}`
          : 'Ready to book your first appointment?'}
      </Text>
      <Text variant="body" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
        {myBooking
          ? 'Here’s your latest visit pass.'
          : 'Head to the Book tab to schedule a visit and get your NFC pass.'}
      </Text>

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Your NFC card
      </Text>
      {myBooking ? (
        <Card accent="onsite">
          <View style={styles.cardHead}>
            <Ionicons name="card" size={28} color={themeColors.primary} />
            <Badge label={myBooking.status} status="pending" size="sm" />
          </View>
          <Text style={[styles.code, { color: themeColors.brand }]}>{myBooking.nfcCode}</Text>
          <Text variant="caption" color={colors.textSecondary}>
            Show this code at reception on arrival.
          </Text>
          <View style={styles.divider} />
          <Text variant="caption" color={colors.textMuted}>Host</Text>
          <Text variant="bodySemibold">
            {employees.find((e) => e.id === myBooking.hostId)?.name || '—'}
          </Text>
        </Card>
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

const styles = StyleSheet.create({
  topRow: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    marginBottom: spacing.md,
  },
  bellBtn: {
    width: 40, height: 40, borderRadius: 20,
    alignItems: 'center', justifyContent: 'center',
  },
  welcome: { fontFamily: fonts.displayBold, fontSize: 22, color: colors.textPrimary },
  eyebrow: { marginTop: spacing.md, marginBottom: spacing.sm },
  cardHead: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    marginBottom: spacing.sm,
  },
  code: {
    fontFamily: fonts.displayExtra, fontSize: 32,
    letterSpacing: 2, marginBottom: spacing.xs,
  },
  divider: {
    height: 1, backgroundColor: colors.border,
    marginVertical: spacing.sm,
  },
  emptyCard: { alignItems: 'center', paddingVertical: spacing.sm },
});
