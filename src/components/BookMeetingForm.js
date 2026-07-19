import React, { useRef, useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import Card from './Card';
import Button from './Button';
import Input from './Input';
import Select from './Select';
import MultiSelect from './MultiSelect';
import Segmented from './Segmented';
import { spacing } from '../theme/spacing';
import { useData } from '../context/DataContext';

// BookMeetingForm — self-service internal meeting booking. Shared by
// Employee, Manager (EmployeeBookScreen) and Receptionist (the
// "Internal meeting" pane on VisitorBookingScreen), so an
// Administrator or anyone else can invite whoever they need — not
// just their own direct reports — and can book either one of the
// company's meeting rooms or an outside location (a client's office,
// a restaurant, etc.) for meetings that don't happen on-site. The
// organiser is derived server-side from the signed-in user's own
// employee record — see RoomBookingController.
export default function BookMeetingForm({ onDone }) {
  const { employees, meetingRooms, bookRoom } = useData();

  const [title, setTitle] = useState('');
  const [locationType, setLocationType] = useState('room'); // 'room' | 'outside'
  const [roomId, setRoomId] = useState(null);
  const [outsideLocation, setOutsideLocation] = useState('');
  const [attendeeIds, setAttendeeIds] = useState([]);
  const [externalGuests, setExternalGuests] = useState('');
  const [date, setDate] = useState(formatDate(new Date()));
  const [startTime, setStartTime] = useState('10:00');
  const [endTime, setEndTime] = useState('11:00');
  const [submitting, setSubmitting] = useState(false);
  const submittingRef = useRef(false);

  const onSubmit = async () => {
    if (submittingRef.current) return;
    const hasPlace = locationType === 'room' ? !!roomId : !!outsideLocation.trim();
    if (!title.trim() || !hasPlace) {
      Alert.alert('Almost there', locationType === 'room'
        ? 'Give the meeting a title and pick a room.'
        : 'Give the meeting a title and enter a location.');
      return;
    }
    submittingRef.current = true;
    setSubmitting(true);
    try {
      await bookRoom({
        title: title.trim(),
        roomId: locationType === 'room' ? roomId : null,
        location: locationType === 'outside' ? outsideLocation.trim() : '',
        startTime: toInstant(date, startTime),
        endTime: toInstant(date, endTime),
        participantIds: attendeeIds,
        externalGuests: externalGuests.trim(),
      });
      Alert.alert('Booked', `${title} is on the calendar.`, [
        { text: 'Done', onPress: onDone },
      ]);
    } catch (err) {
      Alert.alert('Could not book meeting', err.message);
    } finally {
      submittingRef.current = false;
      setSubmitting(false);
    }
  };

  return (
    <>
      <Card>
        <Input
          label="Meeting title"
          value={title}
          onChangeText={setTitle}
          placeholder="e.g. Candidate interview"
          icon="briefcase-outline"
        />

        <Segmented
          value={locationType}
          onChange={(v) => { setLocationType(v); setRoomId(null); setOutsideLocation(''); }}
          options={[
            { label: 'Meeting room', value: 'room' },
            { label: 'Outside location', value: 'outside' },
          ]}
          style={{ marginBottom: spacing.md }}
        />

        {locationType === 'room' ? (
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
        ) : (
          <Input
            label="Location"
            value={outsideLocation}
            onChangeText={setOutsideLocation}
            placeholder="e.g. Client's office, Accra Mall"
            icon="location-outline"
          />
        )}

        <MultiSelect
          label="Invite staff (optional)"
          placeholder="Anyone from the staff directory..."
          values={attendeeIds}
          onChange={setAttendeeIds}
          icon="people-outline"
          options={employees.map((e) => ({
            label: e.name, value: e.id, sublabel: e.department,
          }))}
        />

        <Input
          label="Outside guests (optional)"
          value={externalGuests}
          onChangeText={setExternalGuests}
          placeholder="e.g. Kwame Mensah (client), Ama Boateng"
          icon="person-add-outline"
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
        label="Book meeting"
        icon="checkmark-circle-outline"
        onPress={onSubmit}
        loading={submitting}
        style={{ marginTop: spacing.md }}
      />
    </>
  );
}

function formatDate(d) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

// The backend expects a full ISO instant (with seconds + timezone);
// "YYYY-MM-DDTHH:MM" alone isn't parseable as one and was silently
// failing every booking with a generic "Something went wrong" error.
// Routing through a real Date and toISOString() also correctly
// converts from the device's local time to UTC.
function toInstant(dateStr, timeStr) {
  return new Date(`${dateStr}T${timeStr}:00`).toISOString();
}

const styles = StyleSheet.create({
  timeRow: { flexDirection: 'row' },
});
