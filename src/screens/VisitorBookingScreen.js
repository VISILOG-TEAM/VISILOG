import React, { useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Button, Input, Select, Segmented, BookMeetingForm,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { visitPurposes } from '../data/mockData';

// VisitorBookingScreen — the receptionist's "Book" tab. Defaults to
// the online visitor pre-registration form (booking on behalf of a
// visitor who called or walked up), with a toggle to switch over to
// booking an internal meeting — reception needs to reserve rooms too,
// not just register outside visitors.
//
// Submitting the visitor form creates a new appointment in 'pending'
// status, mirroring the real visitor-side flow.
export default function VisitorBookingScreen({ navigation }) {
  const { colors: themeColors } = useTheme();
  const { employees, bookVisit } = useData();
  const [mode, setMode] = useState('visitor'); // 'visitor' | 'internal'

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
    bookVisit({
      visitorName: visitorName.trim(),
      visitorPhone: visitorPhone.trim(),
      visitorCompany: visitorCompany.trim(),
      purpose,
      hostId,
      scheduledAt: `${date}T${time}`,
    });
    Alert.alert(
      'Appointment requested',
      `${visitorName} is now in the pending queue. The host will be notified to approve the visit.`,
      [{ text: 'Done', onPress: () => navigation.navigate('Home') }]
    );
  };

  return (
    <Screen>
      <Header
        eyebrow={mode === 'visitor' ? 'Pre-registration' : 'Self-service'}
        title={mode === 'visitor' ? 'Book a visit' : 'Book a meeting'}
        subtitle={mode === 'visitor'
          ? 'Face-to-face bookings taken over the phone or in person'
          : 'Reserve a room (or an outside spot) for an internal meeting'}
      />

      <Segmented
        value={mode}
        onChange={setMode}
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
        <View style={[styles.notice, { backgroundColor: themeColors.primarySurface }]}>
          <Ionicons name="information-circle" size={18} color={themeColors.primary} />
          <Text variant="caption" color={themeColors.brand} style={{ marginLeft: 8, flex: 1 }}>
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
      </>
      )}
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
    borderRadius: radius.md,
    padding: spacing.sm,
    marginBottom: spacing.md,
  },
  dateRow: { flexDirection: 'row' },
});
