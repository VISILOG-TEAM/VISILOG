import React, { useCallback, useState } from 'react';
import { View, FlatList, StyleSheet, Alert } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Screen, Header, Text, Card, Button, Input, EmptyState } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { useAuth, type PendingApproval } from '../context/AuthContext';
import { fmtRelative } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';

interface PendingApprovalsScreenProps {
  navigation: RootStackNavigation;
}

// Manager-only: every account in this company still waiting on the
// owner-approval code we emailed at signup (see AuthContext.signup /
// AuthService.sendApprovalCode on the backend). Reached from the
// "Pending approvals" card on ManagerHomeScreen, which only shows up
// once there's something here to see.
export default function PendingApprovalsScreen({ navigation }: PendingApprovalsScreenProps) {
  const { listPendingApprovals, approveUser, resendApproval } = useAuth();
  const [approvals, setApprovals] = useState<PendingApproval[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(async () => {
    const result = await listPendingApprovals();
    if (result.ok) {
      setApprovals(result.approvals);
    } else {
      Alert.alert('Could not load pending approvals', result.error);
    }
  }, [listPendingApprovals]);

  useFocusEffect(
    useCallback(() => {
      setLoading(true);
      load().finally(() => setLoading(false));
    }, [load]),
  );

  const onRefresh = async () => {
    setRefreshing(true);
    await load();
    setRefreshing(false);
  };

  const onApproved = (userId: string) => {
    setApprovals((prev) => prev.filter((a) => a.id !== userId));
  };

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Pending approvals"
          subtitle={approvals.length ? `${approvals.length} waiting` : undefined}
          rightIcon="close"
          onRightPress={() => navigation.goBack()}
        />
      </View>

      <FlatList
        data={approvals}
        keyExtractor={(a) => a.id}
        contentContainerStyle={styles.list}
        refreshing={refreshing}
        onRefresh={onRefresh}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          loading ? null : (
            <EmptyState
              icon="checkmark-done-outline"
              title="Nothing waiting"
              message="New sign-ups needing your approval will show up here."
            />
          )
        }
        renderItem={({ item }) => (
          <ApprovalRow
            approval={item}
            onApprove={(code) => approveUser(item.id, code)}
            onResend={() => resendApproval(item.id)}
            onApproved={() => onApproved(item.id)}
          />
        )}
      />
    </Screen>
  );
}

function ApprovalRow({
  approval,
  onApprove,
  onResend,
  onApproved,
}: {
  approval: PendingApproval;
  onApprove: (code: string) => Promise<{ ok: boolean; message: string }>;
  onResend: () => Promise<{ ok: boolean; message: string }>;
  onApproved: () => void;
}) {
  const { colors } = useTheme();
  const [code, setCode] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [resending, setResending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async () => {
    if (!code.trim() || submitting) return;
    setSubmitting(true);
    setError(null);
    const result = await onApprove(code);
    if (result.ok) {
      onApproved();
    } else {
      setError(result.message);
    }
    setSubmitting(false);
  };

  const resend = async () => {
    if (resending) return;
    setResending(true);
    setError(null);
    const result = await onResend();
    Alert.alert(result.ok ? 'Code sent' : 'Could not resend', result.message);
    setResending(false);
  };

  return (
    <Card style={{ marginHorizontal: spacing.md }}>
      <Text variant="bodySemibold">{approval.name}</Text>
      <Text variant="body" color={colors.textSecondary}>
        {approval.email}
      </Text>
      <Text variant="caption" color={colors.textMuted} style={{ marginTop: 2 }}>
        {approval.role.charAt(0) + approval.role.slice(1).toLowerCase()} · requested{' '}
        {fmtRelative(approval.createdAt)}
      </Text>

      <View style={styles.codeRow}>
        <Input
          value={code}
          onChangeText={(next) => setCode(next.replace(/[^0-9]/g, ''))}
          placeholder="000000"
          keyboardType="number-pad"
          style={styles.codeInput}
        />
        <Button
          label="Approve"
          size="sm"
          loading={submitting}
          disabled={!code.trim()}
          onPress={submit}
          fullWidth={false}
          style={styles.approveBtn}
        />
      </View>
      {error ? (
        <Text variant="caption" color={colors.status.error.solid} style={{ marginTop: 4 }}>
          {error}
        </Text>
      ) : null}

      <Button
        label={resending ? 'Sending...' : 'Resend code'}
        variant="ghost"
        size="sm"
        loading={resending}
        onPress={resend}
        style={{ marginTop: spacing.xs }}
      />
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  codeRow: { flexDirection: 'row', alignItems: 'flex-start', marginTop: spacing.sm, gap: spacing.sm },
  codeInput: { flex: 1, marginBottom: 0 },
  approveBtn: { height: 48, paddingHorizontal: spacing.md },
});
