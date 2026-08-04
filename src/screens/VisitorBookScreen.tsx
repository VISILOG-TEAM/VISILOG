import React, { useRef, useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen,
  Header,
  Text,
  Card,
  Button,
  Input,
  Select,
  DatePicker,
  TimePicker,
  StepProgress,
  StepNav,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { visitPurposes } from '../data/mockData';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';

interface VisitorBookScreenProps {
  navigation: RootStackNavigation;
}

const STEPS = ['Your details', 'Visit details', 'When'];

// VisitorBookScreen -- the visitor's own "Book" tab. Was three sections
// (numbered headers, same fields) all shown in one long scroll; now one
// step at a time behind StepProgress/StepNav, same reasoning as
// BookMeetingForm -- the section numbering already told you this was
// meant to be filled in order, it just didn't enforce it.
export default function VisitorBookScreen({ navigation }: VisitorBookScreenProps) {
  const { colors } = useTheme();
  const { user } = useAuth();
  const { employees, bookVisit } = useData();

  const [name, setName] = useState(user!.name || '');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState(user!.email || '');
  const [company, setCompany] = useState('');
  const [purpose, setPurpose] = useState('Official Business');
  const [otherPurpose, setOtherPurpose] = useState('');
  const [hostId, setHostId] = useState<string | null>(null);
  const [date, setDate] = useState(formatDate(new Date()));
  const [time, setTime] = useState('10:00');
  const [submitting, setSubmitting] = useState(false);
  const submittingRef = useRef(false);
  const [step, setStep] = useState(0);

  const detailsStepProblem = (): string | null => {
    if (!name.trim() || !phone.trim()) return 'Name and phone are required.';
    return null;
  };

  const visitStepProblem = (): string | null => {
    if (!hostId) return 'Pick who you’re visiting.';
    if (purpose === 'Other' && !otherPurpose.trim()) {
      return 'Please describe the purpose of your visit.';
    }
    return null;
  };

  const whenStepProblem = (): string | null => {
    if (!date.trim() || !time.trim()) return 'Pick a date and time for your visit.';
    return null;
  };

  const onNext = () => {
    const problem =
      step === 0 ? detailsStepProblem() : step === 1 ? visitStepProblem() : null;
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
    if (submittingRef.current) {
      Alert.alert('Already booking', 'Your booking is already being submitted.');
      return;
    }
    const problem = detailsStepProblem() || visitStepProblem() || whenStepProblem();
    if (problem) {
      Alert.alert('Almost there', problem);
      setStep(detailsStepProblem() ? 0 : visitStepProblem() ? 1 : 2);
      return;
    }
    submittingRef.current = true;
    setSubmitting(true);
    try {
      await bookVisit({
        visitorName: name,
        visitorPhone: phone,
        visitorEmail: email,
        visitorCompany: company,
        purpose: purpose === 'Other' ? otherPurpose.trim() : purpose,
        hostId: hostId as string,
        scheduledAt: toInstant(date, time),
      });
      Alert.alert(
        'Booked',
        "Your visit request has been sent. You'll get a notification with your pass code once your host approves it.",
        [{ text: 'Done', onPress: () => navigation.navigate('Home') }],
      );
    } catch (err) {
      Alert.alert(
        'Could not book visit',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
    } finally {
      submittingRef.current = false;
      setSubmitting(false);
    }
  };

  return (
    <Screen>
      <Header
        eyebrow="Pre-registration"
        title="Book a visit"
        subtitle="Complete each step to request an appointment"
      />

      <Card>
        <StepProgress steps={STEPS} current={step} />

        {step === 0 ? (
          <>
            <Input label="Full name" value={name} onChangeText={setName} icon="person-outline" />
            <Input
              label="Phone"
              value={phone}
              onChangeText={setPhone}
              icon="call-outline"
              keyboardType="phone-pad"
            />
            <Input
              label="Email (optional)"
              value={email}
              onChangeText={setEmail}
              icon="mail-outline"
              autoCapitalize="none"
              keyboardType="email-address"
            />
            <Input
              label="Company (optional)"
              value={company}
              onChangeText={setCompany}
              icon="business-outline"
            />
          </>
        ) : null}

        {step === 1 ? (
          <>
            <Select
              label="Purpose"
              value={purpose}
              onChange={setPurpose}
              icon="briefcase-outline"
              options={visitPurposes.map((p) => ({ label: p, value: p }))}
            />
            {purpose === 'Other' ? (
              <Input
                label="Please specify"
                value={otherPurpose}
                onChangeText={setOtherPurpose}
                placeholder="What's the purpose of your visit?"
                icon="create-outline"
              />
            ) : null}
            <Select
              label="Who are you visiting?"
              value={hostId}
              onChange={setHostId}
              icon="people-outline"
              placeholder="Pick a host..."
              options={employees.map((e) => ({
                label: e.name,
                value: e.id,
                sublabel: e.department,
              }))}
            />
          </>
        ) : null}

        {step === 2 ? (
          <>
            <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>
              Date
            </Text>
            <DatePicker value={date} onChange={setDate} />
            <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>
              Time
            </Text>
            <TimePicker value={time} onChange={setTime} />

            <View style={[styles.notice, { backgroundColor: colors.primarySurface }]}>
              <Ionicons name="information-circle" size={18} color={colors.primary} />
              <Text variant="caption" color={colors.brand} style={{ marginLeft: 8, flex: 1 }}>
                You'll receive an NFC pass code once submitted -- show it at reception on arrival.
              </Text>
            </View>
          </>
        ) : null}
      </Card>

      <StepNav
        current={step}
        total={STEPS.length}
        onBack={() => setStep((s) => Math.max(0, s - 1))}
        onNext={onNext}
        finishLabel="Submit booking"
        finishIcon="checkmark-circle-outline"
        loading={submitting}
      />
    </Screen>
  );
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

// The backend expects a full ISO instant (with seconds + timezone);
// "YYYY-MM-DDTHH:MM" alone isn't parseable as one.
function toInstant(dateStr: string, timeStr: string): string {
  return new Date(`${dateStr}T${timeStr}:00`).toISOString();
}

const styles = StyleSheet.create({
  chipsLabel: { marginBottom: spacing.xs },
  notice: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    borderRadius: radius.md,
    padding: spacing.sm,
    marginTop: spacing.md,
  },
});
