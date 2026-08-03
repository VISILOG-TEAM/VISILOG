import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  Pressable,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { Text } from '../components';
import { useAuth } from '../context/AuthContext';
import { fonts } from '../theme/typography';
import { spacing, radius } from '../theme/spacing';

// The second gate after VerifyEmailScreen: the address is confirmed,
// but the company's owner (a Manager) still has to approve the account
// with a code emailed to *them*, not to whoever is looking at this
// screen -- so unlike VerifyEmailScreen there's nothing to type here.
// "Check status" just re-asks the backend for a fresh token (see
// AuthContext.refreshSession); once a Manager approves, that token
// comes back with approved=true and RootNavigator moves on by itself.
//
// This is the ONLY screen a verified-but-unapproved account can reach
// -- see RootNavigator, and the matching server-side gate in
// JwtAuthFilter -- so it holds whether or not the app is the thing
// enforcing it. Styled like VerifyEmailScreen since it's a direct
// continuation of the same onboarding stack.
export default function PendingApprovalScreen() {
  const { user, organization, refreshSession, logout } = useAuth();
  const [error, setError] = useState<string | null>(null);
  const [checking, setChecking] = useState(false);

  const onCheckStatus = async () => {
    if (checking) return;
    setChecking(true);
    setError(null);
    const result = await refreshSession();
    // On success there's nothing to navigate to: if the Manager has
    // approved by now, `user.ownerApproved` flips, RootNavigator
    // re-renders, and this screen is replaced by the role's tab shell.
    // If not, the same screen just re-renders with checking reset.
    if (!result.ok) {
      setError(result.error ?? 'Could not check your status.');
    }
    setChecking(false);
  };

  return (
    <View style={styles.bg}>
      <StatusBar style="light" />
      <SafeAreaView style={styles.safe}>
        <KeyboardAvoidingView style={{ flex: 1 }} behavior="padding">
          <ScrollView
            contentContainerStyle={styles.scroll}
            keyboardShouldPersistTaps="handled"
            showsVerticalScrollIndicator={false}
          >
            <BlurView intensity={25} tint="light" style={styles.card}>
              <View style={styles.cardInner}>
                <View style={styles.iconRing}>
                  <Ionicons name="hourglass-outline" size={26} color="#FFFFFF" />
                </View>

                <Text style={styles.heading}>Waiting for approval</Text>
                <Text style={styles.body}>
                  Your email is confirmed. Someone at {organization?.name ?? 'your company'} with
                  owner access still needs to approve your account -- we've emailed them a code to
                  do that.
                </Text>

                {error ? <Text style={styles.error}>{error}</Text> : null}

                <Pressable
                  onPress={onCheckStatus}
                  disabled={checking}
                  style={({ pressed }) => [{ opacity: pressed || checking ? 0.85 : 1 }]}
                >
                  <LinearGradient
                    colors={['#5ECFC9', '#1B8A82', '#0B4A47']}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={styles.submitBtn}
                  >
                    {checking ? (
                      <ActivityIndicator color="#FFFFFF" />
                    ) : (
                      <Text style={styles.submitBtnText}>Check status</Text>
                    )}
                  </LinearGradient>
                </Pressable>

                {/* Escape hatch: without this, someone waiting on
                    approval has no way back to the login screen. */}
                <Pressable onPress={logout} style={styles.signOutRow}>
                  <Text style={styles.signOutText}>Wrong account? Sign out and start again</Text>
                </Pressable>
              </View>
            </BlurView>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  bg: { flex: 1, backgroundColor: '#0F3D2A' },
  safe: { flex: 1 },
  scroll: {
    flexGrow: 1,
    justifyContent: 'center',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.xxl,
  },

  card: {
    borderRadius: radius.xl,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.35)',
  },
  cardInner: {
    padding: spacing.xl,
    backgroundColor:
      Platform.OS === 'android' ? 'rgba(255,255,255,0.12)' : 'rgba(255,255,255,0.05)',
  },

  iconRing: {
    width: 56,
    height: 56,
    borderRadius: 28,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(255,255,255,0.15)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.3)',
    alignSelf: 'center',
    marginBottom: spacing.md,
  },

  heading: {
    fontFamily: fonts.displayBold,
    fontSize: 24,
    color: '#FFFFFF',
    textAlign: 'center',
  },
  body: {
    fontFamily: fonts.regular,
    fontSize: 13,
    lineHeight: 20,
    color: 'rgba(255,255,255,0.85)',
    textAlign: 'center',
    marginTop: spacing.xs,
    marginBottom: spacing.lg,
  },

  error: {
    fontFamily: fonts.regular,
    fontSize: 13,
    color: '#FFD9D9',
    textAlign: 'center',
    marginBottom: spacing.sm,
  },

  submitBtn: {
    height: 50,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
  },
  submitBtnText: { fontFamily: fonts.bold, fontSize: 16, color: '#FFFFFF', letterSpacing: 0.3 },

  signOutRow: { alignItems: 'center', marginTop: spacing.lg },
  // Red, like every other way out of the app -- same soft red
  // VerifyEmailScreen's sign-out row uses, so both halves of onboarding
  // read as the same "leave" affordance.
  signOutText: { fontFamily: fonts.bold, fontSize: 12, color: '#FFB4B4' },
});
