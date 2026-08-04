import React, { useRef, useState } from 'react';
import { View, StyleSheet, Pressable, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Button, Input, Select, StepProgress, StepNav } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { visitPurposes } from '../data/mockData';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';

interface RegisterVisitorScreenProps {
  navigation: RootStackNavigation;
}

interface RegisterVisitorErrors {
  firstName?: string;
  lastName?: string;
  phone?: string;
  hostId?: string;
  consent?: string;
  otherPurpose?: string;
}

const STEPS = ['Visitor', 'Details', 'Confirm'];

// RegisterVisitorScreen -- modal opened from the visitors tab + dashboard.
// Implements the Check-In form from VisiLog spec + User Guide:
// - First/Last name, phone, company, purpose (dropdown), host (dropdown)
// - Badge number auto-generated server-side (see the "Checked in" alert)
// - Optional photo placeholder
// - Optional consent / signature toggle
// Submitting registers AND checks the visitor in (single click flow).
//
// Split across three steps rather than one long scroll, same reasoning
// as BookMeetingForm: who they are, then why they're here and who
// they're seeing, then a last confirm step with the consent checkbox --
// the thing worth a final look before submitting is consent, not
// re-editing the name fields.
export default function RegisterVisitorScreen({ navigation }: RegisterVisitorScreenProps) {
  const { colors } = useTheme();
  const { employees, registerAndCheckIn } = useData();

  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [company, setCompany] = useState('');
  const [purpose, setPurpose] = useState('Official Business');
  const [otherPurpose, setOtherPurpose] = useState('');
  const [hostId, setHostId] = useState<string | null>(null);
  const [consent, setConsent] = useState(true);
  const [step, setStep] = useState(0);

  const [errors, setErrors] = useState<RegisterVisitorErrors>({});
  const [submitting, setSubmitting] = useState(false);
  // useState's `submitting` only updates on the next render, so two taps
  // in the same event-loop tick (a fast double-tap) can both read it as
  // false and both fire. A ref updates synchronously, so it actually
  // blocks the second tap.
  const submittingRef = useRef(false);

  const visitorStepProblem = (): string | null => {
    if (!firstName.trim()) return 'Enter the visitor’s first name.';
    if (!lastName.trim()) return 'Enter the visitor’s last name.';
    if (!phone.trim()) return 'A phone number is required.';
    return null;
  };

  const detailsStepProblem = (): string | null => {
    if (!hostId) return 'Pick a host employee.';
    if (purpose === 'Other' && !otherPurpose.trim()) return 'Describe the purpose of the visit.';
    return null;
  };

  const onNext = () => {
    if (step === 0) {
      const problem = visitorStepProblem();
      if (problem) {
        setErrors({
          firstName: !firstName.trim() ? problem : undefined,
          lastName: firstName.trim() && !lastName.trim() ? problem : undefined,
          phone: firstName.trim() && lastName.trim() && !phone.trim() ? problem : undefined,
        });
        Alert.alert('Almost there', problem);
        return;
      }
    }
    if (step === 1) {
      const problem = detailsStepProblem();
      if (problem) {
        setErrors((e) => ({
          ...e,
          hostId: !hostId ? problem : undefined,
          otherPurpose: hostId && purpose === 'Other' && !otherPurpose.trim() ? problem : undefined,
        }));
        Alert.alert('Almost there', problem);
        return;
      }
    }
    if (step === STEPS.length - 1) {
      onSubmit();
      return;
    }
    setErrors({});
    setStep((s) => s + 1);
  };

  const onSubmit = async () => {
    if (submittingRef.current) return;
    const problem = visitorStepProblem() || detailsStepProblem();
    if (problem) {
      Alert.alert('Almost there', problem);
      setStep(visitorStepProblem() ? 0 : 1);
      return;
    }
    if (!consent) {
      setErrors((e) => ({ ...e, consent: 'Visitor consent is required to check in.' }));
      Alert.alert('Almost there', 'Visitor consent is required to check in.');
      return;
    }

    submittingRef.current = true;
    setSubmitting(true);
    try {
      const visitor = await registerAndCheckIn({
        firstName,
        lastName,
        phone,
        email,
        company,
        purpose: purpose === 'Other' ? otherPurpose.trim() : purpose,
        hostId: hostId as string,
      });
      Alert.alert('Checked in', `${visitor.fullName} (${visitor.badgeId}) is now on-site.`, [
        { text: 'Done', onPress: () => navigation.goBack() },
      ]);
    } catch (err) {
      Alert.alert(
        'Could not check in visitor',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
    } finally {
      submittingRef.current = false;
      setSubmitting(false);
    }
  };

  const hostName = employees.find((e) => e.id === hostId)?.name || 'No host picked';

  return (
    <Screen>
      <Header
        eyebrow="New visitor entry"
        title="Register & check in"
        subtitle="Capture visitor details, then admit to the building."
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      <Card>
        <StepProgress steps={STEPS} current={step} />

        {step === 0 ? (
          <>
            <View style={styles.nameRow}>
              <View style={{ flex: 1 }}>
                <Input
                  label="First name"
                  value={firstName}
                  onChangeText={setFirstName}
                  error={errors.firstName}
                  disableAutofill
                />
              </View>
              <View style={{ width: spacing.sm }} />
              <View style={{ flex: 1 }}>
                <Input
                  label="Last name"
                  value={lastName}
                  onChangeText={setLastName}
                  error={errors.lastName}
                  disableAutofill
                />
              </View>
            </View>

            <Input
              label="Phone number"
              value={phone}
              onChangeText={setPhone}
              icon="call-outline"
              keyboardType="phone-pad"
              error={errors.phone}
              disableAutofill
            />

            <Input
              label="Email (optional)"
              value={email}
              onChangeText={setEmail}
              icon="mail-outline"
              autoCapitalize="none"
              keyboardType="email-address"
              disableAutofill
            />
          </>
        ) : null}

        {step === 1 ? (
          <>
            <Input
              label="Company (optional)"
              value={company}
              onChangeText={setCompany}
              icon="business-outline"
              disableAutofill
            />

            <Select
              label="Purpose of visit"
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
                icon="create-outline"
                error={errors.otherPurpose}
                disableAutofill
              />
            ) : null}

            <Select
              label="Host employee"
              placeholder="Search staff directory..."
              value={hostId}
              onChange={setHostId}
              icon="people-outline"
              error={errors.hostId}
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
            <Text variant="h3" style={{ marginBottom: spacing.sm }}>
              {firstName.trim() || lastName.trim() ? `${firstName} ${lastName}`.trim() : 'New visitor'}
            </Text>
            <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.xs }}>
              {phone || 'No phone'} {email ? `- ${email}` : ''}
            </Text>
            <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
              Seeing {hostName} - {purpose === 'Other' ? otherPurpose : purpose}
            </Text>

            <Pressable onPress={() => setConsent((c) => !c)} style={styles.consent}>
              <View
                style={[
                  styles.checkbox,
                  { borderColor: colors.borderStrong },
                  consent && { backgroundColor: colors.primary, borderColor: colors.primary },
                ]}
              >
                {consent ? <Ionicons name="checkmark" size={14} color="#FFF" /> : null}
              </View>
              <View style={{ flex: 1, marginLeft: spacing.xs }}>
                <Text variant="bodyMd">Visitor agrees to site rules & data policy</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  Acts as the digital signature for this visit.
                </Text>
              </View>
            </Pressable>
            {errors.consent ? (
              <Text
                variant="caption"
                color={colors.status.error.solid}
                style={{ marginTop: -8, marginBottom: 8 }}
              >
                {errors.consent}
              </Text>
            ) : null}
          </>
        ) : null}
      </Card>

      <StepNav
        current={step}
        total={STEPS.length}
        onBack={() => setStep((s) => Math.max(0, s - 1))}
        onNext={onNext}
        finishLabel="Check in visitor"
        finishIcon="checkmark-circle-outline"
        loading={submitting}
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

const styles = StyleSheet.create({
  nameRow: { flexDirection: 'row' },
  consent: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing.xs,
  },
  checkbox: {
    width: 20,
    height: 20,
    borderRadius: 6,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
