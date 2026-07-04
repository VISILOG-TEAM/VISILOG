import React from 'react';
import { View, StyleSheet } from 'react-native';
import Text from './Text';
import { colors } from '../theme/colors';
import { radius } from '../theme/spacing';

// Status pill. `status` selects the colour family; `solid` fills it for
// high-emphasis cases. The leading dot reinforces the state for quick
// scanning (and for anyone who reads colour less easily).
export default function Badge({
  label,
  status = 'neutral',
  solid = false,
  dot = true,
  size = 'md',
}) {
  const s = colors.status[status] || colors.status.neutral;
  const small = size === 'sm';
  const textVariant = small ? 'caption' : 'label';

  if (solid) {
    return (
      <View style={[styles.pill, small && styles.pillSm, { backgroundColor: s.solid }]}>
        <Text variant={textVariant} color={colors.textInverse}>
          {label}
        </Text>
      </View>
    );
  }

  return (
    <View style={[styles.pill, small && styles.pillSm, { backgroundColor: s.bg }]}>
      {dot ? <View style={[styles.dot, { backgroundColor: s.solid }]} /> : null}
      <Text variant={textVariant} color={s.fg}>
        {label}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: radius.pill,
  },
  pillSm: { paddingHorizontal: 8, paddingVertical: 3 },
  dot: { width: 6, height: 6, borderRadius: 3, marginRight: 6 },
});
