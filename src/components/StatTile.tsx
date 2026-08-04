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
type StatTileLayout = 'stacked' | 'row';

interface StatTileProps {
  icon?: IoniconName;
  label: string;
  value: number | string;
  tint?: StatTileTint;
  /** 'stacked' (default) is icon-above-label-above-value, sized for the
   *  Dashboard's 2-per-row grid. 'row' puts the icon, label and value on
   *  a single line -- for a lone, full-width tile (see
   *  ManagerClockInsScreen) where stacking just wastes vertical space. */
  layout?: StatTileLayout;
}

// One of the four big numbers on the Dashboard. A coloured icon chip and
// a big display number. The `tint` prop selects which status colour
// family the icon chip uses.
export default function StatTile({
  icon = 'people',
  label,
  value,
  tint = 'primary',
  layout = 'stacked',
}: StatTileProps) {
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

  if (layout === 'row') {
    return (
      <View
        style={[
          styles.rowCard,
          { backgroundColor: colors.surface, borderColor: colors.border },
          shadows.sm,
        ]}
      >
        <View style={[styles.icon, styles.rowIcon, { backgroundColor: t.bg }]}>
          <Ionicons name={icon} size={18} color={t.fg} />
        </View>
        <Text variant="caption" color={colors.textSecondary} style={styles.rowLabel}>
          {label}
        </Text>
        <Text style={[styles.value, styles.rowValue, { color: colors.textPrimary }]}>
          {value}
        </Text>
      </View>
    );
  }

  return (
    <View
      style={[
        styles.card,
        { backgroundColor: colors.surface, borderColor: colors.border },
        shadows.sm,
      ]}
    >
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
  rowCard: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: radius.lg,
    borderWidth: 1,
    padding: spacing.md,
  },
  icon: {
    width: 32,
    height: 32,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.xs,
  },
  rowIcon: { marginBottom: 0, marginRight: spacing.sm },
  label: { marginTop: 2 },
  rowLabel: { flex: 1, marginTop: 0 },
  value: {
    fontFamily: fonts.displayBold,
    fontSize: 26,
    marginTop: 2,
    letterSpacing: -0.5,
  },
  rowValue: { marginTop: 0, marginLeft: spacing.sm },
});