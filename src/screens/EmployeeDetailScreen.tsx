import React from 'react';
import { View, StyleSheet, Pressable, Linking, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Avatar, Button } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { ApiError } from '../api/client';
import type { RootStackScreenProps } from '../types/navigation';
import type { IoniconName } from '../types';

const capitalize = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

// EmployeeDetailScreen -- single staff member's profile.
export default function EmployeeDetailScreen({
  route,
  navigation,
}: RootStackScreenProps<'EmployeeDetail'>) {
  const { colors } = useTheme();
  const { employeeId } = route.params;
  const { employees, removeEmployee } = useData();
  const employee = employees.find((e) => e.id === employeeId);

  if (!employee) {
    return (
      <Screen>
        <Header title="Not found" rightIcon="close" onRightPress={() => navigation.goBack()} />
      </Screen>
    );
  }

  const onRemove = () => {
    Alert.alert('Remove employee?', `${employee.name} will be removed from the directory.`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Remove',
        style: 'destructive',
        onPress: async () => {
          try {
            await removeEmployee(employee.id);
            navigation.goBack();
          } catch (err) {
            Alert.alert(
              'Could not remove employee',
              err instanceof ApiError ? err.message : 'Something went wrong.',
            );
          }
        },
      },
    ]);
  };

  return (
    <Screen>
      <Header title="Staff profile" rightIcon="close" onRightPress={() => navigation.goBack()} />

      <Card>
        <View style={styles.headerRow}>
          <Avatar name={employee.name} size={64} />
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="h2">{employee.name}</Text>
            <Text variant="caption" color={colors.textSecondary}>
              {employee.department}
            </Text>
          </View>
        </View>

        <View style={styles.actionRow}>
          <ActionPill
            icon="call"
            label="Call"
            onPress={() => Linking.openURL(`tel:${employee.phone}`)}
          />
          <ActionPill
            icon="mail"
            label="Email"
            onPress={() => Linking.openURL(`mailto:${employee.email}`)}
          />
          <ActionPill
            icon="chatbubble-ellipses"
            label="Message"
            onPress={() => Linking.openURL(`sms:${employee.phone}`)}
          />
        </View>
      </Card>

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Contact
      </Text>
      <Card>
        <Row icon="call-outline" label="Personal phone" value={employee.phone} />
        <Divider />
        <Row icon="mail-outline" label="Email" value={employee.email} />
      </Card>

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Work
      </Text>
      <Card>
        <Row icon="briefcase-outline" label="Department" value={employee.department} />
        <Divider />
        <Row icon="shield-outline" label="Role" value={capitalize(employee.role)} />
        <Divider />
        <Row icon="card-outline" label="Employee ID" value={employee.employeeId} />
      </Card>

      <Button
        label="Remove from directory"
        variant="secondary"
        icon="trash-outline"
        onPress={onRemove}
        style={{ marginTop: spacing.xl }}
      />
    </Screen>
  );
}

function Row({ icon, label, value }: { icon: IoniconName; label: string; value: string }) {
  const { colors } = useTheme();
  return (
    <View style={styles.row}>
      <View style={[styles.icon, { backgroundColor: colors.surfaceAlt }]}>
        <Ionicons name={icon} size={18} color={colors.brand} />
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="caption" color={colors.textSecondary}>
          {label}
        </Text>
        <Text variant="bodySemibold">{value}</Text>
      </View>
    </View>
  );
}

function Divider() {
  const { colors } = useTheme();
  return <View style={[styles.divider, { backgroundColor: colors.border }]} />;
}

function ActionPill({
  icon,
  label,
  onPress,
}: {
  icon: IoniconName;
  label: string;
  onPress: () => void;
}) {
  const { colors } = useTheme();
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.pill,
        { backgroundColor: colors.primarySurface },
        pressed && { opacity: 0.85 },
      ]}
    >
      <Ionicons name={icon} size={18} color={colors.primary} />
      <Text variant="caption" color={colors.brand} style={{ marginTop: 2 }}>
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  headerRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.md },
  actionRow: { flexDirection: 'row', gap: spacing.xs },
  pill: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: spacing.sm,
    borderRadius: radius.md,
  },
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: spacing.xs },
  icon: {
    width: 32,
    height: 32,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, marginVertical: spacing.xs, marginLeft: 32 + spacing.sm },
});
