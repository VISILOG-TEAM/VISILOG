import React from 'react';
import { View, Pressable, StyleSheet, type StyleProp, type ViewStyle } from 'react-native';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { radius, spacing } from '../theme/spacing';
import type { Option } from '../types';

interface SegmentedProps<T extends string> {
  options: Option<T>[];
  value: T;
  onChange: (value: T) => void;
  style?: StyleProp<ViewStyle>;
}

// Pill-style filter group used at the top of list screens (e.g. Visitors:
// All Â· On-site Â· Completed). Pass an array of { label, value } options
// and the selected value; emits the new value on press.
export default function Segmented<T extends string>({ options, value, onChange, style }: SegmentedProps<T>) {
  const { colors } = useTheme();
  return (
    <View style={[styles.wrap, { backgroundColor: colors.surfaceAlt }, style]}>
      {options.map((opt) => {
        const active = opt.value === value;
        return (
          <Pressable
            key={opt.value}
            onPress={() => onChange?.(opt.value)}
            style={[styles.btn, active && { backgroundColor: colors.brand }]}
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
});