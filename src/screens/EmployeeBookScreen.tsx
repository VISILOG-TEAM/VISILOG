import React from 'react';
import {
  Screen, Header, Text, BookMeetingForm,
} from '../components';
import { spacing } from '../theme/spacing';
import type { RootStackNavigation } from '../types/navigation';

interface EmployeeBookScreenProps {
  navigation: RootStackNavigation;
}

// EmployeeBookScreen — self-service booking for the signed-in user's
// own meeting (interview, planning session, client meeting, etc.).
// Shared by the Employee and Manager tab sets — an Administrator can
// invite anyone from the directory here too, not just their own team,
// and can book either a meeting room or an outside location.
export default function EmployeeBookScreen({ navigation }: EmployeeBookScreenProps) {
  return (
    <Screen>
      <Header
        eyebrow="Self-service"
        title="Book a meeting"
        subtitle="Reserve a room (or an outside spot) for your own meeting"
      />

      <BookMeetingForm onDone={() => navigation.navigate('Home')} />

      <Text variant="caption" color="#94A3B8" style={{ marginTop: spacing.sm, textAlign: 'center' }}>
        Need to reschedule? Edit the time from your appointment logs — a reason is required.
      </Text>
    </Screen>
  );
}
