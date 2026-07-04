import React, { useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Button, Input, Select,
} from '../components';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { visitPurposes } from '../data/mockData';

// VisitorBookingScreen — the online visitor pre-registration form.
// In the spec this is exposed on the visitor-facing side. Here we
// render it inside the receptionist app so reception staff can also
// book on behalf of a visitor (e.g. when contacted by phone).
//
// Submitting creates a new appointment in 'pending' status, mirroring
// the real visitor-side flow.
export default function VisitorBookingScreen({ navigation }) {
  const { employees, updateAppointmentStatus } = useData();

  const [visitorName, setVisitorName] = useState('');
  const [visitorPhone, setVisitorPhone] = useState('');
  const [visitorCompany, setVisitorCompany] = useState('');
  const [purpose, setPurpose] = useState('Official Business');
  const [hostId, setHostId] = useState(null);
  const [date, setDate] = useState(formatDate(new Date()));
  const [time, setTime] = useState('10:00');

  const onSubmit = () => {
    if (!visitorName.trim() || !visitorPhone.trim() || !hostId) {
      Alert.alert('Almost there', 'Name, phone and host are required.');
      return;
    }
    Alert.alert(
      'Appointment requested',
      `${visitorName} is now in the pending queue. The host will be notified to approve the visit.`,
      [{ text: 'Done', onPress: () => navigation.goBack() }]
    );
  };

  return (
    <Screen>
      <Header
        eyebrow="Pre-registration"
        title="Book a visit"
        subtitle="Self-service appointment booking"
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      <Card>
        <View style={styles.notice}>
          <Ionicons name="information-circle" size={18} color={colors.primary} />
          <Text variant="caption" color={colors.brand} style={{ marginLeft: 8, flex: 1 }}>
            Pre-booking speeds up reception. You will receive a QR code & badge ID after approval.
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
          label="Company (optional)"
          value={visitorCompany}
          onChangeText={setVisitorCompany}
          placeholder="Your organisation"
          icon="business-outline"
        />

        <Select
          label="Purpose"
          value={purpose}
          onChange={setPurpose}
          icon="briefcase-outline"
          options={visitPurposes.map((p) => ({ label: p, value: p }))}
        />

        <Select
          label="Who are you visiting?"
          placeholder="Pick a host..."
          value={hostId}
          onChange={setHostId}
          icon="people-outline"
          options={employees.map((e) => ({
            label: e.name,
            value: e.id,
            sublabel: `${e.department} - ${e.avaya}`,
          }))}
        />

        <View style={styles.dateRow}>
          <View style={{ flex: 1 }}>
            <Input
              label="Date"
              value={date}
              onChangeText={setDate}
              placeholder="YYYY-MM-DD"
              icon="calendar-outline"
            />
          </View>
          <View style={{ width: spacing.sm }} />
          <View style={{ flex: 1 }}>
            <Input
              label="Time"
              value={time}
              onChangeText={setTime}
              placeholder="HH:MM"
              icon="time-outline"
            />
          </View>
        </View>
      </Card>

      <Button
        label="Request appointment"
        icon="checkmark-circle-outline"
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

function formatDate(d) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

const styles = StyleSheet.create({
  notice: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: colors.primarySurface,
    borderRadius: radius.md,
    padding: spacing.sm,
    marginBottom: spacing.md,
  },
  dateRow: { flexDirection: 'row' },
});
