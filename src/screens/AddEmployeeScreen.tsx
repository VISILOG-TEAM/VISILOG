import React, { useState } from 'react';
import { Alert } from 'react-native';
import { Screen, Header, Card, Button, Input, Select } from '../components';
import { spacing } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type { Role } from '../types';

interface AddEmployeeScreenProps {
  navigation: RootStackNavigation;
}

// AddEmployeeScreen — single-entry form mentioned in the User Guide.
// (Bulk CSV import is referenced as a future enhancement.)
//
// Role matters here in a way it didn't before: this roster is exactly
// what AuthService.signup checks emails against, so the role picked
// here is what someone gets automatically the moment they sign up with
// this email — no picker step for them at all.
export default function AddEmployeeScreen({ navigation }: AddEmployeeScreenProps) {
  const { addEmployee } = useData();

  const [employeeId, setEmployeeId] = useState('');
  const [name, setName] = useState('');
  const [department, setDepartment] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [role, setRole] = useState<Role>('employee');

  const onSubmit = async () => {
    if (!employeeId.trim() || !name.trim() || !department.trim() || !email.trim()) {
      Alert.alert('Almost there', 'Employee ID, name, department and email are required.');
      return;
    }
    try {
      const e = await addEmployee({ employeeId, name, department, phone, email, role });
      Alert.alert('Added', `${e.name} is now in the directory.`, [
        { text: 'Done', onPress: () => navigation.goBack() },
      ]);
    } catch (err) {
      Alert.alert('Could not add employee', err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  return (
    <Screen>
      <Header
        eyebrow="New directory entry"
        title="Add an employee"
        subtitle="Single entry. Bulk CSV import coming soon."
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      <Card>
        <Input label="Employee ID" value={employeeId} onChangeText={setEmployeeId}
          placeholder="e.g. VRA-1009" icon="card-outline" autoCapitalize="characters" />
        <Input label="Full name" value={name} onChangeText={setName}
          placeholder="e.g. Yaw Boateng" icon="person-outline" />
        <Input label="Department" value={department} onChangeText={setDepartment}
          placeholder="e.g. IT" icon="business-outline" />
        <Input label="Personal phone" value={phone} onChangeText={setPhone}
          placeholder="+233 ..." icon="call-outline" keyboardType="phone-pad" />
        <Input label="Email" value={email} onChangeText={setEmail}
          placeholder="name@vra.com" icon="mail-outline"
          autoCapitalize="none" keyboardType="email-address" />
        <Select
          label="Role"
          value={role}
          onChange={setRole}
          icon="shield-outline"
          options={[
            { label: 'Employee', value: 'employee' },
            { label: 'Receptionist', value: 'receptionist' },
            { label: 'Manager', value: 'manager' },
          ]}
        />
      </Card>

      <Button label="Add to directory" icon="checkmark-outline" onPress={onSubmit}
        style={{ marginTop: spacing.md }} />
      <Button label="Cancel" variant="ghost" onPress={() => navigation.goBack()}
        style={{ marginTop: spacing.xs }} />
    </Screen>
  );
}
