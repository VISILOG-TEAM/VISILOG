import React, { useState } from 'react';
import { Alert } from 'react-native';
import {
  Screen, Header, Card, Button, Input, Select,
} from '../components';
import { spacing } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { callTypes } from '../data/mockData';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';

interface LogCallScreenProps {
  navigation: RootStackNavigation;
}

interface LogCallErrors {
  callerName?: string;
  callerPhone?: string;
  hostId?: string;
}

// LogCallScreen — record a new call.
// Per the User Guide: caller name, phone, duration, notes, host, call type, purpose.
export default function LogCallScreen({ navigation }: LogCallScreenProps) {
  const { employees, logCall } = useData();

  const [callerName, setCallerName] = useState('');
  const [callerPhone, setCallerPhone] = useState('');
  const [hostId, setHostId] = useState<string | null>(null);
  const [callType, setCallType] = useState('Incoming');
  const [purpose, setPurpose] = useState('');
  const [durationMinutes, setDurationMinutes] = useState('');
  const [notes, setNotes] = useState('');

  const [errors, setErrors] = useState<LogCallErrors>({});

  const onSubmit = async () => {
    const e: LogCallErrors = {};
    if (!callerName.trim()) e.callerName = 'Enter the caller\u2019s name (or "Unknown").';
    if (!callerPhone.trim()) e.callerPhone = 'A phone number is required.';
    if (!hostId) e.hostId = 'Pick the host the call is for.';
    setErrors(e);
    if (Object.keys(e).length) return;

    try {
      const call = await logCall({
        callerName, callerPhone, hostId: hostId as string, callType, purpose, durationMinutes, notes,
      });
      Alert.alert('Call logged', `${call.callType} from ${call.callerName}.`, [
        { text: 'Done', onPress: () => navigation.goBack() },
      ]);
    } catch (err) {
      Alert.alert('Could not log call', err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  return (
    <Screen>
      <Header
        eyebrow="New call record"
        title="Log a call"
        subtitle="Capture incoming, outgoing & missed reception calls."
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      <Card>
        <Select
          label="Call type"
          value={callType}
          onChange={setCallType}
          icon="call-outline"
          options={callTypes.map((t) => ({ label: t, value: t }))}
        />

        <Input
          label="Caller name"
          value={callerName}
          onChangeText={setCallerName}
          placeholder="e.g. Joseph Tetteh"
          icon="person-outline"
          error={errors.callerName}
        />

        <Input
          label="Caller phone"
          value={callerPhone}
          onChangeText={setCallerPhone}
          placeholder="+233 ..."
          icon="call-outline"
          keyboardType="phone-pad"
          error={errors.callerPhone}
        />

        <Select
          label="Host"
          placeholder="Search staff..."
          value={hostId}
          onChange={setHostId}
          icon="people-outline"
          error={errors.hostId}
          options={employees.map((emp) => ({
            label: emp.name,
            value: emp.id,
            sublabel: emp.department,
          }))}
        />

        <Input
          label="Purpose"
          value={purpose}
          onChangeText={setPurpose}
          placeholder="e.g. Booking enquiry"
          icon="document-text-outline"
        />

        <Input
          label="Duration (minutes)"
          value={durationMinutes}
          onChangeText={setDurationMinutes}
          placeholder="0"
          icon="time-outline"
          keyboardType="number-pad"
        />

        <Input
          label="Notes (optional)"
          value={notes}
          onChangeText={setNotes}
          placeholder="What was discussed?"
          multiline
        />
      </Card>

      <Button
        label="Save call record"
        icon="checkmark-outline"
        onPress={onSubmit}
        style={{ marginTop: spacing.md }}
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
