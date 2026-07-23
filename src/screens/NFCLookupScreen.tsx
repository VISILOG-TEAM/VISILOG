import React, { useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Button, Input, Badge, Avatar } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useData } from '../context/DataContext';
import { fmtDateTime } from '../data/format';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type { Appointment, IoniconName } from '../types';

interface NFCLookupScreenProps {
  navigation: RootStackNavigation;
}

// Receptionist enters a visitor's NFC code, sees their full booking.
export default function NFCLookupScreen({ navigation }: NFCLookupScreenProps) {
  const { colors } = useTheme();
  const { findAppointmentByCode, admitAppointment, employeeById } = useData();
  const [code, setCode] = useState('');
  const [found, setFound] = useState<Appointment | null>(null);

  const lookup = async () => {
    const a = await findAppointmentByCode(code);
    if (!a) {
      Alert.alert('Not found', `No booking matches code "${code}".`);
      setFound(null);
      return;
    }
    setFound(a);
  };

  return (
    <Screen>
      <Header
        title="NFC lookup"
        subtitle="Enter the visitor's code to view their booking"
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      <Card>
        <Input
          label="Visitor NFC code"
          value={code}
          onChangeText={setCode}
          placeholder="VC-XXXX-XXXX"
          icon="card-outline"
          autoCapitalize="characters"
        />
        <Button label="Look up" icon="search" onPress={lookup} />
      </Card>

      {found && (
        <Card accent="success" style={{ marginTop: spacing.md }}>
          <View style={styles.head}>
            <Avatar name={found.visitorName} size={48} />
            <View style={{ flex: 1, marginLeft: spacing.sm }}>
              <Text variant="h3">{found.visitorName}</Text>
              <Text variant="caption" color={colors.textSecondary}>
                {found.visitorCompany || 'Visitor'}
              </Text>
            </View>
            <Badge label={found.status} status="success" size="sm" />
          </View>

          <Row icon="card-outline" label="NFC code" value={found.nfcCode || 'Not yet issued'} />
          <Row icon="call-outline" label="Phone" value={found.visitorPhone} />
          <Row icon="briefcase-outline" label="Purpose" value={found.purpose} />
          <Row
            icon="people-outline"
            label="Host"
            value={employeeById(found.hostId)?.name || '--'}
          />
          <Row icon="time-outline" label="Scheduled" value={fmtDateTime(found.scheduledAt)} />

          {found.status === 'pending' && (
            <Button
              label="Admit & check in"
              icon="checkmark-circle-outline"
              onPress={async () => {
                try {
                  const v = await admitAppointment(found);
                  Alert.alert('Admitted', `${v.fullName} (${v.badgeId}) is on-site.`);
                  setFound(null);
                  setCode('');
                } catch (err) {
                  Alert.alert(
                    'Could not admit visitor',
                    err instanceof ApiError ? err.message : 'Something went wrong.',
                  );
                }
              }}
              style={{ marginTop: spacing.sm }}
            />
          )}
        </Card>
      )}
    </Screen>
  );
}

function Row({ icon, label, value }: { icon: IoniconName; label: string; value: string }) {
  const { colors } = useTheme();
  return (
    <View style={styles.row}>
      <Ionicons name={icon} size={16} color={colors.brand} style={{ width: 24 }} />
      <Text variant="caption" color={colors.textSecondary} style={{ width: 80 }}>
        {label}
      </Text>
      <Text variant="bodySemibold" style={{ flex: 1 }}>
        {value}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  head: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.sm },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: 6 },
});