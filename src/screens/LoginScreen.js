import React, { useState } from 'react';
import {
  View, ImageBackground, StyleSheet, Pressable, TextInput,
  KeyboardAvoidingView, Platform, ScrollView, Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { Text } from '../components';
import { colors } from '../theme/colors';
import { fonts } from '../theme/typography';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';

// LoginScreen
// ---------------------------------------------------------------
// Design brief (from the user): use the teal-silk image as the
// background, and a frosted-glass card holding the form — matching
// the reference mock the user shared. The card sits centered, the
// "Login" button is a green gradient, with "Don't have an account?
// Signup" beneath it.
export default function LoginScreen({ navigation }) {
  const { login, DEMO_EMAIL, DEMO_PASSWORD } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [remember, setRemember] = useState(true);
  const [submitting, setSubmitting] = useState(false);

  const onSubmit = () => {
    setSubmitting(true);
    const result = login(email, password);
    setSubmitting(false);
    if (!result.ok) {
      Alert.alert('Login failed', result.error);
    }
    // On success the root navigator will swap to the app stack.
  };

  const fillDemo = () => {
    setEmail(DEMO_EMAIL);
    setPassword(DEMO_PASSWORD);
  };

  return (
    <ImageBackground
      source={require('../../assets/login-bg.jpg')}
      style={styles.bg}
      resizeMode="cover"
    >
      <StatusBar style="light" />
      {/* Subtle dark wash so the glass card stays readable on any phone */}
      <View style={styles.wash} />

      <SafeAreaView style={styles.safe}>
        <KeyboardAvoidingView
          style={{ flex: 1 }}
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        >
          <ScrollView
            contentContainerStyle={styles.scroll}
            keyboardShouldPersistTaps="handled"
            showsVerticalScrollIndicator={false}
          >
            {/* The frosted glass card. expo-blur renders a real iOS-style
                blur; on Android it falls back to a translucent fill. */}
            <BlurView intensity={40} tint="light" style={styles.card}>
              <View style={styles.cardInner}>
                {/* Wordmark — used here instead of a separate logo image */}
                <Text style={styles.wordmark}>VisiLog</Text>
                <Text style={styles.tagline}>
                  Visitor Management & Reception Operations
                </Text>

                <Text style={styles.heading}>Login</Text>
                <Text style={styles.subheading}>
                  Welcome back. Please sign in to continue.
                </Text>

                {/* Email */}
                <View style={styles.fieldRow}>
                  <Ionicons name="person-outline" size={18} color="rgba(255,255,255,0.85)" />
                  <TextInput
                    value={email}
                    onChangeText={setEmail}
                    placeholder="Email address"
                    placeholderTextColor="rgba(255,255,255,0.65)"
                    autoCapitalize="none"
                    keyboardType="email-address"
                    style={styles.input}
                  />
                </View>

                {/* Password */}
                <View style={styles.fieldRow}>
                  <Ionicons name="lock-closed-outline" size={18} color="rgba(255,255,255,0.85)" />
                  <TextInput
                    value={password}
                    onChangeText={setPassword}
                    placeholder="Password"
                    placeholderTextColor="rgba(255,255,255,0.65)"
                    secureTextEntry={!showPassword}
                    style={styles.input}
                  />
                  <Pressable onPress={() => setShowPassword((s) => !s)} hitSlop={8}>
                    <Ionicons
                      name={showPassword ? 'eye-outline' : 'eye-off-outline'}
                      size={18}
                      color="rgba(255,255,255,0.85)"
                    />
                  </Pressable>
                </View>

                {/* Remember me */}
                <Pressable style={styles.remember} onPress={() => setRemember((r) => !r)}>
                  <View style={[styles.checkbox, remember && styles.checkboxOn]}>
                    {remember ? <Ionicons name="checkmark" size={14} color="#FFF" /> : null}
                  </View>
                  <Text style={styles.rememberText}>Remember me</Text>
                </Pressable>

                {/* Gradient login button */}
                <Pressable onPress={onSubmit} disabled={submitting} style={({ pressed }) => [
                  { opacity: pressed || submitting ? 0.85 : 1 },
                ]}>
                  <LinearGradient
                    colors={['#A7F37A', '#16A34A', '#0E9F8E']}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={styles.loginBtn}
                  >
                    <Text style={styles.loginBtnText}>
                      {submitting ? 'Signing in…' : 'Login'}
                    </Text>
                  </LinearGradient>
                </Pressable>

                {/* Demo credentials helper — the spec's User Guide ships an
                    employee@vra.com / password1234 demo account. */}
                <Pressable onPress={fillDemo} style={{ marginTop: spacing.sm }}>
                  <Text style={styles.demoLink}>Use demo account</Text>
                </Pressable>

                {/* Signup */}
                <View style={styles.signupRow}>
                  <Text style={styles.signupHint}>Don&apos;t have an account? </Text>
                  <Pressable onPress={() => navigation.navigate('Signup')}>
                    <Text style={styles.signupLink}>Signup</Text>
                  </Pressable>
                </View>
              </View>
            </BlurView>

            <Text style={styles.footer}>VisiLog 2.0 · Secure visitor management</Text>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </ImageBackground>
  );
}

const styles = StyleSheet.create({
  bg: { flex: 1, backgroundColor: '#0E4E55' },
  wash: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(8, 30, 36, 0.25)' },
  safe: { flex: 1 },
  scroll: {
    flexGrow: 1,
    justifyContent: 'center',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.xxl,
  },

  // Card
  card: {
    borderRadius: radius.xl,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.35)',
  },
  cardInner: {
    padding: spacing.xl,
    // On Android BlurView is weaker, so we tint the inner panel too
    backgroundColor: Platform.OS === 'android' ? 'rgba(255,255,255,0.18)' : 'rgba(255,255,255,0.08)',
  },

  // Branding inside the card
  wordmark: {
    fontFamily: fonts.displayExtra,
    fontSize: 32,
    color: '#FFFFFF',
    letterSpacing: -0.5,
    textAlign: 'center',
  },
  tagline: {
    fontFamily: fonts.medium,
    fontSize: 12,
    color: 'rgba(255,255,255,0.85)',
    textAlign: 'center',
    marginTop: 2,
    marginBottom: spacing.lg,
  },

  heading: {
    fontFamily: fonts.displayBold,
    fontSize: 26,
    color: '#FFFFFF',
    marginBottom: 4,
  },
  subheading: {
    fontFamily: fonts.regular,
    fontSize: 13,
    color: 'rgba(255,255,255,0.85)',
    marginBottom: spacing.lg,
  },

  // Form fields — translucent so the glass shows through
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

  // Remember me
  remember: { flexDirection: 'row', alignItems: 'center', marginVertical: spacing.sm },
  checkbox: {
    width: 18, height: 18, borderRadius: 5,
    borderWidth: 1.5, borderColor: 'rgba(255,255,255,0.85)',
    alignItems: 'center', justifyContent: 'center',
    marginRight: 8,
  },
  checkboxOn: { backgroundColor: '#16A34A', borderColor: '#16A34A' },
  rememberText: { fontFamily: fonts.medium, fontSize: 13, color: '#FFFFFF' },

  // Login button
  loginBtn: {
    height: 50,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: spacing.sm,
  },
  loginBtnText: {
    fontFamily: fonts.bold,
    fontSize: 16,
    color: '#FFFFFF',
    letterSpacing: 0.3,
  },

  demoLink: {
    fontFamily: fonts.medium,
    fontSize: 12,
    color: 'rgba(255,255,255,0.85)',
    textAlign: 'center',
    textDecorationLine: 'underline',
  },

  // Signup
  signupRow: { flexDirection: 'row', justifyContent: 'center', marginTop: spacing.lg },
  signupHint: { fontFamily: fonts.regular, fontSize: 13, color: 'rgba(255,255,255,0.85)' },
  signupLink: { fontFamily: fonts.bold, fontSize: 13, color: '#FFFFFF' },

  footer: {
    fontFamily: fonts.medium,
    fontSize: 11,
    color: 'rgba(255,255,255,0.75)',
    textAlign: 'center',
    marginTop: spacing.xl,
    letterSpacing: 0.5,
  },
});
