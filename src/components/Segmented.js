import React from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import Text from './Text';
import { colors } from '../theme/colors';
import { radius, spacing } from '../theme/spacing';

// Pill-style filter group used at the top of list screens (e.g. Visitors:
// All · On-site · Completed). Pass an array of { label, value } options
// and the selected value; emits the new value on press.
export default function Segmented({ options, value, onChange, style }) {
  return (
    <View style={[styles.wrap, style]}>
      {options.map((opt) => {
        const active = opt.value === value;
        return (
          <Pressable
            key={opt.value}
            onPress={() => onChange?.(opt.value)}
            style={[styles.btn, active && styles.btnActive]}
          >
            <Text
              variant="bodyMd"
              color={active ? colors.textInverse : colors.textSecondary}
            >
              {opt.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    backgroundColor: colors.surfaceAlt,
    borderRadius: radius.pill,
    padding: 4,
  },
  btn: {
    flex: 1,
    paddingVertical: 8,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.pill,
  },
  btnActive: { backgroundColor: colors.brand },
});
