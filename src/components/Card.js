import React from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';
import { shadows } from '../theme/shadows';

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
}) {
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

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.surface,
    borderRadius: radius.lg,
    borderWidth: 1,
    borderColor: colors.border,
    overflow: 'hidden',
  },
  stripe: { position: 'absolute', left: 0, top: 0, bottom: 0, width: 4 },
  pressed: { transform: [{ scale: 0.99 }], opacity: 0.95 },
});
