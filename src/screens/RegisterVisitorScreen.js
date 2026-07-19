import React, { useState } from 'react';
import { View, StyleSheet, Pressable, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Button, Input, Select, Badge,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { visitPurposes, nextBadgeId } from '../data/mockData';

// RegisterVisitorScreen — modal opened from the visitors tab + dashboard.
// Implements the Check-In form from VisiLog spec + User Guide:
//   - First/Last name, phone, company, purpose (dropdown), host (dropdown)
//   - Badge number auto-generated and shown read-only
//   - Optional photo placeholder
//   - Optional consent / signature toggle
// Submitting registers AND checks the visitor in (single click flow).
export default function RegisterVisitorScreen({ navigation }) {
  const { colors: themeColors } = useTheme();
  const { employees, visitors, registerAndCheckIn } = useData();

  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [phone, setPhone] = useState('');
  const [company, setCompany] = useState('');
  const [purpose, setPurpose] = useState('Official Business');
  const [otherPurpose, setOtherPurpose] = useState('');
  const [hostId, setHostId] = useState(null);
  const [consent, setConsent] = useState(true);
  const [photoAdded, setPhotoAdded] = useState(false);

  const [errors, setErrors] = useState({});
  const [submitting, setSubmitting] = useState(false);

  // Preview of the badge ID that will be assigned. Recomputed every render
  // so it stays accurate if the visitor list changes underneath.
  const previewBadge = nextBadgeId(visitors);

  const onSubmit = async () => {
    if (submitting) return;
    const nextErrors = {};
    if (!firstName.trim()) nextErrors.firstName = 'Enter the visitor\u2019s first name.';
    if (!lastName.trim()) nextErrors.lastName = 'Enter the visitor\u2019s last name.';
    if (!phone.trim()) nextErrors.phone = 'A phone number is required.';
    if (!hostId) nextErrors.hostId = 'Pick a host employee.';
    if (!consent) nextErrors.consent = 'Visitor consent is required to check in.';
    if (purpose === 'Other' && !otherPurpose.trim()) {
      nextErrors.otherPurpose = 'Describe the purpose of the visit.';
    }
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) return;

    setSubmitting(true);
    try {
      const visitor = await registerAndCheckIn({
        firstName, lastName, phone, company,
        purpose: purpose === 'Other' ? otherPurpose.trim() : purpose,
        hostId,
      });
      Alert.alert(
        'Checked in',
        `${visitor.fullName} (${visitor.badgeId}) is now on-site.`,
        [{ text: 'Done', onPress: () => navigation.goBack() }]
      );
    } catch (err) {
      Alert.alert('Could not check in visitor', err.message);
    } finally {
      setSubmitting(false);
    }
  };

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
        {/* Photo placeholder — tappable square that toggles a "photo added"
            state. A real build would launch expo-image-picker here. */}
        <Pressable
          onPress={() => setPhotoAdded((p) => !p)}
          style={[styles.photo, photoAdded && styles.photoAdded]}
        >
          <Ionicons
            name={photoAdded ? 'checkmark-circle' : 'camera-outline'}
            size={26}
            color={photoAdded ? colors.status.success.solid : colors.textMuted}
          />
          <Text variant="caption" color={colors.textSecondary} style={{ marginTop: 4 }}>
            {photoAdded ? 'Photo captured' : 'Tap to add photo (optional)'}
          </Text>
        </Pressable>

        <View style={styles.nameRow}>
          <View style={{ flex: 1 }}>
            <Input
              label="First name"
              value={firstName}
              onChangeText={setFirstName}
              placeholder="e.g. Aseye"
              error={errors.firstName}
            />
          </View>
          <View style={{ width: spacing.sm }} />
          <View style={{ flex: 1 }}>
            <Input
              label="Last name"
              value={lastName}
              onChangeText={setLastName}
              placeholder="e.g. Abugri"
              error={errors.lastName}
            />
          </View>
        </View>

        <Input
          label="Phone number"
          value={phone}
          onChangeText={setPhone}
          placeholder="+233 ..."
          icon="call-outline"
          keyboardType="phone-pad"
          error={errors.phone}
        />

        <Input
          label="Company (optional)"
          value={company}
          onChangeText={setCompany}
          placeholder="e.g. Adansi Logistics"
          icon="business-outline"
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
            placeholder="What's the purpose of the visit?"
            icon="create-outline"
            error={errors.otherPurpose}
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

        {/* Badge number (auto-generated, read-only preview) */}
        <View style={[styles.badgePreview, { backgroundColor: themeColors.primarySurface }]}>
          <Ionicons name="card-outline" size={18} color={themeColors.brand} />
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="caption" color={colors.textSecondary}>
              Badge number (auto-generated)
            </Text>
            <Text variant="bodySemibold">{previewBadge}</Text>
          </View>
          <Badge label="Auto" status="info" size="sm" />
        </View>

        {/* Consent / digital signature */}
        <Pressable
          onPress={() => setConsent((c) => !c)}
          style={styles.consent}
        >
          <View style={[styles.checkbox, consent && { backgroundColor: themeColors.primary, borderColor: themeColors.primary }]}>
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
          <Text variant="caption" color={colors.status.error.solid} style={{ marginTop: -8, marginBottom: 8 }}>
            {errors.consent}
          </Text>
        ) : null}
      </Card>

      <Button
        label="Check in visitor"
        icon="checkmark-circle-outline"
        onPress={onSubmit}
        loading={submitting}
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

const styles = StyleSheet.create({
  photo: {
    height: 88,
    borderWidth: 1,
    borderColor: colors.border,
    borderStyle: 'dashed',
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.md,
    backgroundColor: colors.surfaceAlt,
  },
  photoAdded: {
    borderStyle: 'solid',
    borderColor: colors.status.success.solid,
    backgroundColor: colors.status.success.bg,
  },
  nameRow: { flexDirection: 'row' },
  badgePreview: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: radius.md,
    padding: spacing.sm,
    marginBottom: spacing.md,
  },
  consent: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing.xs,
  },
  checkbox: {
    width: 20, height: 20, borderRadius: 6,
    borderWidth: 1.5, borderColor: colors.borderStrong,
    alignItems: 'center', justifyContent: 'center',
  },
});
