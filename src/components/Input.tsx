import React, { useState } from 'react';
import {
  View,
  TextInput,
  StyleSheet,
  Pressable,
  type KeyboardTypeOptions,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import type { IoniconName } from '../types';

interface InputProps {
  label?: string;
  value: string;
  onChangeText: (text: string) => void;
  placeholder?: string;
  icon?: IoniconName;
  error?: string;
  hint?: string;
  keyboardType?: KeyboardTypeOptions;
  secureTextEntry?: boolean;
  autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters';
  autoComplete?: React.ComponentProps<typeof TextInput>['autoComplete'];
  multiline?: boolean;
  style?: StyleProp<ViewStyle>;
}

// Form field with a label, optional leading icon, focus highlight and an
// inline error message. Errors are specific and actionable, never vague.
export default function Input({
  label,
  value,
  onChangeText,
  placeholder,
  icon,
  error,
  hint,
  keyboardType,
  secureTextEntry,
  autoCapitalize = 'sentences',
  autoComplete,
  multiline = false,
  style,
}: InputProps) {
  const { colors } = useTheme();
  const [focused, setFocused] = useState(false);
  // Password fields get their own reveal toggle instead of the caller
  // having to wire one up on every screen -- this is a bit of state per
  // field, so it only kicks in when secureTextEntry is actually passed.
  const [revealed, setRevealed] = useState(false);
  const isPassword = !!secureTextEntry;

  return (
    <View style={[styles.wrap, style]}>
      {label ? (
        <Text variant="label" color={colors.textSecondary} style={styles.label}>
          {label}
        </Text>
      ) : null}

      <View
        style={[
          styles.field,
          { backgroundColor: colors.surface, borderColor: colors.border },
          multiline && styles.multiline,
          focused && { borderColor: colors.primary },
          error && { borderColor: colors.status.error.solid },
        ]}
      >
        {icon ? (
          <Ionicons
            name={icon}
            size={18}
            color={focused ? colors.primary : colors.textMuted}
            style={styles.icon}
          />
        ) : null}
        <TextInput
          style={[styles.input, { color: colors.textPrimary }]}
          value={value}
          onChangeText={onChangeText}
          placeholder={placeholder}
          placeholderTextColor={colors.textMuted}
          keyboardType={keyboardType}
          secureTextEntry={isPassword && !revealed}
          autoCapitalize={autoCapitalize}
          autoComplete={autoComplete}
          multiline={multiline}
          textAlignVertical={multiline ? 'top' : 'center'}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
        />
        {isPassword ? (
          <Pressable onPress={() => setRevealed((r) => !r)} hitSlop={8} style={styles.eyeIcon}>
            <Ionicons
              name={revealed ? 'eye-outline' : 'eye-off-outline'}
              size={18}
              color={colors.textMuted}
            />
          </Pressable>
        ) : null}
      </View>

      {error ? (
        <Text variant="caption" color={colors.status.error.solid} style={styles.error}>
          {error}
        </Text>
      ) : hint ? (
        <Text variant="caption" color={colors.textMuted} style={styles.error}>
          {hint}
        </Text>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { marginBottom: spacing.md },
  label: { marginBottom: 6 },
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    height: 48,
  },
  multiline: { height: 100, alignItems: 'flex-start', paddingTop: 12 },
  icon: { marginRight: 8 },
  eyeIcon: { marginLeft: 8 },
  input: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 15,
    paddingVertical: 0,
  },
  error: { marginTop: 4 },
});