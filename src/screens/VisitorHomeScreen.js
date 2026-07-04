import React, { useState } from 'react';
import { View, StyleSheet, Alert, ScrollView } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Button, Input, Select, Badge, Avatar,
} from '../components';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { visitPurposes } from '../data/mockData';

// The visitor's only screen. Shows their NFC card if they've booked,
// otherwise the booking form. Plus a "help / contact" section.
export default function VisitorHomeScreen() {
  const { user, logout } = useAuth();
  const { employees, appointments, bookVisit } = useData();

  // Show their most recent booking (if any).
  const myBooking = appointments
    .filter((a) => a.bookedByEmail === user.email)
    .sort((a, b) => new Date(b.scheduledAt) - new Date(a.scheduledAt))[0];

  const [name, setName] = useState(user.name || '');
  const [phone, setPhone] = useState('');
  const [company, setCompany] = useState('');
  const [purpose, setPurpose] = useState('Official Business');
  const [hostId, setHostId] = useState(null);

  const onSubmit = () => {
    if (!name.trim() || !phone.trim() || !hostId) {
      Alert.alert('Almost there', 'Name, phone and host are required.');
      return;
    }
    const a = bookVisit({
      visitorName: name, visitorPhone: phone, visitorCompany: company,
      purpose, hostId, bookedByEmail: user.email,
    });
    Alert.alert('Booked', `Your visit code is ${a.nfcCode}. Show it at reception.`);
  };

  return (
    <Screen>
      <Header
        eyebrow="Welcome"
        title={`Hi, ${user.name?.split(' ')[0] || 'there'}`}
        subtitle="Book a visit or show your NFC card"
        rightIcon="log-out-outline"
        onRightPress={() => logout()}
      />

      {myBooking && (
        <>
          <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
            Your NFC card
          </Text>
          <Card accent="onsite">
            <View style={styles.cardHead}>
              <Ionicons name="card" size={28} color={colors.primary} />
              <Badge label={myBooking.status} status="pending" size="sm" />
            </View>
            <Text style={styles.code}>{myBooking.nfcCode}</Text>
            <Text variant="caption" color={colors.textSecondary}>
              Show this code at reception on arrival.
            </Text>
            <View style={styles.divider} />
            <Text variant="caption" color={colors.textMuted}>Host</Text>
            <Text variant="bodySemibold">
              {employees.find((e) => e.id === myBooking.hostId)?.name || '—'}
            </Text>
          </Card>
        </>
      )}

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Book a new visit
      </Text>
      <Card>
        <Input label="Full name" value={name} onChangeText={setName} icon="person-outline" />
        <Input label="Phone" value={phone} onChangeText={setPhone}
          icon="call-outline" keyboardType="phone-pad" />
        <Input label="Company (optional)" value={company} onChangeText={setCompany}
          icon="business-outline" />
        <Select label="Purpose" value={purpose} onChange={setPurpose}
          icon="briefcase-outline"
          options={visitPurposes.map((p) => ({ label: p, value: p }))} />
        <Select label="Who are you visiting?" value={hostId} onChange={setHostId}
          icon="people-outline" placeholder="Pick a host..."
          options={employees.map((e) => ({
            label: e.name, value: e.id,
            sublabel: `${e.department} - ${e.avaya}`,
          }))} />
      </Card>
      <Button label="Submit booking" icon="checkmark-circle-outline"
        onPress={onSubmit} style={{ marginTop: spacing.md }} />

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Need help?
      </Text>
      <Card>
        <Text variant="body">
          Call reception: +233 24 555 0100{'\n'}
          Email: reception@vra.com
        </Text>
      </Card>
    </Screen>
  );
}

const styles = StyleSheet.create({
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  cardHead: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    marginBottom: spacing.sm,
  },
  code: {
    fontFamily: fonts.displayExtra, fontSize: 32, color: colors.brand,
    letterSpacing: 2, marginBottom: spacing.xs,
  },
  divider: {
    height: 1, backgroundColor: colors.border,
    marginVertical: spacing.sm,
  },
});