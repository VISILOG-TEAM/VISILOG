import React from 'react';
import { Screen, Header, Text, BookMeetingForm } from '../components';
import { spacing } from '../theme/spacing';
import type { RootStackNavigation } from '../types/navigation';

interface EmployeeBookScreenProps {
  navigation: RootStackNavigation;
}

// EmployeeBookScreen -- self-service booking for the signed-in user's
// own meeting (interview, planning session, client meeting, etc.).
// Shared by the Employee and Manager tab sets -- an Administrator can
// invite anyone from the directory here too, not just their own team,
// and can book either a meeting room or an outside location.
export default function EmployeeBookScreen({ navigation }: EmployeeBookScreenProps) {
  return (
    <Screen>
      {/* No subtitle and no footnote: the four-step form below now says
          what it does as you go (the location toggle offers "Meeting
          room" or "Outside location" on step one), and the reschedule
          hint was advice about a different screen entirely -- it just
          pushed the form further down the page. */}
      <Header eyebrow="Self-service" title="Book a meeting" />

      <BookMeetingForm onDone={() => navigation.navigate('Home')} />
    </Screen>
  );
}
