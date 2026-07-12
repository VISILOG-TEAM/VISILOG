import React from 'react';
import { Pressable, ActivityIndicator, View, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';

const HEIGHTS = { sm: 40, md: 48, lg: 56 };

// Active-voice labels please: "Register visitor", not "Submit".
export default function Button({
  label,
  onPress,
  variant = 'primary',
  size = 'md',
  icon,
  iconPosition = 'left',
  loading = false,
  disabled = false,
  fullWidth = true,
  style,
}) {
  const { colors } = useTheme();
  // Built per-render (cheap, a handful of keys) so a signed-in org's
  // brand color flows straight into every button without a reload.
  const VARIANTS = {
    primary: { bg: colors.primary, fg: colors.textInverse, border: 'transparent', pressed: colors.primaryPressed },
    secondary: { bg: colors.surface, fg: colors.brand, border: colors.border, pressed: colors.surfaceAlt },
    ghost: { bg: 'transparent', fg: colors.primary, border: 'transparent', pressed: colors.primarySurface },
    danger: { bg: colors.status.error.solid, fg: colors.textInverse, border: 'transparent', pressed: '#B91C1C' },
  };
  const v = VARIANTS[variant] || VARIANTS.primary;
  const isDisabled = disabled || loading;
  const height = HEIGHTS[size] || HEIGHTS.md;
  const labelVariant = size === 'sm' ? 'label' : 'bodySemibold';

  return (
    <Pressable
      onPress={onPress}
      disabled={isDisabled}
      accessibilityRole="button"
      accessibilityState={{ disabled: isDisabled, busy: loading }}
      style={({ pressed }) => [
        styles.base,
        { height, backgroundColor: pressed && !isDisabled ? v.pressed : v.bg, borderColor: v.border },
        v.border !== 'transparent' && styles.bordered,
        fullWidth && styles.fullWidth,
        isDisabled && styles.disabled,
        style,
      ]}
    >
      {loading ? (
        <ActivityIndicator color={v.fg} />
      ) : (
        <View style={styles.content}>
          {icon && iconPosition === 'left' ? (
            <Ionicons name={icon} size={18} color={v.fg} style={styles.iconLeft} />
          ) : null}
          <Text variant={labelVariant} color={v.fg}>
            {label}
          </Text>
          {icon && iconPosition === 'right' ? (
            <Ionicons name={icon} size={18} color={v.fg} style={styles.iconRight} />
          ) : null}
        </View>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: spacing.lg,
  },
  bordered: { borderWidth: 1 },
  fullWidth: { alignSelf: 'stretch' },
  disabled: { opacity: 0.45 },
  content: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center' },
  iconLeft: { marginRight: 8 },
  iconRight: { marginLeft: 8 },
});
