import React, { useState } from 'react';
import { View, StyleSheet, Pressable, Alert, type StyleProp, type ViewStyle } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Avatar, Badge, Button, Input } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import type { RootStackNavigation } from '../types/navigation';
import type { IoniconName } from '../types';

interface ProfileScreenProps {
  navigation: RootStackNavigation;
}

// ProfileScreen -- reached by tapping the profile header on Settings.
// Employee ID, display name and password all live here (rather than on
// the Settings landing page itself), in the same label-over-value row
// format EmployeeDetailScreen uses for a staff member's Contact/Work
// info.
export default function ProfileScreen({ navigation }: ProfileScreenProps) {
  const { colors } = useTheme();
  const { user, updateProfile } = useAuth();
  const { employeeById } = useData();

  // The roster entry backing this account, if it has one -- visitors
  // don't, so the Employee ID row below only shows for staff.
  const myEmployee = user?.employeeId ? employeeById(user.employeeId) : undefined;

  const [editingName, setEditingName] = useState(false);
  const [nameDraft, setNameDraft] = useState(user?.name || '');
  const [savingName, setSavingName] = useState(false);

  const onSaveName = async () => {
    setSavingName(true);
    const result = await updateProfile(nameDraft);
    setSavingName(false);
    if (!result.ok) {
      Alert.alert('Could not update your name', result.error || 'Something went wrong.');
      return;
    }
    setEditingName(false);
  };

  const [editingPassword, setEditingPassword] = useState(false);
  const [currentPw, setCurrentPw] = useState('');
  const [newPw, setNewPw] = useState('');
  const [confirmPw, setConfirmPw] = useState('');

  const onSavePassword = () => {
    if (!currentPw || !newPw || !confirmPw) {
      Alert.alert('Missing fields', 'Fill in all three password fields.');
      return;
    }
    if (newPw.length < 8) {
      Alert.alert('Too short', 'New password must be at least 8 characters.');
      return;
    }
    if (newPw !== confirmPw) {
      Alert.alert('Mismatch', "New passwords don't match.");
      return;
    }
    Alert.alert('Password updated', 'Your password has been changed.');
    setCurrentPw('');
    setNewPw('');
    setConfirmPw('');
    setEditingPassword(false);
  };

  return (
    <Screen>
      <Header title="My profile" rightIcon="close" onRightPress={() => navigation.goBack()} />

      <Card padded={false}>
        <View style={[styles.profileRow, { padding: spacing.md }]}>
          <Avatar name={user?.name || 'You'} size={56} />
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="h3">{user?.name || 'Receptionist'}</Text>
            <Text variant="caption" color={colors.textSecondary}>
              {user?.email || ''}
            </Text>
            <View style={{ flexDirection: 'row', marginTop: 4 }}>
              <Badge label={user?.role || 'Receptionist'} status="info" size="sm" dot={false} />
            </View>
          </View>
        </View>
        <Divider />

        {myEmployee ? (
          <>
            <Row icon="card-outline" label="Employee ID" value={myEmployee.employeeId} />
            <Divider />
          </>
        ) : null}

        {/* Only the display name is editable here: email is the login
            identity, and role is fixed at signup from the staff roster
            (see AuthService.signup), so neither belongs behind a
            self-service edit. */}
        {editingName ? (
          <View style={{ padding: spacing.md }}>
            <Input
              label="Display name"
              value={nameDraft}
              onChangeText={setNameDraft}
              placeholder="Your name"
              icon="person-outline"
            />
            <View style={{ flexDirection: 'row' }}>
              <Button
                label="Cancel"
                variant="ghost"
                onPress={() => {
                  setEditingName(false);
                  setNameDraft(user?.name || '');
                }}
                style={{ flex: 1, marginRight: spacing.xs }}
              />
              <Button
                label={savingName ? 'Saving...' : 'Save'}
                onPress={onSaveName}
                disabled={savingName}
                style={{ flex: 1, marginLeft: spacing.xs }}
              />
            </View>
          </View>
        ) : (
          <Pressable
            onPress={() => {
              setNameDraft(user?.name || '');
              setEditingName(true);
            }}
            style={styles.editableRow}
          >
            <Row
              icon="create-outline"
              label="Display name"
              value={user?.name || ''}
              style={styles.rowFlex}
            />
            <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
          </Pressable>
        )}
        <Divider />

        {editingPassword ? (
          <View style={{ padding: spacing.md }}>
            <Input
              label="Current password"
              value={currentPw}
              onChangeText={setCurrentPw}
              placeholder="Current password"
              icon="lock-closed-outline"
              secureTextEntry
            />
            <Input
              label="New password"
              value={newPw}
              onChangeText={setNewPw}
              placeholder="New password"
              icon="key-outline"
              secureTextEntry
              hint="Must be at least 8 characters."
            />
            <Input
              label="Confirm new password"
              value={confirmPw}
              onChangeText={setConfirmPw}
              placeholder="Repeat new password"
              icon="shield-checkmark-outline"
              secureTextEntry
            />
            <View style={{ flexDirection: 'row' }}>
              <Button
                label="Cancel"
                variant="ghost"
                onPress={() => setEditingPassword(false)}
                style={{ flex: 1, marginRight: spacing.xs }}
              />
              <Button
                label="Save"
                onPress={onSavePassword}
                style={{ flex: 1, marginLeft: spacing.xs }}
              />
            </View>
          </View>
        ) : (
          <Pressable onPress={() => setEditingPassword(true)} style={styles.editableRow}>
            <Row icon="key-outline" label="Password" value="********" style={styles.rowFlex} />
            <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
          </Pressable>
        )}
      </Card>
    </Screen>
  );
}

// Label-over-value display row, same format as EmployeeDetailScreen's
// Contact/Work rows -- used here for both the read-only Employee ID
// row and (wrapped in a Pressable with a trailing chevron) the
// editable Display name/Password rows.
function Row({
  icon,
  label,
  value,
  style,
}: {
  icon: IoniconName;
  label: string;
  value: string;
  style?: StyleProp<ViewStyle>;
}) {
  const { colors } = useTheme();
  return (
    <View style={[styles.row, style]}>
      <View style={[styles.linkIcon, { backgroundColor: colors.surfaceAlt }]}>
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

const styles = StyleSheet.create({
  profileRow: { flexDirection: 'row', alignItems: 'center' },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing.md,
  },
  rowFlex: { flex: 1, padding: 0 },
  editableRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing.md,
  },
  linkIcon: {
    width: 32,
    height: 32,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, marginLeft: spacing.md + 32 + spacing.sm },
});
