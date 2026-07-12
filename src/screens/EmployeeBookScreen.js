import React, { useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import {
  Screen, Header, Text, Card, Button, Input, Select,
} from '../components';
import { spacing } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { meetingRooms } from '../data/mockData';

// EmployeeBookScreen — self-service booking for the employee's own
// meeting/interview (e.g. an interview slot), reserving a room and
// time window. Shared by the Employee and Manager tab sets.
export default function EmployeeBookScreen({ navigation }) {
  const { user } = useAuth();
  const { bookRoom } = useData();

  const [title, setTitle] = useState('');
  const [roomId, setRoomId] = useState(null);
  const [date, setDate] = useState(formatDate(new Date()));
  const [startTime, setStartTime] = useState('10:00');
  const [endTime, setEndTime] = useState('11:00');

  const onSubmit = () => {
    if (!title.trim() || !roomId) {
      Alert.alert('Almost there', 'Give the meeting a title and pick a room.');
      return;
    }
    bookRoom({
      title: title.trim(),
      roomId,
      organiserId: user.employeeId || user.id,
      startTime: `${date}T${startTime}`,
      endTime: `${date}T${endTime}`,
    });
    Alert.alert('Booked', `${title} is on the calendar.`, [
      { text: 'Done', onPress: () => navigation.navigate('Home') },
    ]);
  };

  return (
    <Screen>
      <Header
        eyebrow="Self-service"
        title="Book a meeting"
        subtitle="Reserve a room for your own meeting or interview"
      />

      <Card>
        <Input
          label="Meeting title"
          value={title}
          onChangeText={setTitle}
          placeholder="e.g. Candidate interview"
          icon="briefcase-outline"
        />
        <Select
          label="Room"
          placeholder="Pick a room..."
          value={roomId}
          onChange={setRoomId}
          icon="business-outline"
          options={meetingRooms.map((r) => ({
            label: r.name, value: r.id, sublabel: `${r.floor} · Capacity ${r.capacity}`,
          }))}
        />
        <Input
          label="Date"
          value={date}
          onChangeText={setDate}
          placeholder="YYYY-MM-DD"
          icon="calendar-outline"
        />
        <View style={styles.timeRow}>
          <View style={{ flex: 1 }}>
            <Input label="Start" value={startTime} onChangeText={setStartTime}
              placeholder="HH:MM" icon="time-outline" />
          </View>
          <View style={{ width: spacing.sm }} />
          <View style={{ flex: 1 }}>
            <Input label="End" value={endTime} onChangeText={setEndTime}
              placeholder="HH:MM" icon="time-outline" />
          </View>
        </View>
      </Card>

      <Button
        label="Book room"
        icon="checkmark-circle-outline"
        onPress={onSubmit}
        style={{ marginTop: spacing.md }}
      />

      <Text variant="caption" color="#94A3B8" style={{ marginTop: spacing.sm, textAlign: 'center' }}>
        Need to reschedule? Edit the time from your appointment logs — a reason is required.
      </Text>
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
  timeRow: { flexDirection: 'row' },
});
