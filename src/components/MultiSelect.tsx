import React, { useMemo, useState } from 'react';
import { View, Modal, Pressable, FlatList, StyleSheet, TextInput } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import Button from './Button';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import type { IoniconName, Option } from '../types';

interface MultiSelectProps<T> {
  label?: string;
  placeholder?: string;
  values?: T[];
  options?: Option<T>[];
  onChange?: (values: T[]) => void;
  icon?: IoniconName;
  /** Shown inside the picker when `options` is empty, explaining why. */
  emptyMessage?: string;
}

// Like Select, but lets the user tick more than one option before
// closing the sheet -- used for picking meeting attendees from the
// whole staff directory (not just a single host).
export default function MultiSelect<T>({
  label,
  placeholder = 'Select...',
  values = [],
  options = [],
  onChange,
  icon,
  emptyMessage,
}: MultiSelectProps<T>) {
  const { colors } = useTheme();
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const selectedLabels = options.filter((o) => values.includes(o.value)).map((o) => o.label);

  // Same reasoning as Select -- picking meeting attendees out of a real
  // staff directory meant scrolling a long list with no way to jump to
  // a name.
  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return options;
    return options.filter(
      (o) => o.label.toLowerCase().includes(q) || o.sublabel?.toLowerCase().includes(q),
    );
  }, [options, query]);

  const toggle = (value: T) => {
    if (values.includes(value)) {
      onChange?.(values.filter((v) => v !== value));
    } else {
      onChange?.([...values, value]);
    }
  };

  const summary =
    selectedLabels.length === 0
      ? placeholder
      : selectedLabels.length <= 2
        ? selectedLabels.join(', ')
        : `${selectedLabels.length} people selected`;

  return (
    <View style={{ marginBottom: spacing.md }}>
      {label ? (
        <Text variant="label" color={colors.textSecondary} style={{ marginBottom: 6 }}>
          {label}
        </Text>
      ) : null}

      <Pressable
        onPress={() => setOpen(true)}
        style={[styles.field, { backgroundColor: colors.surface, borderColor: colors.border }]}
      >
        {icon ? (
          <Ionicons name={icon} size={18} color={colors.textMuted} style={{ marginRight: 8 }} />
        ) : null}
        <Text
          variant="body"
          color={selectedLabels.length ? colors.textPrimary : colors.textMuted}
          style={{ flex: 1 }}
          numberOfLines={1}
        >
          {summary}
        </Text>
        <Ionicons name="chevron-down" size={18} color={colors.textMuted} />
      </Pressable>

      <Modal
        visible={open}
        transparent
        animationType="fade"
        onRequestClose={() => setOpen(false)}
        onShow={() => setQuery('')}
      >
        <Pressable style={styles.backdrop} onPress={() => setOpen(false)}>
          <Pressable
            style={[styles.sheet, { backgroundColor: colors.surface }]}
            onPress={(e) => e.stopPropagation()}
          >
            <View style={[styles.handle, { backgroundColor: colors.borderStrong }]} />
            {label ? (
              <Text variant="h3" style={{ marginBottom: spacing.sm }}>
                {label}
              </Text>
            ) : null}

            {options.length > 4 ? (
              <View
                style={[
                  styles.searchField,
                  { backgroundColor: colors.surfaceAlt, borderColor: colors.border },
                ]}
              >
                <Ionicons name="search-outline" size={16} color={colors.textMuted} />
                <TextInput
                  value={query}
                  onChangeText={setQuery}
                  placeholder="Search..."
                  placeholderTextColor={colors.textMuted}
                  style={[styles.searchInput, { color: colors.textPrimary }]}
                  autoCapitalize="none"
                />
              </View>
            ) : null}

            <FlatList
              data={filtered}
              keyboardShouldPersistTaps="handled"
              ListEmptyComponent={
                <View style={styles.empty}>
                  <Text variant="bodyMd" color={colors.textSecondary} style={{ textAlign: 'center' }}>
                    {options.length === 0
                      ? emptyMessage || 'Nothing to choose from yet.'
                      : `No matches for "${query.trim()}".`}
                  </Text>
                </View>
              }
              keyExtractor={(item) => String(item.value)}
              ItemSeparatorComponent={() => (
                <View style={[styles.sep, { backgroundColor: colors.border }]} />
              )}
              renderItem={({ item }) => {
                const active = values.includes(item.value);
                return (
                  <Pressable onPress={() => toggle(item.value)} style={styles.row}>
                    <View
                      style={[
                        styles.checkbox,
                        { borderColor: colors.borderStrong },
                        active && { backgroundColor: colors.primary, borderColor: colors.primary },
                      ]}
                    >
                      {active ? <Ionicons name="checkmark" size={14} color="#FFF" /> : null}
                    </View>
                    <View style={{ flex: 1, marginLeft: spacing.sm }}>
                      <Text variant="bodySemibold">{item.label}</Text>
                      {item.sublabel ? (
                        <Text variant="caption" color={colors.textSecondary}>
                          {item.sublabel}
                        </Text>
                      ) : null}
                    </View>
                  </Pressable>
                );
              }}
            />

            <Button label="Done" onPress={() => setOpen(false)} style={{ marginTop: spacing.sm }} />
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    height: 48,
  },
  searchField: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    height: 40,
    marginBottom: spacing.sm,
  },
  searchInput: { flex: 1, fontSize: 15, paddingVertical: 0, marginLeft: 8 },
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(14, 27, 44, 0.45)',
    justifyContent: 'flex-end',
  },
  sheet: {
    borderTopLeftRadius: radius.xl,
    borderTopRightRadius: radius.xl,
    paddingHorizontal: spacing.md,
    paddingTop: spacing.sm,
    paddingBottom: spacing.xl,
    maxHeight: '70%',
  },
  handle: {
    width: 36,
    height: 4,
    borderRadius: 2,
    alignSelf: 'center',
    marginBottom: spacing.sm,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing.sm,
  },
  checkbox: {
    width: 20,
    height: 20,
    borderRadius: 6,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  empty: { paddingVertical: spacing.xl, paddingHorizontal: spacing.md },
  sep: { height: 1 },
});
