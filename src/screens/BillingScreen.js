import React from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, Button,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtDate } from '../data/format';

const STATUS_META = {
  active: { label: 'Active', badge: 'success' },
  trial: { label: 'Trial', badge: 'pending' },
  past_due: { label: 'Past due', badge: 'rejected' },
};

// BillingScreen — Manager/Administrator only, reachable from
// Settings > Organisation > "Billing & subscription". Stands in for
// the Stripe-backed subscription flow: a company signs in with their
// org's own plan/status/seat count and can switch tiers here (a real
// build would hit Stripe Checkout/Billing Portal instead of the demo
// confirm-alert below).
export default function BillingScreen({ navigation }) {
  const { colors: themeColors } = useTheme();
  const { user } = useAuth();
  const { plans, billing, invoices, changePlan } = useData();

  const currentPlan = plans.find((p) => p.id === billing?.planId);
  const statusMeta = STATUS_META[billing?.status] || STATUS_META.active;

  // Switches immediately rather than gating behind a confirm dialog —
  // a real build would hand off to Stripe Checkout here instead.
  const onSwitchPlan = async (plan) => {
    if (plan.id === currentPlan?.id) return;
    try {
      await changePlan(plan.id);
      Alert.alert('Plan updated', `You're now on the ${plan.name} plan (GHS ${plan.price} / 2 years).`);
    } catch (err) {
      Alert.alert('Could not switch plan', err.message);
    }
  };

  return (
    <Screen>
      <Header
        eyebrow={user.organizationName}
        title="Billing & subscription"
        subtitle="Manage your organisation's plan and payment details"
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      {/* Current plan summary */}
      <Card accent={statusMeta.badge}>
        <View style={styles.planHead}>
          <View style={{ flex: 1 }}>
            <Text variant="caption" color={colors.textSecondary}>Current plan</Text>
            <Text variant="h2">{currentPlan?.name || '—'}</Text>
          </View>
          <Badge label={statusMeta.label} status={statusMeta.badge} />
        </View>

        <Text style={[styles.price, { color: themeColors.brand }]}>
          GHS {currentPlan?.price}
          <Text variant="body" color={colors.textSecondary}> / 2 years</Text>
        </Text>

        <View style={styles.metaRow}>
          <MetaCell icon="people-outline" label="Seats used"
            value={`${billing?.seatsUsed ?? 0} / ${currentPlan?.seatLimit ?? '—'}`} />
          <MetaCell icon="calendar-outline" label="Renews"
            value={fmtDate(billing?.renewalDate)} />
        </View>
      </Card>

      {/* Plan comparison */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Choose a plan
      </Text>
      {plans.map((plan) => {
        const isCurrent = plan.id === currentPlan?.id;
        return (
          <Card key={plan.id} style={{ marginBottom: spacing.sm }}>
            <View style={styles.planHead}>
              <View style={{ flex: 1 }}>
                <Text variant="h3">{plan.name}</Text>
                <Text variant="bodySemibold" style={{ color: themeColors.brand }}>
                  GHS {plan.price}<Text variant="caption" color={colors.textSecondary}> / 2yr</Text>
                </Text>
              </View>
              {isCurrent ? <Badge label="Current plan" status="info" size="sm" dot={false} /> : null}
            </View>

            {plan.features.map((f) => (
              <View key={f} style={styles.featureRow}>
                <Ionicons name="checkmark-circle" size={16} color={themeColors.primary} />
                <Text variant="bodyMd" color={colors.textSecondary} style={{ marginLeft: 6, flex: 1 }}>
                  {f}
                </Text>
              </View>
            ))}

            {!isCurrent ? (
              <Button
                label={`Switch to ${plan.name}`}
                variant="secondary"
                onPress={() => onSwitchPlan(plan)}
                style={{ marginTop: spacing.sm }}
              />
            ) : null}
          </Card>
        );
      })}

      {/* Payment method */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Payment method
      </Text>
      <Card>
        <View style={styles.cardRow}>
          <View style={[styles.cardIcon, { backgroundColor: themeColors.primarySurface }]}>
            <Ionicons name="card-outline" size={20} color={themeColors.brand} />
          </View>
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="bodySemibold">Card ending in {billing?.paymentLast4 || '••••'}</Text>
            <Text variant="caption" color={colors.textSecondary}>Billed once every 2 years</Text>
          </View>
          <Button
            label="Update"
            variant="ghost"
            size="sm"
            fullWidth={false}
            onPress={() => Alert.alert('Demo only', 'Updating a card wires up to Stripe Billing Portal in production.')}
          />
        </View>
      </Card>

      {/* Invoice history */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Billing history
      </Text>
      <Card padded={false}>
        {invoices.length === 0 ? (
          <Text variant="body" color={colors.textSecondary} style={{ padding: spacing.md }}>
            No invoices yet.
          </Text>
        ) : (
          invoices.map((inv, i) => (
            <View key={inv.id}>
              <View style={styles.invoiceRow}>
                <View style={{ flex: 1 }}>
                  <Text variant="bodySemibold">{fmtDate(inv.date)}</Text>
                  <Text variant="caption" color={colors.textSecondary}>
                    2-year subscription
                  </Text>
                </View>
                <Text variant="bodySemibold" style={{ marginRight: spacing.sm }}>
                  GHS {inv.amount}
                </Text>
                <Badge
                  label={inv.status === 'paid' ? 'Paid' : 'Failed'}
                  status={inv.status === 'paid' ? 'success' : 'rejected'}
                  size="sm"
                  dot={false}
                />
              </View>
              {i < invoices.length - 1 ? <View style={styles.divider} /> : null}
            </View>
          ))
        )}
      </Card>
    </Screen>
  );
}

function MetaCell({ icon, label, value }) {
  const { colors: themeColors } = useTheme();
  return (
    <View style={styles.metaCell}>
      <Ionicons name={icon} size={16} color={themeColors.primary} style={{ marginRight: 6 }} />
      <View>
        <Text variant="caption" color={colors.textSecondary}>{label}</Text>
        <Text variant="bodySemibold">{value}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  planHead: { flexDirection: 'row', alignItems: 'flex-start', marginBottom: spacing.xs },
  price: { fontFamily: fonts.displayExtra, fontSize: 30, marginBottom: spacing.sm },
  metaRow: { flexDirection: 'row', gap: spacing.lg, marginTop: spacing.xs },
  metaCell: { flexDirection: 'row', alignItems: 'center' },
  featureRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 3 },
  cardRow: { flexDirection: 'row', alignItems: 'center' },
  cardIcon: {
    width: 40, height: 40, borderRadius: 12,
    alignItems: 'center', justifyContent: 'center',
  },
  invoiceRow: {
    flexDirection: 'row', alignItems: 'center',
    padding: spacing.md,
  },
  divider: { height: 1, backgroundColor: colors.border, marginLeft: spacing.md },
});
