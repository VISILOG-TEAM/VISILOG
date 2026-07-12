import React from 'react';
import { View, StyleSheet, Pressable, Linking, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Avatar, Button } from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';

// EmployeeDetailScreen — single staff member's profile.
export default function EmployeeDetailScreen({ route, navigation }) {
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
    Alert.alert(
      'Remove employee?',
      `${employee.name} will be removed from the directory.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove', style: 'destructive',
          onPress: () => { removeEmployee(employee.id); navigation.goBack(); },
        },
      ]
    );
  };

  return (
    <Screen>
      <Header
        title="Staff profile"
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

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
          <ActionPill icon="call" label="Call"
            onPress={() => Linking.openURL(`tel:${employee.phone}`)} />
          <ActionPill icon="mail" label="Email"
            onPress={() => Linking.openURL(`mailto:${employee.email}`)} />
          <ActionPill icon="chatbubble-ellipses" label="Message"
            onPress={() => Linking.openURL(`sms:${employee.phone}`)} />
        </View>
      </Card>

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>Contact</Text>
      <Card>
        <Row icon="call-outline" label="Personal phone" value={employee.phone} />
        <Divider />
        <Row icon="business-outline" label="Avaya extension" value={employee.avaya} />
        <Divider />
        <Row icon="mail-outline" label="Email" value={employee.email} />
        <Divider />
        <Row icon="briefcase-outline" label="Department" value={employee.department} />
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

function Row({ icon, label, value }) {
  const { colors: themeColors } = useTheme();
  return (
    <View style={styles.row}>
      <View style={styles.icon}>
        <Ionicons name={icon} size={18} color={themeColors.brand} />
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="caption" color={colors.textSecondary}>{label}</Text>
        <Text variant="bodySemibold">{value}</Text>
      </View>
    </View>
  );
}

function Divider() {
  return <View style={styles.divider} />;
}

function ActionPill({ icon, label, onPress }) {
  const { colors: themeColors } = useTheme();
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.pill, { backgroundColor: themeColors.primarySurface }, pressed && { opacity: 0.85 }]}>
      <Ionicons name={icon} size={18} color={themeColors.primary} />
      <Text variant="caption" color={themeColors.brand} style={{ marginTop: 2 }}>
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  headerRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.md },
  actionRow: { flexDirection: 'row', gap: spacing.xs },
  pill: {
    flex: 1, alignItems: 'center', paddingVertical: spacing.sm,
    borderRadius: radius.md,
  },
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: spacing.xs },
  icon: {
    width: 32, height: 32, borderRadius: 10,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center', justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, backgroundColor: colors.border, marginVertical: spacing.xs, marginLeft: 32 + spacing.sm },
});
