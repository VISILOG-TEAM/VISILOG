import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  Pressable,
  TextInput,
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

// The last step of signing up: confirm the email address the account
// was created with by entering the 6-digit code sent to it.
//
// This is the ONLY screen an unverified account can reach -- see
// RootNavigator, and the matching server-side gate in JwtAuthFilter, so
// it holds whether or not the app is the thing enforcing it. Styled
// like RegisterCompany/Signup rather than the in-app screens because
// that's what it continues from; it isn't "inside" the app yet.
export default function VerifyEmailScreen() {
  const { user, organization, verifyEmail, resendVerification, logout } = useAuth();
  const [code, setCode] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [resending, setResending] = useState(false);

  const onSubmit = async () => {
    if (submitting) return;
    setSubmitting(true);
    setError(null);
    setNotice(null);
    const result = await verifyEmail(code);
    // On success there's nothing to navigate to: `user.emailVerified`
    // flips, RootNavigator re-renders, and this screen is replaced by
    // the role's tab shell. Don't setState after that -- the component
    // is already on its way out.
    if (!result.ok) {
      setError(result.error ?? 'Could not verify that code.');
      setSubmitting(false);
    }
  };

  const onResend = async () => {
    if (resending) return;
    setResending(true);
    setError(null);
    setNotice(null);
    const result = await resendVerification();
    if (result.ok) {
      setNotice(result.message);
      setCode('');
    } else {
      setError(result.message);
    }
    setResending(false);
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
                  <Ionicons name="mail-open-outline" size={26} color="#FFFFFF" />
                </View>

                <Text style={styles.heading}>Check your email</Text>
                <Text style={styles.body}>
                  We sent a 6-digit code to {user?.email ?? 'your email address'}. Enter it below to
                  finish setting up your account.
                </Text>

                <TextInput
                  value={code}
                  onChangeText={(next) => setCode(next.replace(/[^0-9]/g, ''))}
                  placeholder="000000"
                  placeholderTextColor="rgba(255,255,255,0.4)"
                  keyboardType="number-pad"
                  maxLength={6}
                  style={styles.codeInput}
                  autoFocus
                />

                {error ? <Text style={styles.error}>{error}</Text> : null}
                {notice ? <Text style={styles.notice}>{notice}</Text> : null}

                <Pressable
                  onPress={onSubmit}
                  disabled={submitting}
                  style={({ pressed }) => [{ opacity: pressed || submitting ? 0.85 : 1 }]}
                >
                  <LinearGradient
                    colors={['#5ECFC9', '#1B8A82', '#0B4A47']}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={styles.submitBtn}
                  >
                    {submitting ? (
                      <ActivityIndicator color="#FFFFFF" />
                    ) : (
                      <Text style={styles.submitBtnText}>Verify my email</Text>
                    )}
                  </LinearGradient>
                </Pressable>

                <Pressable onPress={onResend} disabled={resending} style={styles.resendRow}>
                  <Text style={styles.resendText}>
                    {resending ? 'Sending...' : "Didn't get it? Resend code"}
                  </Text>
                </Pressable>

                {/* A manager who just registered gets their company code
                    here as well as in the confirmation dialog -- they
                    can't reach Company Setup (where it otherwise lives)
                    until this screen is done with, and that code is the
                    thing their whole staff needs to sign up. */}
                {user?.role === 'manager' && organization?.code ? (
                  <View style={styles.codeNote}>
                    <Text style={styles.codeNoteLabel}>Your company code</Text>
                    <Text style={styles.codeNoteValue}>{organization.code}</Text>
                    <Text style={styles.codeNoteHint}>
                      Share this with your staff and visitors so they can sign up. You can find it
                      again in Company Setup.
                    </Text>
                  </View>
                ) : null}

                {/* Escape hatch: without this, one typo in an email
                    address locks the account out of the app with no way
                    back to the login screen. */}
                <Pressable onPress={logout} style={styles.signOutRow}>
                  <Text style={styles.signOutText}>Wrong address? Sign out and start again</Text>
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

  // Wide letter-spacing and a big face: this is six digits copied from
  // an email, so legibility beats matching the ordinary input style.
  codeInput: {
    fontFamily: fonts.displayBold,
    fontSize: 28,
    letterSpacing: 8,
    color: '#FFFFFF',
    textAlign: 'center',
    backgroundColor: 'rgba(255,255,255,0.12)',
    borderColor: 'rgba(255,255,255,0.28)',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingVertical: spacing.sm,
    marginBottom: spacing.md,
  },

  error: {
    fontFamily: fonts.regular,
    fontSize: 13,
    color: '#FFD9D9',
    textAlign: 'center',
    marginBottom: spacing.sm,
  },
  notice: {
    fontFamily: fonts.regular,
    fontSize: 13,
    color: '#D6F5E4',
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

  resendRow: { alignItems: 'center', marginTop: spacing.md },
  resendText: { fontFamily: fonts.bold, fontSize: 13, color: '#FFFFFF' },

  codeNote: {
    marginTop: spacing.lg,
    padding: spacing.md,
    borderRadius: radius.md,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.22)',
  },
  codeNoteLabel: {
    fontFamily: fonts.regular,
    fontSize: 11,
    color: 'rgba(255,255,255,0.75)',
    textAlign: 'center',
  },
  codeNoteValue: {
    fontFamily: fonts.displayBold,
    fontSize: 22,
    letterSpacing: 1,
    color: '#FFFFFF',
    textAlign: 'center',
    marginVertical: 2,
  },
  codeNoteHint: {
    fontFamily: fonts.regular,
    fontSize: 11,
    lineHeight: 16,
    color: 'rgba(255,255,255,0.75)',
    textAlign: 'center',
  },

  signOutRow: { alignItems: 'center', marginTop: spacing.lg },
  signOutText: { fontFamily: fonts.regular, fontSize: 12, color: 'rgba(255,255,255,0.75)' },
});
