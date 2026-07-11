import React from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import Avatar from './Avatar';
import { colors } from '../theme/colors';
import { spacing } from '../theme/spacing';

// Used by every list screen (visitors, employees, calls, NFC cards, etc.).
// Pass either `avatarName` for initials, a `leftIcon`, or a custom `left`
// node. `right` can be anything (a badge, text, an icon). `chevron` adds
// a trailing arrow when the row is tappable.
export default function ListItem({
  avatarName,
  leftIcon,
  left,
  title,
  subtitle,
  meta,
  right,
  chevron = false,
  onPress,
}) {
  const content = (
    <>
      {left ? (
        left
      ) : avatarName ? (
        <Avatar name={avatarName} size={40} />
      ) : leftIcon ? (
        <View style={styles.iconWrap}>
          <Ionicons name={leftIcon} size={18} color={colors.brand} />
        </View>
      ) : null}

      <View style={styles.middle}>
        <Text variant="bodySemibold" numberOfLines={1}>
          {title}
        </Text>
        {subtitle ? (
          <Text variant="caption" color={colors.textSecondary} numberOfLines={1}>
            {subtitle}
          </Text>
        ) : null}
      </View>

      <View style={styles.rightCol}>
        {meta ? (
          <Text variant="caption" color={colors.textMuted}>
            {meta}
          </Text>
        ) : null}
        {right}
        {chevron ? (
          <Ionicons
            name="chevron-forward"
            size={18}
            color={colors.textMuted}
            style={{ marginLeft: 6 }}
          />
        ) : null}
      </View>
    </>
  );

  // Pressable supports the (pressed) => style render-prop form; a plain View
  // does not, so non-interactive rows (no onPress) get a static style instead.
  if (onPress) {
    return (
      <Pressable
        onPress={onPress}
        style={({ pressed }) => [
          styles.row,
          pressed && { backgroundColor: colors.surfaceAlt },
        ]}
      >
        {content}
      </Pressable>
    );
  }

  return <View style={styles.row}>{content}</View>;
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
    gap: spacing.sm,
    minHeight: 56,
  },
  iconWrap: {
    width: 40, height: 40, borderRadius: 10,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center', justifyContent: 'center',
  },
  middle: { flex: 1, marginHorizontal: spacing.xs },
  rightCol: { flexDirection: 'row', alignItems: 'center' },
});
