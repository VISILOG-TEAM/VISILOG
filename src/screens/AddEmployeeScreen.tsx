import React, { useState } from 'react';
import { Alert } from 'react-native';
import { Screen, Header, Card, Button, Input, Select, StepProgress, StepNav } from '../components';
import { spacing } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type { Role } from '../types';

interface AddEmployeeScreenProps {
  navigation: RootStackNavigation;
}

const STEPS = ['Identity', 'Contact', 'Role'];

// AddEmployeeScreen -- single-entry form mentioned in the User Guide.
// (Bulk CSV import is referenced as a future enhancement.)
//
// Role matters here in a way it didn't before: this roster is exactly
// what AuthService.signup checks emails against, so the role picked
// here is what someone gets automatically the moment they sign up with
// this email -- no picker step for them at all.
export default function AddEmployeeScreen({ navigation }: AddEmployeeScreenProps) {
  const { addEmployee } = useData();

  const [employeeId, setEmployeeId] = useState('');
  const [name, setName] = useState('');
  const [department, setDepartment] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [role, setRole] = useState<Role>('employee');
  const [step, setStep] = useState(0);

  const identityStepProblem = (): string | null => {
    if (!employeeId.trim() || !name.trim() || !department.trim()) {
      return 'Employee ID, name and department are required.';
    }
    return null;
  };

  const contactStepProblem = (): string | null => {
    if (!email.trim()) return 'Email is required.';
    return null;
  };

  const onNext = () => {
    const problem = step === 0 ? identityStepProblem() : step === 1 ? contactStepProblem() : null;
    if (problem) {
      Alert.alert('Almost there', problem);
      return;
    }
    if (step === STEPS.length - 1) {
      onSubmit();
      return;
    }
    setStep((s) => s + 1);
  };

  const onSubmit = async () => {
    const problem = identityStepProblem() || contactStepProblem();
    if (problem) {
      Alert.alert('Almost there', problem);
      setStep(identityStepProblem() ? 0 : 1);
      return;
    }
    try {
      const e = await addEmployee({ employeeId, name, department, phone, email, role });
      Alert.alert('Added', `${e.name} is now in the directory.`, [
        { text: 'Done', onPress: () => navigation.goBack() },
      ]);
    } catch (err) {
      Alert.alert(
        'Could not add employee',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
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
        <StepProgress steps={STEPS} current={step} />

        {step === 0 ? (
          <>
            <Input
              label="Employee ID"
              value={employeeId}
              onChangeText={setEmployeeId}
              placeholder="e.g. VRA-1009"
              icon="card-outline"
              autoCapitalize="characters"
            />
            <Input
              label="Full name"
              value={name}
              onChangeText={setName}
              placeholder="e.g. Yaw Boateng"
              icon="person-outline"
            />
            <Input
              label="Department"
              value={department}
              onChangeText={setDepartment}
              placeholder="e.g. IT"
              icon="business-outline"
            />
          </>
        ) : null}

        {step === 1 ? (
          <>
            <Input
              label="Personal phone"
              value={phone}
              onChangeText={setPhone}
              placeholder="+233 ..."
              icon="call-outline"
              keyboardType="phone-pad"
            />
            <Input
              label="Email"
              value={email}
              onChangeText={setEmail}
              placeholder="name@vra.com"
              icon="mail-outline"
              autoCapitalize="none"
              keyboardType="email-address"
            />
          </>
        ) : null}

        {step === 2 ? (
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
        ) : null}
      </Card>

      <StepNav
        current={step}
        total={STEPS.length}
        onBack={() => setStep((s) => Math.max(0, s - 1))}
        onNext={onNext}
        finishLabel="Add to directory"
        finishIcon="checkmark-outline"
      />
      <Button
        label="Cancel"
        variant="ghost"
        onPress={() => navigation.goBack()}
        style={{ marginTop: spacing.xs }}
      />
    </Screen>
  );
}
