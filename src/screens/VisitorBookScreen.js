import React, { useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Button, Input, Select,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { visitPurposes } from '../data/mockData';

// VisitorBookScreen — the visitor's own "Book" tab. Same fields as the
// form that used to live on VisitorHomeScreen, given a more formal,
// sectioned treatment (distinct headers per group) since it's now a
// dedicated screen rather than embedded on the dashboard.
export default function VisitorBookScreen({ navigation }) {
  const { colors: themeColors } = useTheme();
  const { user } = useAuth();
  const { employees, bookVisit } = useData();

  const [name, setName] = useState(user.name || '');
  const [phone, setPhone] = useState('');
  const [company, setCompany] = useState('');
  const [purpose, setPurpose] = useState('Official Business');
  const [otherPurpose, setOtherPurpose] = useState('');
  const [hostId, setHostId] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  const onSubmit = async () => {
    if (submitting) {
      Alert.alert('Already booking', 'Your booking is already being submitted.');
      return;
    }
    if (!name.trim() || !phone.trim() || !hostId) {
      Alert.alert('Almost there', 'Name, phone and host are required.');
      return;
    }
    if (purpose === 'Other' && !otherPurpose.trim()) {
      Alert.alert('Almost there', 'Please describe the purpose of your visit.');
      return;
    }
    setSubmitting(true);
    try {
      const a = await bookVisit({
        visitorName: name, visitorPhone: phone, visitorCompany: company,
        purpose: purpose === 'Other' ? otherPurpose.trim() : purpose, hostId,
      });
      Alert.alert('Booked', `Your visit code is ${a.nfcCode}. Show it at reception.`, [
        { text: 'Done', onPress: () => navigation.navigate('Home') },
      ]);
    } catch (err) {
      Alert.alert('Could not book visit', err.message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Screen>
      <Header
        eyebrow="Pre-registration"
        title="Book a visit"
        subtitle="Complete each section below to request an appointment"
      />

      <Text variant="label" color={themeColors.brand} style={styles.sectionLabel}>
        1 · Your details
      </Text>
      <Card>
        <Input label="Full name" value={name} onChangeText={setName} icon="person-outline" />
        <Input label="Phone" value={phone} onChangeText={setPhone}
          icon="call-outline" keyboardType="phone-pad" />
        <Input label="Company (optional)" value={company} onChangeText={setCompany}
          icon="business-outline" />
      </Card>

      <Text variant="label" color={themeColors.brand} style={styles.sectionLabel}>
        2 · Visit details
      </Text>
      <Card>
        <Select label="Purpose" value={purpose} onChange={setPurpose}
          icon="briefcase-outline"
          options={visitPurposes.map((p) => ({ label: p, value: p }))} />
        {purpose === 'Other' ? (
          <Input label="Please specify" value={otherPurpose} onChangeText={setOtherPurpose}
            placeholder="What's the purpose of your visit?" icon="create-outline" />
        ) : null}
        <Select label="Who are you visiting?" value={hostId} onChange={setHostId}
          icon="people-outline" placeholder="Pick a host..."
          options={employees.map((e) => ({
            label: e.name, value: e.id,
            sublabel: e.department,
          }))} />
      </Card>

      <View style={[styles.notice, { backgroundColor: themeColors.primarySurface }]}>
        <Ionicons name="information-circle" size={18} color={themeColors.primary} />
        <Text variant="caption" color={themeColors.brand} style={{ marginLeft: 8, flex: 1 }}>
          You’ll receive an NFC pass code once submitted — show it at reception on arrival.
        </Text>
      </View>

      <Button label="Submit booking" icon="checkmark-circle-outline"
        onPress={onSubmit} loading={submitting} style={{ marginTop: spacing.sm }} />
    </Screen>
  );
}

const styles = StyleSheet.create({
  sectionLabel: { marginTop: spacing.lg, marginBottom: spacing.xs, textTransform: 'uppercase' },
  notice: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    borderRadius: radius.md,
    padding: spacing.sm,
    marginTop: spacing.md,
  },
});
