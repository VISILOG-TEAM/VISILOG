import React, { useCallback, useState } from 'react';
import {
  View, FlatList, Pressable, StyleSheet, Modal, TextInput, KeyboardAvoidingView, Alert,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Button, EmptyState } from '../components';
import { colors as staticColors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtRelative } from '../data/format';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type { AppNotification, RoomBookingResponse } from '../types';

interface NotificationsScreenProps {
  navigation: RootStackNavigation;
}

// NotificationsScreen — in-app alerts (meeting invites, and an
// organiser being told someone declined). Reached from the bell icon
// on the Home header. There's no push/SMS delivery in this build, so
// this list (fetched on focus) is the only place these show up — see
// NotificationService on the backend.
export default function NotificationsScreen({ navigation }: NotificationsScreenProps) {
  const { user } = useAuth();
  const {
    notifications, refreshNotifications, markNotificationRead, roomBookings, respondToMeeting,
  } = useData();
  const [refreshing, setRefreshing] = useState(false);
  const [declining, setDeclining] = useState<AppNotification | null>(null);

  useFocusEffect(
    useCallback(() => {
      refreshNotifications();
    }, [])
  );

  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshNotifications();
    } finally {
      setRefreshing(false);
    }
  };

  const sorted = [...notifications].sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
  );

  // A participant's own response row for the meeting a notification
  // points at — undefined once the organiser sees it (they don't get
  // a response row for their own meeting) or for non-invite types.
  const myResponseFor = (n: AppNotification): RoomBookingResponse | undefined => {
    if (n.type !== 'meeting_invite' || !n.relatedId || !user?.employeeId) return undefined;
    const booking = roomBookings.find((b) => b.id === n.relatedId);
    return booking?.responses.find((r) => r.employeeId === user.employeeId);
  };

  const onAcknowledge = async (n: AppNotification) => {
    if (!n.relatedId) return;
    try {
      await respondToMeeting(n.relatedId, 'acknowledged');
      markNotificationRead(n.id);
    } catch (err) {
      Alert.alert('Could not respond', err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  const onConfirmDecline = async (reason: string) => {
    if (!declining?.relatedId) return;
    try {
      await respondToMeeting(declining.relatedId, 'declined', reason);
      markNotificationRead(declining.id);
      setDeclining(null);
    } catch (err) {
      Alert.alert('Could not decline', err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Notifications"
          subtitle={sorted.length ? `${sorted.length} total` : undefined}
          onBackPress={() => navigation.goBack()}
        />
      </View>

      <FlatList
        data={sorted}
        keyExtractor={(n) => n.id}
        contentContainerStyle={styles.list}
        refreshing={refreshing}
        onRefresh={onRefresh}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="notifications-outline"
            title="No notifications yet"
            message="Meeting invites and other alerts will show up here."
          />
        }
        renderItem={({ item }) => (
          <NotificationRow
            notification={item}
            myResponse={myResponseFor(item)}
            onPress={() => markNotificationRead(item.id)}
            onAcknowledge={() => onAcknowledge(item)}
            onDecline={() => setDeclining(item)}
          />
        )}
      />

      <DeclineReasonModal
        visible={!!declining}
        onCancel={() => setDeclining(null)}
        onConfirm={onConfirmDecline}
      />
    </Screen>
  );
}

function NotificationRow({
  notification, myResponse, onPress, onAcknowledge, onDecline,
}: {
  notification: AppNotification;
  myResponse: RoomBookingResponse | undefined;
  onPress: () => void;
  onAcknowledge: () => void;
  onDecline: () => void;
}) {
  const { colors: themeColors } = useTheme();
  const canRespond = notification.type === 'meeting_invite' && myResponse?.status === 'pending';

  return (
    <Pressable onPress={onPress} disabled={notification.read}>
      <Card padded={false} style={{ marginHorizontal: spacing.md }}>
        <View style={styles.row}>
          <View style={[styles.iconWrap, { backgroundColor: themeColors.primarySurface }]}>
            <Ionicons
              name={notification.type === 'meeting_declined' ? 'close-circle-outline' : 'calendar-outline'}
              size={18}
              color={themeColors.primary}
            />
          </View>
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <View style={styles.rowTop}>
              <Text variant="bodySemibold" numberOfLines={1}>{notification.title}</Text>
              {!notification.read ? <View style={styles.unreadDot} /> : null}
            </View>
            <Text variant="body" color={staticColors.textSecondary}>{notification.body}</Text>
            <Text variant="caption" color={staticColors.textMuted} style={{ marginTop: 2 }}>
              {fmtRelative(notification.createdAt)}
            </Text>

            {canRespond ? (
              <View style={styles.actionRow}>
                <Button
                  label="Seen it"
                  icon="checkmark-circle-outline"
                  variant="secondary"
                  size="sm"
                  onPress={onAcknowledge}
                  style={{ flex: 1, marginRight: spacing.xs }}
                />
                <Button
                  label="Can't make it"
                  icon="close-circle-outline"
                  variant="secondary"
                  size="sm"
                  onPress={onDecline}
                  style={{ flex: 1, marginLeft: spacing.xs }}
                />
              </View>
            ) : myResponse?.status === 'acknowledged' ? (
              <View style={styles.respondedRow}>
                <Ionicons name="checkmark-circle" size={14} color={themeColors.primary} />
                <Text variant="caption" color={themeColors.primary} style={{ marginLeft: 4 }}>
                  You said you've seen this
                </Text>
              </View>
            ) : myResponse?.status === 'declined' ? (
              <View style={styles.respondedRow}>
                <Ionicons name="close-circle" size={14} color={staticColors.status.rejected.solid} />
                <Text variant="caption" color={staticColors.status.rejected.solid} style={{ marginLeft: 4 }}>
                  You declined
                </Text>
              </View>
            ) : null}
          </View>
        </View>
      </Card>
    </Pressable>
  );
}

// A reason is required to decline (per RoomBookingService.respond),
// and Android has no built-in Alert.prompt, so this is a small custom
// modal — same pattern as RescheduleModal's reason field.
function DeclineReasonModal({
  visible, onCancel, onConfirm,
}: { visible: boolean; onCancel: () => void; onConfirm: (reason: string) => void }) {
  const { colors } = useTheme();
  const [reason, setReason] = useState('');

  const onSubmit = () => {
    if (!reason.trim()) {
      Alert.alert('Almost there', "Let the organiser know why you can't make it.");
      return;
    }
    onConfirm(reason.trim());
    setReason('');
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onCancel}>
      <KeyboardAvoidingView style={modalStyles.wrap} behavior="padding">
        <View style={modalStyles.card}>
          <Text variant="h3">Can't make it?</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            Let the organiser know why — they'll see this right away.
          </Text>
          <TextInput
            value={reason}
            onChangeText={setReason}
            placeholder="e.g. I have another commitment that day"
            placeholderTextColor={staticColors.textMuted}
            style={modalStyles.input}
            multiline
          />
          <View style={modalStyles.row}>
            <Pressable onPress={onCancel} style={[modalStyles.btn, modalStyles.btnGhost]}>
              <Text variant="bodySemibold" color={colors.textSecondary}>Cancel</Text>
            </Pressable>
            <Pressable onPress={onSubmit} style={[modalStyles.btn, { backgroundColor: colors.brand }]}>
              <Text variant="bodySemibold" color={colors.textInverse}>Send</Text>
            </Pressable>
          </View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  row: { flexDirection: 'row', alignItems: 'flex-start', padding: spacing.md },
  iconWrap: {
    width: 40, height: 40, borderRadius: radius.md,
    alignItems: 'center', justifyContent: 'center',
  },
  rowTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: 8 },
  unreadDot: {
    width: 8, height: 8, borderRadius: 4, backgroundColor: staticColors.palette.red600,
  },
  actionRow: { flexDirection: 'row', marginTop: spacing.sm },
  respondedRow: { flexDirection: 'row', alignItems: 'center', marginTop: spacing.xs },
});

const modalStyles = StyleSheet.create({
  wrap: {
    flex: 1, backgroundColor: 'rgba(10,42,29,0.55)',
    alignItems: 'center', justifyContent: 'center', padding: spacing.lg,
  },
  card: {
    width: '100%', maxWidth: 360,
    backgroundColor: staticColors.surface,
    borderRadius: radius.lg,
    padding: spacing.lg,
  },
  input: {
    borderWidth: 1, borderColor: staticColors.border, borderRadius: radius.md,
    paddingHorizontal: spacing.sm, paddingVertical: 10, minHeight: 80, textAlignVertical: 'top',
    fontFamily: fonts.regular, fontSize: 14, color: staticColors.textPrimary,
  },
  row: { flexDirection: 'row', marginTop: spacing.md, gap: spacing.sm },
  btn: { flex: 1, height: 44, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center' },
  btnGhost: { backgroundColor: staticColors.surfaceAlt },
});
