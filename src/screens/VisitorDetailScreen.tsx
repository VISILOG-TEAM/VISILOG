import React, { useState } from 'react';
import { View, StyleSheet, Alert, Pressable, Linking } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, Button, Input, Avatar,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtTime, fmtDate, fmtDuration } from '../data/format';
import { ApiError } from '../api/client';
import type { RootStackScreenProps } from '../types/navigation';
import type { IoniconName } from '../types';

// VisitorDetailScreen — the full record for one visitor.
// Reachable by tapping any row in the Visitors list. Shows:
//   - Identity block (avatar, name, badge ID, status)
//   - Visit details (host, purpose, company, phone)
//   - Timing (check-in, check-out, duration)
//   - Notes (editable)
//   - Check-out action (when on-site)
export default function VisitorDetailScreen({ route, navigation }: RootStackScreenProps<'VisitorDetail'>) {
  const { visitorId } = route.params;
  const { visitors, checkOutVisitor, employeeById } = useData();
  const visitor = visitors.find((v) => v.id === visitorId);

  const [note, setNote] = useState('');

  if (!visitor) {
    return (
      <Screen>
        <Header title="Visitor not found" rightIcon="close" onRightPress={() => navigation.goBack()} />
        <Text variant="body" color={colors.textSecondary}>
          This record may have been removed. Go back and try again.
        </Text>
      </Screen>
    );
  }

  const host = employeeById(visitor.hostId);
  const isOnsite = visitor.status === 'onsite';

  const onCheckOut = () => {
    Alert.alert(
      'Check out visitor?',
      `${visitor.fullName} will be marked as departed.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Check out',
          style: 'destructive',
          onPress: async () => {
            try {
              await checkOutVisitor(visitor.id, note);
              navigation.goBack();
            } catch (err) {
              Alert.alert('Could not check out', err instanceof ApiError ? err.message : 'Something went wrong.');
            }
          },
        },
      ]
    );
  };

  return (
    <Screen>
      <Header
        title="Visit details"
        subtitle={visitor.badgeId}
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      {/* Identity card */}
      <Card accent={isOnsite ? 'onsite' : 'neutral'}>
        <View style={styles.identityRow}>
          <Avatar name={visitor.fullName} size={56} />
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="h2" numberOfLines={1}>{visitor.fullName}</Text>
            <Text variant="caption" color={colors.textSecondary}>
              {visitor.company || 'No company on file'}
            </Text>
          </View>
          <Badge
            label={isOnsite ? 'On-site' : 'Completed'}
            status={isOnsite ? 'onsite' : 'neutral'}
          />
        </View>
      </Card>

      {/* Quick contact actions */}
      <View style={styles.actionsRow}>
        <ActionPill icon="call" label="Call"
          onPress={() => Linking.openURL(`tel:${visitor.phone}`)} />
        <ActionPill icon="chatbubble-ellipses" label="Message"
          onPress={() => Linking.openURL(`sms:${visitor.phone}`)} />
        <ActionPill icon="mail" label="Email"
          onPress={() => Alert.alert('No email on file', 'This visitor record has no email address.')} />
      </View>

      {/* Visit details */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>Visit details</Text>
      <Card>
        <DetailRow icon="people-outline" label="Host" value={host?.name || 'Not assigned'}
          sub={host ? host.department : undefined} />
        <Divider />
        <DetailRow icon="briefcase-outline" label="Purpose" value={visitor.purpose} />
        <Divider />
        <DetailRow icon="call-outline" label="Phone" value={visitor.phone} />
        <Divider />
        <DetailRow icon="card-outline" label="Badge ID" value={visitor.badgeId} />
      </Card>

      {/* Timing */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>Timing</Text>
      <Card>
        <DetailRow icon="log-in-outline" label="Checked in"
          value={fmtTime(visitor.checkInAt)} sub={fmtDate(visitor.checkInAt)} />
        <Divider />
        <DetailRow icon="log-out-outline" label="Checked out"
          value={visitor.checkOutAt ? fmtTime(visitor.checkOutAt) : 'Still on-site'}
          sub={visitor.checkOutAt ? fmtDate(visitor.checkOutAt) : undefined} />
        <Divider />
        <DetailRow icon="hourglass-outline" label="Duration"
          value={fmtDuration(visitor.checkInAt, visitor.checkOutAt)} />
      </Card>

      {/* Notes */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>Notes</Text>
      {isOnsite ? (
        <Input
          placeholder="Check-out note (optional)"
          value={note}
          onChangeText={setNote}
          multiline
        />
      ) : (
        <Card>
          <Text variant="body" color={visitor.notes ? colors.textPrimary : colors.textMuted}>
            {visitor.notes || 'No notes were recorded for this visit.'}
          </Text>
        </Card>
      )}

      {isOnsite ? (
        <Button
          label="Check out visitor"
          icon="log-out-outline"
          variant="primary"
          onPress={onCheckOut}
          style={{ marginTop: spacing.md }}
        />
      ) : null}
    </Screen>
  );
}

// Small internal helpers

function DetailRow({
  icon, label, value, sub,
}: { icon: IoniconName; label: string; value: string; sub?: string }) {
  const { colors: themeColors } = useTheme();
  return (
    <View style={styles.detailRow}>
      <View style={styles.detailIcon}>
        <Ionicons name={icon} size={18} color={themeColors.brand} />
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="caption" color={colors.textSecondary}>{label}</Text>
        <Text variant="bodySemibold">{value}</Text>
        {sub ? (
          <Text variant="caption" color={colors.textMuted}>{sub}</Text>
        ) : null}
      </View>
    </View>
  );
}

function Divider() {
  return <View style={styles.divider} />;
}

function ActionPill({
  icon, label, onPress,
}: { icon: IoniconName; label: string; onPress: () => void }) {
  const { colors: themeColors } = useTheme();
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.pill, pressed && { opacity: 0.85 }]}>
      <Ionicons name={icon} size={18} color={themeColors.primary} />
      <Text variant="bodyMd" color={themeColors.brand} style={{ marginLeft: 6 }}>
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  identityRow: { flexDirection: 'row', alignItems: 'center' },
  actionsRow: { flexDirection: 'row', gap: spacing.xs, marginTop: spacing.sm },
  pill: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing.sm,
    backgroundColor: colors.surface,
    borderRadius: radius.pill,
    borderWidth: 1,
    borderColor: colors.border,
  },
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  detailRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: spacing.xs },
  detailIcon: {
    width: 32, height: 32, borderRadius: 10,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center', justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, backgroundColor: colors.border, marginVertical: spacing.xs, marginLeft: 32 + spacing.sm },
});
