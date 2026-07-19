import React, { useState } from 'react';
import { View, StyleSheet, Pressable, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Button } from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';

// LegalAgreementScreen has two modes, driven by whether `pending` (the
// not-yet-submitted company registration form) was passed in:
//
//   - Registration flow: RegisterCompanyScreen collects the form, then
//     pushes here with `pending` set. A company can't use VisiLog until
//     this screen's subscription is agreed to and "paid" for — there's
//     no real payment processor in this build, so this is a placeholder
//     checkout step, but registerCompany() (the call that actually
//     creates the org and hands back a company code) only fires from
//     the button on *this* screen, never from the form screen itself.
//   - Review flow: reachable anytime afterwards from Company Setup (the
//     paying manager's own screen), with no `pending` data — read-only,
//     no checkbox or payment section, just the terms.
const ANNUAL_PRICE = 480;
const TERM_YEARS = 2;

const TERMS_TEXT = `VisiLog Subscription Agreement

1. Term & Renewal
VisiLog is licensed on a minimum two-year subscription term. Your subscription begins on the date of activation and automatically covers your organization for the full term shown below. You will be notified before renewal.

2. What's included
Your subscription covers unlimited visitor check-ins, staff roster management, meeting room booking, NFC badge issuance, and all Company Setup administration tools for your organization, billed at the plan tier your Administrator selects afterwards.

3. Data & Privacy
Visitor and staff data you enter is stored for your organization only and is never shared with other tenants. You are responsible for obtaining any consent required by your local data protection laws before collecting visitor information.

4. Administrator responsibility
The person completing this agreement is designated the organization's initial Administrator (Manager role) and is responsible for configuring the staff roster, office location, and branding in Company Setup, and for managing who else on their team has administrative access.

5. Cancellation
You may cancel future renewals at any time from Billing & Subscription in Settings. Cancelling does not refund the current term.

By continuing, you confirm you have the authority to enter into this agreement on behalf of your organization.`;

export default function LegalAgreementScreen({ navigation, route }) {
  const { colors: themeColors } = useTheme();
  const { registerCompany } = useAuth();
  const pending = route?.params?.pending || null;
  const viewOnly = !pending;

  const [agreed, setAgreed] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  const onConfirm = async () => {
    if (!agreed || submitting) return;
    setSubmitting(true);
    const result = await registerCompany(
      pending.companyName, pending.adminName, pending.adminEmail, pending.password
    );
    setSubmitting(false);
    if (!result.ok) {
      Alert.alert('Could not register your company', result.error);
      return;
    }
    Alert.alert(
      'You’re all set',
      `${result.organization.name} is registered and active for the next ${TERM_YEARS} years. Your company code is ${result.organization.code} — share it with your staff and visitors so they can sign up. You can find it again anytime in Company Setup.`
    );
    // On success the root navigator will swap to the manager tab shell.
  };

  return (
    <Screen>
      <Header
        eyebrow={viewOnly ? 'Company Setup' : 'Before you activate'}
        title="Legal agreement"
        subtitle={viewOnly
          ? 'The terms your organization agreed to when it registered.'
          : "Read and agree to continue — you're a couple of taps from a company code."}
        onBackPress={() => navigation.goBack()}
      />

      <Card>
        <Text variant="bodyMd" color={colors.textPrimary} style={styles.terms}>
          {TERMS_TEXT}
        </Text>
      </Card>

      {!viewOnly ? (
        <>
          <Card style={{ marginTop: spacing.sm }}>
            <View style={styles.planRow}>
              <View>
                <Text variant="bodySemibold">VisiLog subscription</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {TERM_YEARS}-year term · billed once
                </Text>
              </View>
              <Text variant="h2" color={themeColors.brand}>
                ${ANNUAL_PRICE * TERM_YEARS}
              </Text>
            </View>
            <Text variant="caption" color={colors.textMuted} style={{ marginTop: spacing.xs }}>
              This is a demo build — no real payment is processed and no card details are collected. Agreeing below activates your subscription immediately.
            </Text>
          </Card>

          <Pressable onPress={() => setAgreed((a) => !a)} style={styles.agreeRow}>
            <View style={[
              styles.checkbox,
              agreed && { backgroundColor: themeColors.primary, borderColor: themeColors.primary },
            ]}>
              {agreed ? <Ionicons name="checkmark" size={14} color="#FFF" /> : null}
            </View>
            <Text variant="bodyMd" style={{ flex: 1, marginLeft: spacing.xs }}>
              I have read and agree to the VisiLog Subscription Agreement above.
            </Text>
          </Pressable>

          <Button
            label={submitting ? 'Activating…' : `Agree & activate (${TERM_YEARS}-year term)`}
            icon="shield-checkmark-outline"
            onPress={onConfirm}
            disabled={!agreed || submitting}
            style={{ marginTop: spacing.md }}
          />
        </>
      ) : null}
    </Screen>
  );
}

const styles = StyleSheet.create({
  terms: { lineHeight: 20 },
  planRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  agreeRow: {
    flexDirection: 'row', alignItems: 'center',
    marginTop: spacing.md, paddingVertical: spacing.xs,
  },
  checkbox: {
    width: 20, height: 20, borderRadius: 6,
    borderWidth: 1.5, borderColor: colors.borderStrong,
    alignItems: 'center', justifyContent: 'center',
  },
});
