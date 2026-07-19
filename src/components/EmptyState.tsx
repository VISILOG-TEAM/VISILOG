import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import Button from './Button';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import type { IoniconName } from '../types';

interface EmptyStateProps {
  icon?: IoniconName;
  title: string;
  message?: string;
  actionLabel?: string;
  onAction?: () => void;
}

// An empty screen is an invitation to act, not a dead end. Give it a clear
// title, a sentence of direction, and (optionally) the next action.
export default function EmptyState({
  icon = 'sparkles-outline',
  title,
  message,
  actionLabel,
  onAction,
}: EmptyStateProps) {
  const { colors } = useTheme();
  return (
    <View style={styles.wrap}>
      <View style={[styles.badge, { backgroundColor: colors.primarySurface }]}>
        <Ionicons name={icon} size={26} color={colors.primary} />
      </View>
      <Text variant="h2" align="center" style={styles.title}>
        {title}
      </Text>
      {message ? (
        <Text variant="body" color={colors.textSecondary} align="center" style={styles.message}>
          {message}
        </Text>
      ) : null}
      {actionLabel ? (
        <Button
          label={actionLabel}
          onPress={onAction}
          fullWidth={false}
          style={styles.action}
        />
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing.huge,
    paddingHorizontal: spacing.lg,
  },
  badge: {
    width: 60,
    height: 60,
    borderRadius: radius.xl,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.md,
  },
  title: { marginBottom: 6 },
  message: { maxWidth: 280 },
  action: { marginTop: spacing.lg, paddingHorizontal: 24 },
});
