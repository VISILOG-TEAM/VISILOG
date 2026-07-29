import React, { useMemo, useState } from 'react';
import { View, StyleSheet, FlatList, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen,
  Header,
  Text,
  Card,
  Badge,
  Segmented,
  EmptyState,
  Avatar,
  Button,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useData } from '../context/DataContext';
import { fmtDate } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';
import type { NfcCard as NfcCardType } from '../types';
import { usePullToRefresh } from '../components/usePullToRefresh';

interface NFCCardsScreenProps {
  navigation: RootStackNavigation;
}

type NfcCardFilter = 'active' | 'revoked' | 'all';

// NFCCardsScreen -- list of virtual NFC cards.
// Per the VisiLog 2.0 spec: each card has a holder, an issuance date,
// an expiry, and a status ('active' | 'revoked'). Receptionists can
// revoke (or in this demo, "rotate") a card.
export default function NFCCardsScreen({ navigation }: NFCCardsScreenProps) {
  const refreshControl = usePullToRefresh();
  const { nfcCards, employeeById } = useData();
  const [filter, setFilter] = useState<NfcCardFilter>('active');

  const list = useMemo(() => {
    return nfcCards
      .filter((c) => filter === 'all' || c.status === filter)
      .map((c) => {
        let holder;
        if (c.holderType === 'employee') holder = employeeById(c.holderId)?.name || 'Unknown';
        else holder = `Visitor ${c.holderId}`;
        return { ...c, holderName: holder };
      });
  }, [nfcCards, filter, employeeById]);

  const onRevoke = (card: NfcCardType) => {
    Alert.alert('Revoke NFC card?', `Card ${card.tokenHash} will no longer grant access.`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Revoke',
        style: 'destructive',
        onPress: () => {
          Alert.alert('Demo only', 'Card revocation hits the NFC service in production.');
        },
      },
    ]);
  };

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="NFC Cards"
          subtitle="Issued credentials & access tokens"
          rightIcon="add"
          onRightPress={() => Alert.alert('Issue card', 'Card issuance is a demo placeholder.')}
        />
        <Segmented
          value={filter}
          onChange={setFilter}
          options={[
            { label: 'Active', value: 'active' },
            { label: 'Revoked', value: 'revoked' },
            { label: 'All', value: 'all' },
          ]}
        />
      </View>

      <FlatList
        refreshControl={refreshControl}
        data={list}
        keyExtractor={(c) => c.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="card-outline"
            title="No cards here"
            message="Issued NFC cards will appear in this list."
          />
        }
        renderItem={({ item }) => <NfcCard card={item} onRevoke={() => onRevoke(item)} />}
      />
    </Screen>
  );
}

function NfcCard({
  card,
  onRevoke,
}: {
  card: NfcCardType & { holderName: string };
  onRevoke: () => void;
}) {
  const { colors } = useTheme();
  const isActive = card.status === 'active';
  return (
    <Card accent={isActive ? 'onsite' : 'rejected'} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.cardHead}>
        <View
          style={[
            styles.chip,
            { backgroundColor: isActive ? colors.primarySurface : colors.status.rejected.bg },
          ]}
        >
          <Ionicons
            name="card"
            size={20}
            color={isActive ? colors.primary : colors.status.rejected.solid}
          />
        </View>
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold">{card.holderName}</Text>
          <Text variant="caption" color={colors.textSecondary}>
            {card.holderType === 'employee' ? 'Employee credential' : 'Visitor pass'}
          </Text>
        </View>
        <Badge label={card.status} status={isActive ? 'success' : 'rejected'} size="sm" />
      </View>

      <View style={[styles.tokenRow, { backgroundColor: colors.surfaceAlt }]}>
        <Text variant="caption" color={colors.textMuted}>
          Token
        </Text>
        <Text style={[styles.token, { color: colors.brand }]}>{card.tokenHash}</Text>
      </View>

      <View style={styles.dateRow}>
        <View style={{ flex: 1 }}>
          <Text variant="caption" color={colors.textMuted}>
            Issued
          </Text>
          <Text variant="bodyMd">{fmtDate(card.issuedAt)}</Text>
        </View>
        <View style={{ flex: 1 }}>
          <Text variant="caption" color={colors.textMuted}>
            Expires
          </Text>
          <Text variant="bodyMd">{fmtDate(card.expiresAt)}</Text>
        </View>
      </View>

      {isActive && (
        <Button
          label="Revoke card"
          variant="secondary"
          icon="ban-outline"
          onPress={onRevoke}
          style={{ marginTop: spacing.sm }}
        />
      )}
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  cardHead: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.sm },
  chip: {
    width: 44,
    height: 44,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  tokenRow: {
    borderRadius: radius.sm,
    padding: spacing.sm,
    marginBottom: spacing.sm,
  },
  token: { fontFamily: fonts.semibold, fontSize: 16, letterSpacing: 1 },
  dateRow: { flexDirection: 'row', gap: spacing.md },
});
