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
  Segmented,
  BookMeetingForm,
  StepProgress,
  StepNav,
} from '../components';
import { DatePicker, TimePicker } from '../components/QuickDateTime';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { visitPurposes } from '../data/mockData';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';

interface VisitorBookingScreenProps {
  navigation: RootStackNavigation;
}

type BookingMode = 'visitor' | 'internal';

const STEPS = ['Visitor', 'Details', 'When'];

// VisitorBookingScreen -- the receptionist's "Book" tab. Defaults to
// the online visitor pre-registration form (booking on behalf of a
// visitor who called or walked up), with a toggle to switch over to
// booking an internal meeting -- reception needs to reserve rooms too,
// not just register outside visitors.
//
// Submitting the visitor form creates a new appointment in 'pending'
// status, mirroring the real visitor-side flow.
export default function VisitorBookingScreen({ navigation }: VisitorBookingScreenProps) {
  const { colors } = useTheme();
  const { employees, bookVisit } = useData();
  const [mode, setMode] = useState<BookingMode>('visitor');

  const [visitorName, setVisitorName] = useState('');
  const [visitorPhone, setVisitorPhone] = useState('');
  const [visitorEmail, setVisitorEmail] = useState('');
  const [visitorCompany, setVisitorCompany] = useState('');
  const [purpose, setPurpose] = useState('Official Business');
  const [otherPurpose, setOtherPurpose] = useState('');
  const [hostId, setHostId] = useState<string | null>(null);
  const [date, setDate] = useState(formatDate(new Date()));
  const [time, setTime] = useState('10:00');
  const [submitting, setSubmitting] = useState(false);
  const submittingRef = useRef(false);
  const [step, setStep] = useState(0);

  const visitorStepProblem = (): string | null => {
    if (!visitorName.trim() || !visitorPhone.trim()) return 'Name and phone are required.';
    return null;
  };

  const detailsStepProblem = (): string | null => {
    if (!hostId) return 'Pick who they’re visiting.';
    if (purpose === 'Other' && !otherPurpose.trim()) {
      return 'Please describe the purpose of the visit.';
    }
    return null;
  };

  const onNextStep = () => {
    const problem = step === 0 ? visitorStepProblem() : step === 1 ? detailsStepProblem() : null;
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
      Alert.alert('Already booking', 'This appointment is already being submitted.');
      return;
    }
    const problem = visitorStepProblem() || detailsStepProblem();
    if (problem) {
      Alert.alert('Almost there', problem);
      setStep(visitorStepProblem() ? 0 : 1);
      return;
    }
    submittingRef.current = true;
    setSubmitting(true);
    try {
      await bookVisit({
        visitorName: visitorName.trim(),
        visitorPhone: visitorPhone.trim(),
        visitorEmail: visitorEmail.trim(),
        visitorCompany: visitorCompany.trim(),
        purpose: purpose === 'Other' ? otherPurpose.trim() : purpose,
        hostId: hostId as string,
        scheduledAt: toInstant(date, time),
      });
      Alert.alert(
        'Appointment requested',
        `${visitorName} is now in the pending queue. The host will be notified to approve the visit.`,
        [{ text: 'Done', onPress: () => navigation.navigate('Home') }],
      );
    } catch (err) {
      Alert.alert(
        'Could not request appointment',
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
        eyebrow={mode === 'visitor' ? 'Pre-registration' : 'Self-service'}
        title={mode === 'visitor' ? 'Book a visit' : 'Book a meeting'}
        subtitle={
          mode === 'visitor'
            ? 'Face-to-face bookings taken over the phone or in person'
            : 'Reserve a room (or an outside spot) for an internal meeting'
        }
      />

      <Segmented
        value={mode}
        onChange={(m) => {
          setMode(m);
          setStep(0);
        }}
        options={[
          { label: 'Visitor booking', value: 'visitor' },
          { label: 'Internal meeting', value: 'internal' },
        ]}
        style={{ marginBottom: spacing.md }}
      />

      {mode === 'internal' ? (
        <BookMeetingForm onDone={() => navigation.navigate('Home')} />
      ) : (
        <>
          <Card>
            <StepProgress steps={STEPS} current={step} />

            {step === 0 ? (
              <>
                <View style={[styles.notice, { backgroundColor: colors.primarySurface }]}>
                  <Ionicons name="information-circle" size={18} color={colors.primary} />
                  <Text variant="caption" color={colors.brand} style={{ marginLeft: 8, flex: 1 }}>
                    Pre-booking speeds up reception. You will receive a QR code & badge ID after
                    approval.
                  </Text>
                </View>

                <Input
                  label="Full name"
                  value={visitorName}
                  onChangeText={setVisitorName}
                  placeholder="e.g. Selasi Akoto"
                  icon="person-outline"
                />

                <Input
                  label="Phone number"
                  value={visitorPhone}
                  onChangeText={setVisitorPhone}
                  placeholder="+233 ..."
                  icon="call-outline"
                  keyboardType="phone-pad"
                />

                <Input
                  label="Email (optional)"
                  value={visitorEmail}
                  onChangeText={setVisitorEmail}
                  placeholder="name@example.com"
                  icon="mail-outline"
                  autoCapitalize="none"
                  keyboardType="email-address"
                />

                <Input
                  label="Company (optional)"
                  value={visitorCompany}
                  onChangeText={setVisitorCompany}
                  placeholder="Your organisation"
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
                    placeholder="What's the purpose of the visit?"
                    icon="create-outline"
                  />
                ) : null}

                <Select
                  label="Who are you visiting?"
                  placeholder="Pick a host..."
                  value={hostId}
                  onChange={setHostId}
                  icon="people-outline"
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
                <Text variant="label" color={colors.textSecondary} style={{ marginBottom: 4 }}>
                  Date
                </Text>
                <DatePicker value={date} onChange={setDate} />
                <Text variant="label" color={colors.textSecondary} style={{ marginBottom: 4 }}>
                  Time
                </Text>
                <TimePicker value={time} onChange={setTime} />
              </>
            ) : null}
          </Card>

          <StepNav
            current={step}
            total={STEPS.length}
            onBack={() => setStep((s) => Math.max(0, s - 1))}
            onNext={onNextStep}
            finishLabel="Request appointment"
            finishIcon="checkmark-circle-outline"
            loading={submitting}
          />
        </>
      )}
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
// "YYYY-MM-DDTHH:MM" alone isn't parseable as one and was silently
// failing every appointment request with a generic error.
function toInstant(dateStr: string, timeStr: string): string {
  return new Date(`${dateStr}T${timeStr}:00`).toISOString();
}

const styles = StyleSheet.create({
  notice: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    borderRadius: radius.md,
    padding: spacing.sm,
    marginBottom: spacing.md,
  },
  dateRow: { flexDirection: 'row' },
});
