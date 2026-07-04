import React, { useState } from 'react';
import { View, TextInput, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';

// Form field with a label, optional leading icon, focus highlight and an
// inline error message. Errors are specific and actionable, never vague.
export default function Input({
  label,
  value,
  onChangeText,
  placeholder,
  icon,
  error,
  keyboardType,
  secureTextEntry,
  autoCapitalize = 'sentences',
  multiline = false,
  style,
}) {
  const [focused, setFocused] = useState(false);

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
          multiline && styles.multiline,
          focused && styles.focused,
          error && styles.errored,
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
          style={styles.input}
          value={value}
          onChangeText={onChangeText}
          placeholder={placeholder}
          placeholderTextColor={colors.textMuted}
          keyboardType={keyboardType}
          secureTextEntry={secureTextEntry}
          autoCapitalize={autoCapitalize}
          multiline={multiline}
          textAlignVertical={multiline ? 'top' : 'center'}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
        />
      </View>

      {error ? (
        <Text variant="caption" color={colors.status.error.solid} style={styles.error}>
          {error}
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
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    height: 48,
  },
  multiline: { height: 100, alignItems: 'flex-start', paddingTop: 12 },
  focused: { borderColor: colors.primary },
  errored: { borderColor: colors.status.error.solid },
  icon: { marginRight: 8 },
  input: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 15,
    color: colors.textPrimary,
    paddingVertical: 0,
  },
  error: { marginTop: 4 },
});
