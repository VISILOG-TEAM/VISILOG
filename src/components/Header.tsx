import React, { type ReactNode } from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import type { IoniconName } from '../types';

interface HeaderAction {
  icon: IoniconName;
  onPress?: () => void;
  badge?: number;
  /** Red treatment for an action that signs you out of the app. Matches
   *  the `dangerSubtle` Button variant used by Sign out in Settings, so
   *  leaving VisiLog looks the same wherever you do it. */
  danger?: boolean;
}

interface HeaderProps {
  title: string;
  subtitle?: string;
  eyebrow?: string;
  rightIcon?: IoniconName;
  onRightPress?: () => void;
  /** Unread-count badge for the single rightIcon button. */
  badge?: number;
  /** A row of icon buttons (e.g. notifications bell + logout) -- takes
   * priority over rightIcon/right when given. */
  rightActions?: HeaderAction[];
  right?: ReactNode;
  onBackPress?: () => void;
}

function ActionButton({ icon, onPress, badge, danger }: HeaderAction) {
  const { colors } = useTheme();
  const background = danger ? colors.status.error.bg : colors.surface;
  const border = danger ? colors.status.error.fg : colors.border;
  const foreground = danger ? colors.status.error.fg : colors.brand;
  return (
    <Pressable
      onPress={onPress}
      hitSlop={8}
      style={({ pressed }) => [
        styles.iconBtn,
        { backgroundColor: background, borderColor: border },
        pressed && { opacity: 0.6 },
      ]}
    >
      <Ionicons name={icon} size={20} color={foreground} />
      {badge ? (
        <View style={[styles.badge, { backgroundColor: colors.palette.red600 }]}>
          <Text variant="caption" color={colors.textInverse} style={styles.badgeText}>
            {badge > 9 ? '9+' : badge}
          </Text>
        </View>
      ) : null}
    </Pressable>
  );
}

// Consistent page header. Pass `rightIcon` (+ onRightPress, optionally
// `badge`... via rightActions) for a quick action button, `rightActions`
// for several buttons in a row, or `right` to drop in a fully custom
// element. Pass `onBackPress` for a leading back chevron on screens
// pushed onto the stack (the app hides the native header, so this is
// the only back affordance those screens get).
export default function Header({
  title,
  subtitle,
  eyebrow,
  rightIcon,
  onRightPress,
  badge,
  rightActions,
  right,
  onBackPress,
}: HeaderProps) {
  const { colors } = useTheme();
  return (
    <View style={styles.row}>
      {onBackPress ? (
        <Pressable onPress={onBackPress} hitSlop={8} style={styles.backBtn}>
          <Ionicons name="chevron-back" size={22} color={colors.brand} />
        </Pressable>
      ) : null}
      <View style={styles.left}>
        {eyebrow ? (
          <Text variant="eyebrow" color={colors.primary} style={styles.eyebrow}>
            {eyebrow}
          </Text>
        ) : null}
        <Text variant="h1">{title}</Text>
        {subtitle ? (
          <Text variant="body" color={colors.textSecondary} style={styles.subtitle}>
            {subtitle}
          </Text>
        ) : null}
      </View>

      {rightActions && rightActions.length > 0 ? (
        <View style={styles.actionsRow}>
          {rightActions.map((action, i) => (
            <View key={action.icon + i} style={i > 0 ? styles.actionsGap : undefined}>
              <ActionButton {...action} />
            </View>
          ))}
        </View>
      ) : rightIcon ? (
        <ActionButton icon={rightIcon} onPress={onRightPress} badge={badge} />
      ) : (
        right || null
      )}
    </View>
  );
}

// row/left/backBtn/eyebrow/subtitle are layout-only; iconBtn's/badge's
// color values are applied inline above from useTheme() instead.
const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    marginBottom: spacing.lg,
  },
  left: { flex: 1, paddingRight: spacing.md },
  backBtn: {
    width: 36,
    height: 36,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing.xs,
    marginTop: 2,
  },
  eyebrow: { marginBottom: 4 },
  subtitle: { marginTop: 2 },
  iconBtn: {
    width: 40,
    height: 40,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
  },
  actionsRow: { flexDirection: 'row' },
  actionsGap: { marginLeft: spacing.xs },
  badge: {
    position: 'absolute',
    top: -4,
    right: -4,
    minWidth: 16,
    height: 16,
    borderRadius: 8,
    paddingHorizontal: 3,
    alignItems: 'center',
    justifyContent: 'center',
  },
  badgeText: { fontSize: 10, lineHeight: 12 },
});
