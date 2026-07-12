import React from 'react';
import { View, StyleSheet, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { AuthBackground, Text } from '../components';
import { hexToRgb } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { fonts } from '../theme/typography';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';

// RoleSelectScreen — shown once right after a successful login (see
// AuthContext's `hasChosenRole`). "Administrator" from the brief is
// folded into the existing `manager` role, just relabeled here.
const ROLES = [
  { value: 'visitor', label: 'Visitor', icon: 'person-outline', blurb: 'Book a visit & get your NFC pass' },
  { value: 'receptionist', label: 'Receptionist', icon: 'desktop-outline', blurb: 'Front desk check-in & call log' },
  { value: 'employee', label: 'Employee', icon: 'briefcase-outline', blurb: 'Clock in, host visitors, book rooms' },
  { value: 'manager', label: 'Administrator', icon: 'shield-checkmark-outline', blurb: 'Oversight, reports & attendance' },
];

export default function RoleSelectScreen() {
  const { chooseRole } = useAuth();
  const { colors: themeColors } = useTheme();

  return (
    <AuthBackground
      gradientColors={[themeColors.brandTint, themeColors.brandDark, themeColors.brandDark]}
      accentColor={hexToRgb(themeColors.primary)}
    >
      <View style={styles.wrap}>
        <Text style={styles.heading}>Welcome to VisiLog</Text>
        <Text style={styles.subheading}>Which of these are you?</Text>

        <View style={styles.grid}>
          {ROLES.map((r) => (
            <Pressable
              key={r.value}
              onPress={() => chooseRole(r.value)}
              style={({ pressed }) => [
                styles.card,
                { borderColor: `rgba(${hexToRgb(themeColors.primary)},0.35)` },
                pressed && { opacity: 0.85 },
              ]}
            >
              <View style={[styles.iconWrap, { backgroundColor: `rgba(${hexToRgb(themeColors.primary)},0.12)` }]}>
                <Ionicons name={r.icon} size={26} color={themeColors.primary} />
              </View>
              <Text style={styles.cardLabel}>{r.label}</Text>
              <Text style={styles.cardBlurb}>{r.blurb}</Text>
            </Pressable>
          ))}
        </View>
      </View>
    </AuthBackground>
  );
}

const styles = StyleSheet.create({
  wrap: { flex: 1, justifyContent: 'center', paddingHorizontal: spacing.lg },
  heading: {
    fontFamily: fonts.displayBold, fontSize: 26, color: '#FFFFFF',
    textAlign: 'center', marginBottom: 4,
  },
  subheading: {
    fontFamily: fonts.regular, fontSize: 14, color: 'rgba(255,255,255,0.8)',
    textAlign: 'center', marginBottom: spacing.xl,
  },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.sm, justifyContent: 'space-between' },
  card: {
    width: '48%',
    borderRadius: radius.lg,
    borderWidth: 1,
    backgroundColor: 'rgba(255,255,255,0.08)',
    padding: spacing.md,
    marginBottom: spacing.sm,
  },
  iconWrap: {
    width: 44, height: 44, borderRadius: 12,
    alignItems: 'center', justifyContent: 'center',
    marginBottom: spacing.sm,
  },
  cardLabel: { fontFamily: fonts.semibold, fontSize: 15, color: '#FFFFFF', marginBottom: 2 },
  cardBlurb: { fontFamily: fonts.regular, fontSize: 11, color: 'rgba(255,255,255,0.75)' },
});
