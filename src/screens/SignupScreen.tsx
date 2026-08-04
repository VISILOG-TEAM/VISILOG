import React, { useState } from 'react';
import {
  View,
  StyleSheet,
  Pressable,
  TextInput,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { Text, Segmented } from '../components';
import { useAuth } from '../context/AuthContext';
import { fonts } from '../theme/typography';
import { spacing, radius } from '../theme/spacing';
import type { RootStackNavigation } from '../types/navigation';
import type { IoniconName } from '../types';

interface SignupScreenProps {
  navigation: RootStackNavigation;
}

// Signup uses the exact same background photo as Login, so the two
// pages feel like one continuous flow. The sign-in/register pill at
// the top mirrors Login's -- tapping "Sign in" here just goes back.
//
// Role isn't chosen here -- the backend matches `email` against the
// company's staff roster (that role) or falls back to visitor.
export default function SignupScreen({ navigation }: SignupScreenProps) {
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [companyCode, setCompanyCode] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const { signup } = useAuth();

  const onSubmit = async () => {
    if (!fullName.trim() || !email.trim() || !password || !companyCode.trim()) {
      Alert.alert('Almost there', 'Please fill in every field above.');
      return;
    }
    if (password.length < 8) {
      Alert.alert('Password too short', 'Your password must be at least 8 characters.');
      return;
    }
    if (password !== confirm) {
      Alert.alert("Passwords don't match", 'Please re-enter the same password twice.');
      return;
    }
    setSubmitting(true);
    const result = await signup(companyCode, email, password, fullName);
    setSubmitting(false);
    if (!result.ok) {
      Alert.alert('Signup failed', result.error);
      return;
    }
    // On success the root navigator will swap to the app stack.
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
            {/* Back chevron */}
            <Pressable onPress={() => navigation.goBack()} style={styles.back} hitSlop={8}>
              <Ionicons name="chevron-back" size={22} color="#FFFFFF" />
            </Pressable>

            <BlurView intensity={25} tint="light" style={styles.card}>
              <View style={styles.cardInner}>
                <Text style={styles.wordmark}>VisiLog</Text>

                <Segmented
                  value="register"
                  onChange={(v) => {
                    if (v === 'signin') navigation.goBack();
                  }}
                  options={[
                    { label: 'Sign in', value: 'signin' },
                    { label: 'Register', value: 'register' },
                  ]}
                  style={{ marginBottom: spacing.lg }}
                />

                <Text style={styles.heading}>Create account</Text>

                <Field
                  icon="business-outline"
                  placeholder="Company name"
                  value={companyCode}
                  onChangeText={setCompanyCode}
                  autoCapitalize="characters"
                />
                <Field
                  icon="person-outline"
                  placeholder="Full name"
                  value={fullName}
                  onChangeText={setFullName}
                />
                <Field
                  icon="mail-outline"
                  placeholder="Email address"
                  value={email}
                  onChangeText={setEmail}
                  autoCapitalize="none"
                  keyboardType="email-address"
                />
                <Field
                  icon="lock-closed-outline"
                  placeholder="Password"
                  value={password}
                  onChangeText={setPassword}
                  secureTextEntry
                />
                <Text style={styles.passwordHint}>Must be at least 8 characters.</Text>
                <Field
                  icon="shield-checkmark-outline"
                  placeholder="Confirm password"
                  value={confirm}
                  onChangeText={setConfirm}
                  secureTextEntry
                />

                <Pressable
                  onPress={onSubmit}
                  disabled={submitting}
                  style={({ pressed }) => [{ opacity: pressed || submitting ? 0.85 : 1 }]}
                >
                  <LinearGradient
                    colors={['#5ECFC9', '#1B8A82', '#0B4A47']}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={styles.signupBtn}
                  >
                    <Text style={styles.signupBtnText}>
                      {submitting ? 'Creating account...' : 'Create account'}
                    </Text>
                  </LinearGradient>
                </Pressable>

                <View style={styles.loginRow}>
                  <Text style={styles.loginHint}>Already have one? </Text>
                  <Pressable onPress={() => navigation.goBack()}>
                    <Text style={styles.loginLink}>Login</Text>
                  </Pressable>
                </View>
              </View>
            </BlurView>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </View>
  );
}

// Small internal field component to keep the JSX above readable. Local
// because it's only used on this screen.
function Field({
  icon,
  secureTextEntry,
  ...inputProps
}: { icon: IoniconName; secureTextEntry?: boolean } & React.ComponentProps<typeof TextInput>) {
  const [revealed, setRevealed] = useState(false);
  return (
    <View style={styles.fieldRow}>
      <Ionicons name={icon} size={18} color="rgba(255,255,255,0.85)" />
      <TextInput
        placeholderTextColor="rgba(255,255,255,0.65)"
        style={styles.input}
        secureTextEntry={secureTextEntry && !revealed}
        {...inputProps}
      />
      {secureTextEntry ? (
        <Pressable onPress={() => setRevealed((r) => !r)} hitSlop={8}>
          <Ionicons
            name={revealed ? 'eye-outline' : 'eye-off-outline'}
            size={18}
            color="rgba(255,255,255,0.85)"
          />
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  // Solid brand green -- replaced the decorative photo background so
  // the auth screens read as part of the branded app rather than a
  // stock image. Uses the emerald brand ink from theme/colors.ts.
  bg: { flex: 1, backgroundColor: '#0F3D2A' },
  safe: { flex: 1 },
  scroll: {
    flexGrow: 1,
    justifyContent: 'center',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.xxl,
  },

  back: { position: 'absolute', top: spacing.sm, left: spacing.sm, padding: 8, zIndex: 1 },

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

  wordmark: {
    fontFamily: fonts.displayExtra,
    fontSize: 28,
    lineHeight: 36,
    color: '#FFFFFF',
    textAlign: 'center',
    marginBottom: spacing.md,
  },
  heading: {
    fontFamily: fonts.displayBold,
    fontSize: 24,
    lineHeight: 30,
    color: '#FFFFFF',
    marginBottom: spacing.lg,
  },
  subheading: {
    fontFamily: fonts.regular,
    fontSize: 13,
    color: 'rgba(255,255,255,0.85)',
    marginBottom: spacing.lg,
  },

  fieldRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.12)',
    borderColor: 'rgba(255,255,255,0.28)',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    height: 48,
    marginBottom: spacing.sm,
  },
  input: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 15,
    color: '#FFFFFF',
    marginHorizontal: 8,
    paddingVertical: 0,
  },
  passwordHint: {
    fontFamily: fonts.regular,
    fontSize: 11,
    color: 'rgba(255,255,255,0.7)',
    marginTop: -6,
    marginBottom: spacing.sm,
  },

  signupBtn: {
    height: 50,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: spacing.sm,
  },
  signupBtnText: { fontFamily: fonts.bold, fontSize: 16, color: '#FFFFFF', letterSpacing: 0.3 },

  loginRow: { flexDirection: 'row', justifyContent: 'center', marginTop: spacing.lg },
  loginHint: { fontFamily: fonts.regular, fontSize: 13, color: 'rgba(255,255,255,0.85)' },
  loginLink: { fontFamily: fonts.bold, fontSize: 13, color: '#FFFFFF' },
});
