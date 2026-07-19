import React, { useState } from 'react';
import { View, Image, FlatList, StyleSheet, Alert, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import {
  Screen, Header, Text, Card, Button, Input, EmptyState,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';

// MeetingRoomsScreen — Company Setup > meeting rooms (manager only).
// The rooms managed here are exactly what BookMeetingForm and
// AppointmentsScreen's "Meeting Rooms" tab draw from.
export default function MeetingRoomsScreen({ navigation }) {
  const { colors: themeColors } = useTheme();
  const { meetingRooms, addMeetingRoom, removeMeetingRoom } = useData();

  const [name, setName] = useState('');
  const [capacity, setCapacity] = useState('');
  const [floor, setFloor] = useState('');
  const [photoUrl, setPhotoUrl] = useState('');
  const [pickingPhoto, setPickingPhoto] = useState(false);
  const [adding, setAdding] = useState(false);

  const onPickPhoto = async () => {
    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) {
      Alert.alert('Permission needed', 'Allow photo library access to add a room photo.');
      return;
    }
    setPickingPhoto(true);
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ['images'],
        allowsEditing: true,
        aspect: [4, 3],
        quality: 0.6,
        base64: true,
      });
      if (result.canceled) return;
      const asset = result.assets[0];
      if (!asset.base64) {
        Alert.alert('Could not read image', 'Please try a different photo.');
        return;
      }
      setPhotoUrl(`data:${asset.mimeType || 'image/jpeg'};base64,${asset.base64}`);
    } finally {
      setPickingPhoto(false);
    }
  };

  const onAdd = async () => {
    if (!name.trim()) {
      Alert.alert('Almost there', 'Give the room a name.');
      return;
    }
    setAdding(true);
    try {
      await addMeetingRoom({ name: name.trim(), capacity, floor: floor.trim(), photoUrl: photoUrl || null });
      setName(''); setCapacity(''); setFloor(''); setPhotoUrl('');
    } catch (err) {
      Alert.alert('Could not add room', err.message);
    } finally {
      setAdding(false);
    }
  };

  const onRemove = (room) => {
    Alert.alert('Remove room?', `${room.name} will no longer be bookable.`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Remove', style: 'destructive',
        onPress: () => removeMeetingRoom(room.id).catch((err) => Alert.alert('Could not remove room', err.message)),
      },
    ]);
  };

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Meeting rooms"
          subtitle="Bookable spaces across the office"
          rightIcon="close"
          onRightPress={() => navigation.goBack()}
        />
        <Card>
          <Input label="Room name" value={name} onChangeText={setName}
            placeholder="e.g. Boardroom A" icon="business-outline" />
          <View style={styles.row}>
            <View style={{ flex: 1 }}>
              <Input label="Capacity" value={capacity} onChangeText={setCapacity}
                placeholder="e.g. 12" icon="people-outline" keyboardType="number-pad" />
            </View>
            <View style={{ width: spacing.sm }} />
            <View style={{ flex: 1 }}>
              <Input label="Floor" value={floor} onChangeText={setFloor}
                placeholder="e.g. 3rd Floor" icon="layers-outline" />
            </View>
          </View>
          <Pressable onPress={onPickPhoto} disabled={pickingPhoto} style={styles.photoRow}>
            <View style={[styles.photoPreview, { borderColor: colors.border }]}>
              {photoUrl ? (
                <Image source={{ uri: photoUrl }} style={styles.photoImage} resizeMode="cover" />
              ) : (
                <Ionicons name="camera-outline" size={20} color={colors.textMuted} />
              )}
            </View>
            <Text variant="bodySemibold" color={themeColors.brand} style={{ marginLeft: spacing.sm }}>
              {pickingPhoto ? 'Opening photos…' : photoUrl ? 'Change photo' : 'Add a room photo (optional)'}
            </Text>
          </Pressable>
          <Button label={adding ? 'Adding…' : 'Add room'} onPress={onAdd} disabled={adding} />
        </Card>
      </View>

      <FlatList
        data={meetingRooms}
        keyExtractor={(r) => r.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState icon="business-outline" title="No rooms yet" message="Add your first meeting room above." />
        }
        renderItem={({ item }) => (
          <Card style={{ marginHorizontal: spacing.md }}>
            <View style={styles.roomRow}>
              <View style={[styles.roomIcon, { backgroundColor: themeColors.primarySurface }]}>
                {item.photoUrl ? (
                  <Image source={{ uri: item.photoUrl }} style={styles.roomIconImage} resizeMode="cover" />
                ) : (
                  <Ionicons name="business" size={20} color={themeColors.primary} />
                )}
              </View>
              <View style={{ flex: 1, marginLeft: spacing.sm }}>
                <Text variant="bodySemibold">{item.name}</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {item.floor || 'No floor set'}{item.capacity ? ` · Capacity ${item.capacity}` : ''}
                </Text>
              </View>
              <Pressable onPress={() => onRemove(item)} hitSlop={8}>
                <Ionicons name="trash-outline" size={20} color={colors.status.rejected.solid} />
              </Pressable>
            </View>
          </Card>
        )}
      />
    </Screen>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  row: { flexDirection: 'row' },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  roomRow: { flexDirection: 'row', alignItems: 'center' },
  roomIcon: {
    width: 44, height: 44, borderRadius: 12,
    alignItems: 'center', justifyContent: 'center',
    overflow: 'hidden',
  },
  roomIconImage: { width: '100%', height: '100%' },
  photoRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.md },
  photoPreview: {
    width: 44, height: 44, borderRadius: radius.md,
    borderWidth: 1, alignItems: 'center', justifyContent: 'center',
    overflow: 'hidden', backgroundColor: colors.surfaceAlt,
  },
  photoImage: { width: '100%', height: '100%' },
});
