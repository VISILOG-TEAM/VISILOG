import React, { useMemo, useState } from 'react';
import { View, Modal, Pressable, FlatList, StyleSheet, TextInput } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import type { IoniconName, Option } from '../types';

interface SelectProps<T> {
  label?: string;
  placeholder?: string;
  value?: T | null;
  options?: Option<T>[];
  onChange?: (value: T) => void;
  icon?: IoniconName;
  error?: string;
  /** Shown inside the picker when `options` is empty, so the user
   * learns WHY there's nothing to choose (e.g. no rooms added yet)
   * instead of staring at a blank sheet. */
  emptyMessage?: string;
}

// A labelled "select"-style field. Tapping it opens a modal list of
// options. Use for: purpose of visit, host employee, call type, etc.
export default function Select<T>({
  label,
  placeholder = 'Select...',
  value,
  options = [],
  onChange,
  icon,
  error,
  emptyMessage,
}: SelectProps<T>) {
  const { colors } = useTheme();
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const selected = options.find((o) => o.value === value);

  // Typing filters by label or sublabel (e.g. a host's name or their
  // department) -- a plain tap-to-pick list was fine for a handful of
  // fixed choices like "purpose of visit", but picking a host or staff
  // member out of a real company's whole roster meant scrolling a long
  // list with no way to jump to a name.
  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return options;
    return options.filter(
      (o) => o.label.toLowerCase().includes(q) || o.sublabel?.toLowerCase().includes(q),
    );
  }, [options, query]);

  return (
    <View style={{ marginBottom: spacing.md }}>
      {label ? (
        <Text variant="label" color={colors.textSecondary} style={{ marginBottom: 6 }}>
          {label}
        </Text>
      ) : null}

      <Pressable
        onPress={() => setOpen(true)}
        style={[
          styles.field,
          { backgroundColor: colors.surface, borderColor: colors.border },
          error && { borderColor: colors.status.error.solid },
        ]}
      >
        {icon ? (
          <Ionicons name={icon} size={18} color={colors.textMuted} style={{ marginRight: 8 }} />
        ) : null}
        <Text
          variant="body"
          color={selected ? colors.textPrimary : colors.textMuted}
          style={{ flex: 1 }}
          numberOfLines={1}
        >
          {selected ? selected.label : placeholder}
        </Text>
        <Ionicons name="chevron-down" size={18} color={colors.textMuted} />
      </Pressable>

      {error ? (
        <Text variant="caption" color={colors.status.error.solid} style={{ marginTop: 4 }}>
          {error}
        </Text>
      ) : null}

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
                const active = item.value === value;
                return (
                  <Pressable
                    onPress={() => {
                      onChange?.(item.value);
                      setOpen(false);
                    }}
                    style={styles.row}
                  >
                    <View style={{ flex: 1 }}>
                      <Text variant="bodySemibold">{item.label}</Text>
                      {item.sublabel ? (
                        <Text variant="caption" color={colors.textSecondary}>
                          {item.sublabel}
                        </Text>
                      ) : null}
                    </View>
                    {active ? (
                      <Ionicons name="checkmark-circle" size={20} color={colors.primary} />
                    ) : null}
                  </Pressable>
                );
              }}
            />
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
  empty: { paddingVertical: spacing.xl, paddingHorizontal: spacing.md },
  sep: { height: 1 },
});
