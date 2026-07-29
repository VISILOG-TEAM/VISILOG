import React, { useMemo, useState } from 'react';
import { View, FlatList, StyleSheet, Pressable, Linking } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen,
  Header,
  Input,
  Text,
  Card,
  EmptyState,
  Avatar,
  CsvImportModal,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import type { RootStackNavigation } from '../types/navigation';
import type { Employee, EmployeeInput, Role } from '../types';
import { usePullToRefresh } from '../components/usePullToRefresh';

interface DirectoryScreenProps {
  navigation: RootStackNavigation;
}

// Accepts a wide range of header spellings so a real HR export (which
// almost never matches a fixed schema) doesn't need renaming first --
// "code"/"employee code"/"employeeid"/"staff id" all work for the id
// column, and FirstName+LastName combine into one name if there's no
// single "name" column at all.
function mapCsvRow(record: Record<string, string>): EmployeeInput {
  const firstName = record['firstname'] || record['first name'] || '';
  const lastName = record['lastname'] || record['last name'] || '';
  const combinedName = [firstName, lastName].filter(Boolean).join(' ');

  return {
    employeeId:
      record['code'] ||
      record['employee code'] ||
      record['employeecode'] ||
      record['employeeid'] ||
      record['employee id'] ||
      record['staff id'] ||
      record['id'] ||
      '',
    name: record['name'] || record['full name'] || record['fullname'] || combinedName || '',
    department: record['department'] || '',
    phone:
      record['phone'] || record['phone number'] || record['phonenumber'] || record['mobile'] || '',
    email: record['email'] || record['email address'] || record['emailaddress'] || '',
    role: (record['role'] || 'employee').toLowerCase() as Role,
  };
}

// DirectoryScreen -- the Phone Book.
// Lists every staff member; tap a row to open their detail page; tap
// the phone icon to dial straight from the device.
export default function DirectoryScreen({ navigation }: DirectoryScreenProps) {
  const refreshControl = usePullToRefresh();
  const { employees, bulkImportEmployees } = useData();
  const [query, setQuery] = useState('');
  const [importVisible, setImportVisible] = useState(false);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return employees;
    return employees.filter(
      (e) =>
        e.name.toLowerCase().includes(q) ||
        e.department.toLowerCase().includes(q) ||
        e.phone.includes(q),
    );
  }, [employees, query]);

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Directory"
          subtitle={`${employees.length} employees`}
          onBackPress={() => navigation.goBack()}
          rightActions={[
            { icon: 'document-attach-outline', onPress: () => setImportVisible(true) },
            { icon: 'person-add-outline', onPress: () => navigation.navigate('AddEmployee') },
          ]}
        />
        <Input
          placeholder="Search name or department"
          value={query}
          onChangeText={setQuery}
          icon="search"
        />
      </View>

      <FlatList
        refreshControl={refreshControl}
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

      <CsvImportModal
        visible={importVisible}
        onClose={() => setImportVisible(false)}
        title="Import staff"
        columnsHint="Needs a name and an email for each person. Staff ID, department, phone and role\nare used if your file has them -- a missing staff ID is generated, and a missing or\nunrecognised role becomes employee."
        mapRow={mapCsvRow}
        onImport={bulkImportEmployees}
      />
    </Screen>
  );
}

function DirectoryRow({
  employee,
  onPress,
  onCall,
}: {
  employee: Employee;
  onPress: () => void;
  onCall: () => void;
}) {
  const { colors } = useTheme();
  return (
    <Card padded={false} onPress={onPress} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <Avatar name={employee.name} size={44} />
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold" numberOfLines={1}>
            {employee.name}
          </Text>
          <Text variant="caption" color={colors.textSecondary} numberOfLines={1}>
            {employee.department}
          </Text>
        </View>
        <Pressable
          onPress={onCall}
          hitSlop={8}
          style={[styles.callBtn, { backgroundColor: colors.primarySurface }]}
        >
          <Ionicons name="call" size={18} color={colors.primary} />
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
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
