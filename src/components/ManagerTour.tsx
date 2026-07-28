import React, { useEffect, useState } from 'react';
import { View, Modal, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import Button from './Button';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { hasSeenManagerTour, markManagerTourSeen } from '../api/managerTour';
import type { IoniconName } from '../types';

// First-run orientation for a newly registered Administrator. A company
// that has just signed up has no staff, no rooms and no office location
// yet, so the Manager home screen is almost entirely empty -- and
// nothing on it says which of those to do first, or that a company
// needs all three before anyone can actually clock in.
//
// Deliberately a sequence of cards over a dimmed screen rather than a
// true spotlight cut out around each real button: highlighting live
// elements means measuring their on-screen position at runtime, which
// breaks quietly whenever a layout, a tab order or a screen size
// changes -- and it would have to work across two navigators, since
// Company Setup and Billing aren't even on this screen. Naming where
// to go survives all of that, and is what the manager actually needs.
//
// Shown once per Administrator (see api/managerTour.ts) and skippable
// at any point.

interface TourStop {
  icon: IoniconName;
  title: string;
  body: string;
}

const STOPS: TourStop[] = [
  {
    icon: 'business-outline',
    title: 'Start in Company Setup',
    body:
      "Settings > Company Setup is where you set your company's name and logo, and mark your office location on the map. Staff can only clock in when they're physically inside that location, so this comes first.",
  },
  {
    icon: 'people-outline',
    title: 'Add your staff',
    body:
      'Company Setup > Staff roster is the list of everyone who works here. When someone signs up with your company code, VisiLog matches their work email against this list to decide whether they are a receptionist, an employee, a manager -- or a visitor. Anyone not on it becomes a visitor.',
  },
  {
    icon: 'easel-outline',
    title: 'Add your meeting rooms',
    body:
      'Company Setup > Meeting rooms fills the room picker your staff use when booking meetings. Until you add at least one, that picker has nothing in it.',
  },
  {
    icon: 'card-outline',
    title: 'Check your subscription',
    body:
      'Settings > Billing shows your plan, how many staff seats it covers and when it renews. Your plan also decides which features are switched on, so it is worth a look before you invite everybody.',
  },
  {
    icon: 'share-social-outline',
    title: 'Then share your company code',
    body:
      "Your company code is on the Company Setup screen. Send it to your staff and visitors -- it's the only thing they need to sign up and find your organisation.",
  },
];

export default function ManagerTour() {
  const { colors } = useTheme();
  const { user } = useAuth();
  const [visible, setVisible] = useState(false);
  const [index, setIndex] = useState(0);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      if (!user || user.role !== 'manager') return;
      const seen = await hasSeenManagerTour(user.id);
      if (!cancelled && !seen) setVisible(true);
    })();
    return () => {
      cancelled = true;
    };
  }, [user]);

  // Marked seen on *any* exit, including Skip: someone who dismissed it
  // chose not to read it, and showing it again next launch would read
  // as the app not listening rather than as a helpful reminder.
  const close = async () => {
    setVisible(false);
    if (user) await markManagerTourSeen(user.id);
  };

  const stop = STOPS[index];
  const isLast = index === STOPS.length - 1;

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={close}>
      <View style={styles.backdrop}>
        <View style={[styles.card, { backgroundColor: colors.surface }]}>
          <View style={[styles.iconRing, { backgroundColor: colors.primarySurface }]}>
            <Ionicons name={stop.icon} size={24} color={colors.primary} />
          </View>

          <Text variant="h3" align="center" style={{ marginBottom: spacing.xs }}>
            {stop.title}
          </Text>
          <Text variant="body" color={colors.textSecondary} align="center">
            {stop.body}
          </Text>

          <View style={styles.dots}>
            {STOPS.map((s, i) => (
              <View
                key={s.title}
                style={[
                  styles.dot,
                  { backgroundColor: i === index ? colors.primary : colors.border },
                ]}
              />
            ))}
          </View>

          <View style={styles.row}>
            {index > 0 ? (
              <Button
                label="Back"
                variant="secondary"
                onPress={() => setIndex((i) => i - 1)}
                style={{ flex: 1, marginRight: spacing.xs }}
              />
            ) : null}
            <Button
              label={isLast ? "Got it" : 'Next'}
              onPress={() => (isLast ? close() : setIndex((i) => i + 1))}
              style={{ flex: 1, marginLeft: index > 0 ? spacing.xs : 0 }}
            />
          </View>

          {!isLast ? (
            <Pressable onPress={close} style={styles.skip} hitSlop={8}>
              <Text variant="caption" color={colors.textMuted}>
                Skip this
              </Text>
            </Pressable>
          ) : null}
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(14, 27, 44, 0.6)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.lg,
  },
  card: {
    width: '100%',
    maxWidth: 420,
    borderRadius: radius.xl,
    padding: spacing.xl,
    alignItems: 'center',
  },
  iconRing: {
    width: 52,
    height: 52,
    borderRadius: 26,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.md,
  },
  dots: { flexDirection: 'row', marginVertical: spacing.lg },
  dot: { width: 7, height: 7, borderRadius: 4, marginHorizontal: 3 },
  row: { flexDirection: 'row', alignSelf: 'stretch' },
  skip: { marginTop: spacing.md, padding: 4 },
});
