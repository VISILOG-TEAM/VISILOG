import React, { useEffect, useState } from 'react';
import {
  View, ImageBackground, StyleSheet, Pressable, TextInput,
  KeyboardAvoidingView, Platform, ScrollView, Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { StatusBar } from 'expo-status-bar';
import { BlurView } from 'expo-blur';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import * as AuthSession from 'expo-auth-session';
import * as WebBrowser from 'expo-web-browser';
import * as Crypto from 'expo-crypto';
import { Text, Segmented } from '../components';
import { fonts } from '../theme/typography';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { loadRememberedLogin } from '../api/rememberedLogin';
import { API_BASE_URL } from '../api/config';
import { GOOGLE_CLIENT_ID } from '../api/googleConfig';
import type { RootStackNavigation } from '../types/navigation';

// Closes the in-app browser tab automatically once Google redirects
// back -- without this the tab can be left hanging open after a
// successful sign-in.
WebBrowser.maybeCompleteAuthSession();

const GOOGLE_DISCOVERY = {
  authorizationEndpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
  tokenEndpoint: 'https://oauth2.googleapis.com/token',
};

interface LoginScreenProps {
  navigation: RootStackNavigation;
}

// LoginScreen
// ---------------------------------------------------------------
// Uses the original teal-silk background photo (kept on Login/Signup
// specifically, per design direction -- the green gradient is only for
// the newer Splash/RoleSelect screens). The sign-in/register pill at
// the top of the card is purely navigational -- tapping "Register"
// jumps to the Signup screen (see Segmented usage below).
//
// The company code identifies which paying organization (tenant) this
// login belongs to -- VisiLog serves several companies, each with their
// own data and brand colors, so this resolves both.
export default function LoginScreen({ navigation }: LoginScreenProps) {
  const { login, loginWithGoogle } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [companyCode, setCompanyCode] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [remember, setRemember] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [googleSubmitting, setGoogleSubmitting] = useState(false);
  const [nonce] = useState(() => Crypto.randomUUID());

  // "Remember me" previously only kept the session alive across app
  // restarts -- it never actually remembered anything the user could
  // see, which is what the label promises. This restores the last
  // company code + email (never the password) that were saved on a
  // successful login with the box checked.
  useEffect(() => {
    (async () => {
      const remembered = await loadRememberedLogin();
      if (remembered) {
        setCompanyCode(remembered.companyCode);
        setEmail(remembered.email);
      }
    })();
  }, []);

  // Requesting an ID token directly (rather than an auth code) means no
  // client secret is ever needed on the phone -- Google hands back a
  // signed token in the redirect, and the backend is the one that
  // actually verifies it (see GoogleTokenService), never the app itself.
  //
  // Google's OAuth client only accepts a real HTTPS domain as a
  // redirect target, not a bare app scheme -- so this points at a tiny
  // landing page hosted by our own backend (OAuthRedirectController),
  // which immediately bounces the browser on to visilog://oauth-redirect
  // carrying the result forward. expo-auth-session's redirect listener
  // (registered via app.json's "scheme") catches that final hop.
  const [request, , promptAsync] = AuthSession.useAuthRequest(
    {
      clientId: GOOGLE_CLIENT_ID,
      scopes: ['openid', 'profile', 'email'],
      redirectUri: `${API_BASE_URL}/oauth/google/redirect`,
      responseType: AuthSession.ResponseType.IdToken,
      extraParams: { nonce },
    },
    GOOGLE_DISCOVERY
  );

  const onSubmit = async () => {
    setSubmitting(true);
    const result = await login(email, password, companyCode, remember);
    setSubmitting(false);
    if (!result.ok) {
      Alert.alert('Login failed', result.error);
      return;
    }
    // On success the root navigator will swap to the app stack.
  };

  const onGoogleLogin = async () => {
    if (!GOOGLE_CLIENT_ID) {
      Alert.alert('Not set up yet', 'Google sign-in has not been configured for this build.');
      return;
    }
    if (!companyCode.trim()) {
      Alert.alert('Almost there', 'Enter your company code first, then continue with Google.');
      return;
    }
    setGoogleSubmitting(true);
    try {
      const result = await promptAsync();
      if (result.type !== 'success' || !result.params.id_token) {
        setGoogleSubmitting(false);
        return;
      }
      const authResult = await loginWithGoogle(companyCode, result.params.id_token);
      setGoogleSubmitting(false);
      if (!authResult.ok) {
        Alert.alert('Google sign-in failed', authResult.error);
      }
      // On success the root navigator will swap to the app stack.
    } catch {
      setGoogleSubmitting(false);
      Alert.alert('Google sign-in failed', 'Something went wrong. Please try again.');
    }
  };

  return (
    <ImageBackground
      source={require('../../assets/login-bg.jpg')}
      style={styles.bg}
      resizeMode="cover"
    >
      <StatusBar style="light" />
      <View style={styles.wash} />
      <SafeAreaView style={styles.safe}>
        <KeyboardAvoidingView
          style={{ flex: 1 }}
          behavior="padding"
        >
          <ScrollView
            contentContainerStyle={styles.scroll}
            keyboardShouldPersistTaps="handled"
            showsVerticalScrollIndicator={false}
          >
            {/* The frosted glass card. expo-blur renders a real iOS-style
                blur; on Android it falls back to a translucent fill. */}
            <BlurView intensity={25} tint="light" style={styles.card}>
              <View style={styles.cardInner}>
                {/* Wordmark -- used here instead of a separate logo image */}
                <Text style={styles.wordmark}>VisiLog</Text>
                <Text style={styles.tagline}>
                  Visitor Management & Reception Operations
                </Text>

                <Segmented
                  value="signin"
                  onChange={(v) => {
                    if (v === 'register') navigation.navigate('Signup');
                  }}
                  options={[
                    { label: 'Sign in', value: 'signin' },
                    { label: 'Register', value: 'register' },
                  ]}
                  style={{ marginBottom: spacing.lg }}
                />

                <Text style={styles.heading}>Login</Text>
                <Text style={styles.subheading}>
                  Welcome back. Please sign in to continue.
                </Text>

                {/* Company code -- resolves which organization this login is for */}
                <View style={styles.fieldRow}>
                  <Ionicons name="business-outline" size={18} color="rgba(255,255,255,0.85)" />
                  <TextInput
                    value={companyCode}
                    onChangeText={setCompanyCode}
                    placeholder="Company code"
                    placeholderTextColor="rgba(255,255,255,0.65)"
                    autoCapitalize="characters"
                    style={styles.input}
                  />
                </View>

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

                {/* Remember me / Forgot password */}
                <View style={styles.rememberRow}>
                  <Pressable style={styles.remember} onPress={() => setRemember((r) => !r)}>
                    <View style={[styles.checkbox, remember && styles.checkboxOn]}>
                      {remember ? <Ionicons name="checkmark" size={14} color="#FFF" /> : null}
                    </View>
                    <Text style={styles.rememberText}>Remember me</Text>
                  </Pressable>
                  <Pressable onPress={() => navigation.navigate('ForgotPassword')} hitSlop={6}>
                    <Text style={styles.forgotText}>Forgot password?</Text>
                  </Pressable>
                </View>

                {/* Gradient login button */}
                <Pressable onPress={onSubmit} disabled={submitting} style={({ pressed }) => [
                  { opacity: pressed || submitting ? 0.85 : 1 },
                ]}>
                  <LinearGradient
                    colors={['#5ECFC9', '#1B8A82', '#0B4A47']}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={styles.loginBtn}
                  >
                    <Text style={styles.loginBtnText}>
                      {submitting ? 'Signing in...' : 'Login'}
                    </Text>
                  </LinearGradient>
                </Pressable>

                {/* Google sign-in -- verified server-side, see GoogleTokenService */}
                <Pressable
                  onPress={onGoogleLogin}
                  disabled={!request || googleSubmitting}
                  style={({ pressed }) => [styles.googleBtn, { opacity: pressed || googleSubmitting ? 0.85 : 1 }]}
                >
                  <Ionicons name="logo-google" size={18} color="#FFFFFF" />
                  <Text style={styles.googleBtnText}>
                    {googleSubmitting ? 'Signing in...' : 'Continue with Google'}
                  </Text>
                </Pressable>

                {/* Signup */}
                <View style={styles.signupRow}>
                  <Text style={styles.signupHint}>Don&apos;t have an account?{' '}</Text>
                  <Pressable onPress={() => navigation.navigate('Signup')} hitSlop={6}>
                    <Text style={styles.signupLink}>Signup</Text>
                  </Pressable>
                </View>

                {/* New company */}
                <View style={[styles.signupRow, styles.newCompanyRow]}>
                  <Text style={styles.signupHint}>Setting up VisiLog for your company?{' '}</Text>
                  <Pressable onPress={() => navigation.navigate('RegisterCompany')} hitSlop={6}>
                    <Text style={styles.signupLink}>Register your company</Text>
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
    backgroundColor: Platform.OS === 'android' ? 'rgba(255,255,255,0.12)' : 'rgba(255,255,255,0.05)',
  },

  // Branding inside the card
  wordmark: {
    fontFamily: fonts.displayExtra,
    fontSize: 32,
    lineHeight: 40,
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

  // Form fields -- translucent so the glass shows through
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

  // Remember me / Forgot password
  rememberRow: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    marginVertical: spacing.sm,
  },
  remember: { flexDirection: 'row', alignItems: 'center' },
  forgotText: { fontFamily: fonts.medium, fontSize: 13, color: '#FFFFFF', textDecorationLine: 'underline' },
  checkbox: {
    width: 18, height: 18, borderRadius: 5,
    borderWidth: 1.5, borderColor: 'rgba(255,255,255,0.85)',
    alignItems: 'center', justifyContent: 'center',
    marginRight: 8,
  },
  checkboxOn: { backgroundColor: '#2E9E96', borderColor: '#2E9E96' },
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

  // Google button
  googleBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    height: 48,
    borderRadius: radius.md,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.35)',
    backgroundColor: 'rgba(255,255,255,0.10)',
    marginTop: spacing.sm,
    gap: 8,
  },
  googleBtnText: { fontFamily: fonts.medium, fontSize: 14, color: '#FFFFFF' },

  // Signup -- flexWrap so long copy ("Setting up VisiLog for your
  // company? Register your company") breaks onto its own centered line
  // on narrow phones instead of the two Text nodes bunching together.
  signupRow: {
    flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'center',
    marginTop: spacing.lg, paddingHorizontal: spacing.sm,
  },
  newCompanyRow: { marginTop: spacing.sm },
  signupHint: {
    fontFamily: fonts.regular, fontSize: 13, lineHeight: 20,
    color: 'rgba(255,255,255,0.85)', textAlign: 'center',
  },
  signupLink: { fontFamily: fonts.bold, fontSize: 13, lineHeight: 20, color: '#FFFFFF' },

  footer: {
    fontFamily: fonts.medium,
    fontSize: 11,
    color: 'rgba(255,255,255,0.75)',
    textAlign: 'center',
    marginTop: spacing.xl,
    letterSpacing: 0.5,
  },
});