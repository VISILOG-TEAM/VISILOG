import React, { useState } from 'react';
import { View, StyleSheet, Pressable, Modal } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import Card from './Card';
import { colors } from '../theme/colors';
import { spacing, radius } from '../theme/spacing';
import { meetingRooms } from '../data/mockData';

// A simplified "tour" map: a stylized floor-plan grid with tappable
// pins for reception + each meeting room. There's no real indoor
// positioning here (that needs BLE beacons / indoor GPS infrastructure
// this demo doesn't have) — tapping a pin shows a photo placeholder and
// short walking directions instead, giving the tour feel without it.
const LOCATIONS = [
  {
    id: 'reception', name: 'Reception', floor: 'Ground Floor', icon: 'desktop-outline',
    directions: ['Enter through the main doors.', 'Reception desk is straight ahead.'],
  },
  ...meetingRooms.map((r, i) => ({
    id: r.id,
    name: r.name,
    floor: r.floor,
    capacity: r.capacity,
    icon: 'business-outline',
    directions: [
      'From reception, take the lift or stairs up.',
      `Follow signage to ${r.floor}.`,
      `${r.name} is the ${i === 0 ? 'first' : i === 1 ? 'second' : 'third'} door on the left.`,
    ],
  })),
];

export default function CompanyMapSection() {
  const [selected, setSelected] = useState(null);

  return (
    <View>
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Find your way around
      </Text>
      <Card padded={false} style={styles.mapCard}>
        <View style={styles.floor}>
          {LOCATIONS.map((loc, i) => (
            <Pressable
              key={loc.id}
              onPress={() => setSelected(loc)}
              style={[styles.room, ROOM_LAYOUT[i % ROOM_LAYOUT.length]]}
            >
              <View style={styles.pin}>
                <Ionicons name={loc.icon} size={16} color={colors.brand} />
              </View>
              <Text variant="caption" color={colors.textPrimary} numberOfLines={1} style={styles.roomLabel}>
                {loc.name}
              </Text>
            </Pressable>
          ))}
        </View>
      </Card>

      <Modal visible={!!selected} transparent animationType="fade" onRequestClose={() => setSelected(null)}>
        <View style={styles.modalWrap}>
          <View style={styles.modalCard}>
            <View style={styles.modalPhoto}>
              <Ionicons name={selected?.icon || 'business-outline'} size={40} color={colors.primary} />
            </View>
            <Text variant="h3">{selected?.name}</Text>
            <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.sm }}>
              {selected?.floor}{selected?.capacity ? ` · Capacity ${selected.capacity}` : ''}
            </Text>
            {selected?.directions.map((step, i) => (
              <View key={i} style={styles.stepRow}>
                <View style={styles.stepNum}>
                  <Text variant="caption" color={colors.textInverse}>{i + 1}</Text>
                </View>
                <Text variant="bodyMd" style={{ flex: 1 }}>{step}</Text>
              </View>
            ))}
            <Pressable onPress={() => setSelected(null)} style={styles.closeBtn}>
              <Text variant="bodySemibold" color={colors.textInverse}>Got it</Text>
            </Pressable>
          </View>
        </View>
      </Modal>
    </View>
  );
}

// Simple 2x2-ish layout so the "floor" feels laid out rather than a
// plain list, without needing a real building diagram.
const ROOM_LAYOUT = [
  { top: 12, left: 12 },
  { top: 12, right: 12 },
  { bottom: 12, left: 12 },
  { bottom: 12, right: 12 },
];

const styles = StyleSheet.create({
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  mapCard: { overflow: 'hidden' },
  floor: {
    height: 200,
    backgroundColor: colors.surfaceAlt,
    position: 'relative',
  },
  room: {
    position: 'absolute',
    width: 120,
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: colors.border,
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.xs,
  },
  pin: {
    width: 30, height: 30, borderRadius: 15,
    backgroundColor: colors.primarySurface,
    alignItems: 'center', justifyContent: 'center',
    marginBottom: 4,
  },
  roomLabel: { textAlign: 'center' },

  modalWrap: {
    flex: 1, backgroundColor: 'rgba(10,42,29,0.55)',
    alignItems: 'center', justifyContent: 'center', padding: spacing.lg,
  },
  modalCard: {
    width: '100%', maxWidth: 360,
    backgroundColor: colors.surface,
    borderRadius: radius.lg,
    padding: spacing.lg,
  },
  modalPhoto: {
    height: 80, borderRadius: radius.md,
    backgroundColor: colors.primarySurface,
    alignItems: 'center', justifyContent: 'center',
    marginBottom: spacing.sm,
  },
  stepRow: { flexDirection: 'row', alignItems: 'flex-start', marginTop: spacing.xs, gap: 8 },
  stepNum: {
    width: 20, height: 20, borderRadius: 10,
    backgroundColor: colors.brand,
    alignItems: 'center', justifyContent: 'center',
    marginTop: 2,
  },
  closeBtn: {
    marginTop: spacing.md, height: 44, borderRadius: radius.md,
    backgroundColor: colors.brand,
    alignItems: 'center', justifyContent: 'center',
  },
});
