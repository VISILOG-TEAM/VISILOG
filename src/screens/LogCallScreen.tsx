import React, { useState } from 'react';
import { Alert } from 'react-native';
import { Screen, Header, Card, Button, Input, Select, StepProgress, StepNav } from '../components';
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

const STEPS = ['Call', 'Who', 'Notes'];

// LogCallScreen -- record a new call.
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
  const [step, setStep] = useState(0);

  const [errors, setErrors] = useState<LogCallErrors>({});

  const callStepProblem = (): string | null => {
    if (!callerName.trim()) return 'Enter the caller’s name (or "Unknown").';
    if (!callerPhone.trim()) return 'A phone number is required.';
    return null;
  };

  const whoStepProblem = (): string | null => {
    if (!hostId) return 'Pick the host the call is for.';
    return null;
  };

  const onNext = () => {
    const problem = step === 0 ? callStepProblem() : step === 1 ? whoStepProblem() : null;
    if (problem) {
      setErrors({
        callerName: !callerName.trim() ? problem : undefined,
        callerPhone: callerName.trim() && !callerPhone.trim() ? problem : undefined,
        hostId: step === 1 && !hostId ? problem : undefined,
      });
      Alert.alert('Almost there', problem);
      return;
    }
    if (step === STEPS.length - 1) {
      onSubmit();
      return;
    }
    setErrors({});
    setStep((s) => s + 1);
  };

  const onSubmit = async () => {
    const problem = callStepProblem() || whoStepProblem();
    if (problem) {
      Alert.alert('Almost there', problem);
      setStep(callStepProblem() ? 0 : 1);
      return;
    }

    try {
      const call = await logCall({
        callerName,
        callerPhone,
        hostId: hostId as string,
        callType,
        purpose,
        durationMinutes,
        notes,
      });
      Alert.alert('Call logged', `${call.callType} from ${call.callerName}.`, [
        { text: 'Done', onPress: () => navigation.goBack() },
      ]);
    } catch (err) {
      Alert.alert(
        'Could not log call',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
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
        <StepProgress steps={STEPS} current={step} />

        {step === 0 ? (
          <>
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
          </>
        ) : null}

        {step === 1 ? (
          <>
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
          </>
        ) : null}

        {step === 2 ? (
          <>
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
          </>
        ) : null}
      </Card>

      <StepNav
        current={step}
        total={STEPS.length}
        onBack={() => setStep((s) => Math.max(0, s - 1))}
        onNext={onNext}
        finishLabel="Save call record"
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
