import React, { type ReactNode } from 'react';
import { View, Pressable, StyleSheet, type StyleProp, type ViewStyle } from 'react-native';
import { colors as staticColors, type StatusKey } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { shadows } from '../theme/shadows';

interface CardProps {
  children?: ReactNode;
  accent?: StatusKey;
  onPress?: () => void;
  padded?: boolean;
  elevated?: boolean;
  style?: StyleProp<ViewStyle>;
}

// Signature element: an optional coloured edge stripe that echoes the
// coloured border of a visitor pass. A visitor's status is information,
// so we encode it structurally on the card's leading edge rather than
// relying on a badge alone. Pass accent="onsite" | "pending" | "rejected" | ...
export default function Card({
  children,
  accent,
  onPress,
  padded = true,
  elevated = true,
  style,
}: CardProps) {
  const { colors } = useTheme();
  const accentColor = accent ? colors.status[accent]?.solid || colors.primary : null;

  const padStyle = padded
    ? { padding: spacing.md, ...(accentColor ? { paddingLeft: spacing.md + 6 } : null) }
    : null;

  const inner = (
    <View style={[styles.card, elevated && shadows.sm, padStyle, style]}>
      {accentColor ? <View style={[styles.stripe, { backgroundColor: accentColor }]} /> : null}
      {children}
    </View>
  );

  if (onPress) {
    return (
      <Pressable
        onPress={onPress}
        style={({ pressed }) => (pressed ? styles.pressed : null)}
      >
        {inner}
      </Pressable>
    );
  }
  return inner;
}

// Card background/border are neutral (identical across every
// organization's theme), so a plain module-level StyleSheet is fine —
// only `accentColor` above needs to react to the signed-in org's brand.
const styles = StyleSheet.create({
  card: {
    backgroundColor: staticColors.surface,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: staticColors.border,
    overflow: 'hidden',
  },
  stripe: { position: 'absolute', left: 0, top: 0, bottom: 0, width: 4 },
  pressed: { transform: [{ scale: 0.99 }], opacity: 0.95 },
});
