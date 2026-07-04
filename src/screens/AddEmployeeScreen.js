import React, { useState } from 'react';
import { Alert } from 'react-native';
import { Screen, Header, Card, Button, Input } from '../components';
import { spacing } from '../theme/spacing';
import { useData } from '../context/DataContext';

// AddEmployeeScreen — single-entry form mentioned in the User Guide.
// (Bulk CSV import is referenced as a future enhancement.)
export default function AddEmployeeScreen({ navigation }) {
  const { addEmployee } = useData();

  const [name, setName] = useState('');
  const [department, setDepartment] = useState('');
  const [phone, setPhone] = useState('');
  const [avaya, setAvaya] = useState('');
  const [email, setEmail] = useState('');

  const onSubmit = () => {
    if (!name.trim() || !department.trim()) {
      Alert.alert('Almost there', 'Name and department are required.');
      return;
    }
    const e = addEmployee({ name, department, phone, avaya, email });
    Alert.alert('Added', `${e.name} is now in the directory.`, [
      { text: 'Done', onPress: () => navigation.goBack() },
    ]);
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
        <Input label="Full name" value={name} onChangeText={setName}
          placeholder="e.g. Yaw Boateng" icon="person-outline" />
        <Input label="Department" value={department} onChangeText={setDepartment}
          placeholder="e.g. IT" icon="business-outline" />
        <Input label="Personal phone" value={phone} onChangeText={setPhone}
          placeholder="+233 ..." icon="call-outline" keyboardType="phone-pad" />
        <Input label="Avaya extension" value={avaya} onChangeText={setAvaya}
          placeholder="e.g. 3403" icon="grid-outline" keyboardType="number-pad" />
        <Input label="Email" value={email} onChangeText={setEmail}
          placeholder="name@vra.com" icon="mail-outline"
          autoCapitalize="none" keyboardType="email-address" />
      </Card>

      <Button label="Add to directory" icon="checkmark-outline" onPress={onSubmit}
        style={{ marginTop: spacing.md }} />
      <Button label="Cancel" variant="ghost" onPress={() => navigation.goBack()}
        style={{ marginTop: spacing.xs }} />
    </Screen>
  );
}
