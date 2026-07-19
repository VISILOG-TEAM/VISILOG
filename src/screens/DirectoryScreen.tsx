import React, { useMemo, useState } from 'react';
import { View, FlatList, StyleSheet, Pressable, Linking } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Input, Text, Card, EmptyState, Avatar,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import type { RootStackNavigation } from '../types/navigation';
import type { Employee } from '../types';

interface DirectoryScreenProps {
  navigation: RootStackNavigation;
}

// DirectoryScreen — the Phone Book.
// Lists every staff member; tap a row to open their detail page; tap
// the phone icon to dial straight from the device.
export default function DirectoryScreen({ navigation }: DirectoryScreenProps) {
  const { employees } = useData();
  const [query, setQuery] = useState('');

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return employees;
    return employees.filter(
      (e) =>
        e.name.toLowerCase().includes(q) ||
        e.department.toLowerCase().includes(q) ||
        e.phone.includes(q)
    );
  }, [employees, query]);

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Directory"
          subtitle={`${employees.length} employees`}
          onBackPress={() => navigation.goBack()}
          rightIcon="person-add-outline"
          onRightPress={() => navigation.navigate('AddEmployee')}
        />
        <Input
          placeholder="Search name or department"
          value={query}
          onChangeText={setQuery}
          icon="search"
        />
      </View>

      <FlatList
        data={filtered}
        keyExtractor={(e) => e.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.xs }} />}
        ListEmptyComponent={
          <EmptyState
            icon="people-outline"
            title="No matches"
            message="Try a different name or department."
          />
        }
        renderItem={({ item }) => (
          <DirectoryRow
            employee={item}
            onPress={() => navigation.navigate('EmployeeDetail', { employeeId: item.id })}
            onCall={() => Linking.openURL(`tel:${item.phone}`)}
          />
        )}
      />
    </Screen>
  );
}

function DirectoryRow({
  employee, onPress, onCall,
}: { employee: Employee; onPress: () => void; onCall: () => void }) {
  const { colors: themeColors } = useTheme();
  return (
    <Card padded={false} onPress={onPress} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <Avatar name={employee.name} size={44} />
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold" numberOfLines={1}>{employee.name}</Text>
          <Text variant="caption" color={colors.textSecondary} numberOfLines={1}>
            {employee.department}
          </Text>
        </View>
        <Pressable onPress={onCall} hitSlop={8} style={[styles.callBtn, { backgroundColor: themeColors.primarySurface }]}>
          <Ionicons name="call" size={18} color={themeColors.primary} />
        </Pressable>
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  row: { flexDirection: 'row', alignItems: 'center', padding: spacing.sm },
  callBtn: {
    width: 40, height: 40, borderRadius: 20,
    alignItems: 'center', justifyContent: 'center',
  },
});
