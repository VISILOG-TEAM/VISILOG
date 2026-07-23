import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { shadows } from '../theme/shadows';
import { fonts } from '../theme/typography';
import type { IoniconName } from '../types';

type StatTileTint = 'primary' | 'info' | 'success' | 'pending';

interface StatTileProps {
  icon?: IoniconName;
  label: string;
  value: number | string;
  tint?: StatTileTint;
}

// One of the four big numbers on the Dashboard. A coloured icon chip on
// the left and a big display number on the right. The `tint` prop selects
// which status colour family the icon chip uses.
export default function StatTile({ icon = 'people', label, value, tint = 'primary' }: StatTileProps) {
  const { colors } = useTheme();
  // 'primary' pulls the signed-in org's brand accent; the rest are fixed
  // status colors that don't vary per organization.
  const TINTS = {
    primary: { bg: colors.primarySurface, fg: colors.primary },
    info: { bg: colors.status.info.bg, fg: colors.status.info.solid },
    success: { bg: colors.status.success.bg, fg: colors.status.success.solid },
    pending: { bg: colors.status.pending.bg, fg: colors.status.pending.solid },
  };
  const t = TINTS[tint] || TINTS.primary;
  return (
    <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.border }, shadows.sm]}>
      <View style={[styles.icon, { backgroundColor: t.bg }]}>
        <Ionicons name={icon} size={18} color={t.fg} />
      </View>
      <Text variant="caption" color={colors.textSecondary} style={styles.label}>
        {label}
      </Text>
      <Text style={[styles.value, { color: colors.textPrimary }]}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    flex: 1,
    borderRadius: radius.lg,
    borderWidth: 1,
    padding: spacing.md,
  },
  icon: {
    width: 32, height: 32, borderRadius: radius.md,
    alignItems: 'center', justifyContent: 'center',
    marginBottom: spacing.xs,
  },
  label: { marginTop: 2 },
  value: {
    fontFamily: fonts.displayBold,
    fontSize: 26,
    marginTop: 2,
    letterSpacing: -0.5,
  },
});