# VisiLog - dark-mode brand legibility, themed avatars, red close buttons, text removals
# Run from the repository root.
$ErrorActionPreference = 'Stop'

$content = @'
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
  heading: { fontFamily: fonts.displayBold, fontSize: 24, color: '#FFFFFF' },
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

'@
$path = Join-Path (Get-Location) 'src\screens\SignupScreen.tsx'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/SignupScreen.tsx'

$content = @'
import React, { useEffect, useState } from 'react';
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
    GOOGLE_DISCOVERY,
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
    <View style={styles.bg}>
      <StatusBar style="light" />
      <SafeAreaView style={styles.safe}>
        <KeyboardAvoidingView style={{ flex: 1 }} behavior="padding">
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
                <Text style={styles.tagline}>Visitor Management & Reception Operations</Text>

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
                <Text style={styles.subheading}>Welcome back. Please sign in to continue.</Text>

                {/* The company you belong to -- resolves which organization this
                    login is for. Labelled "Company name" because that IS the
                    code for companies registered from now on (see
                    AuthService.generateUniqueCompanyCode); the backend strips
                    spaces and punctuation so "Acme Logistics" and
                    "ACMELOGISTICS" both resolve. */}
                <View style={styles.fieldRow}>
                  <Ionicons name="business-outline" size={18} color="rgba(255,255,255,0.85)" />
                  <TextInput
                    value={companyCode}
                    onChangeText={setCompanyCode}
                    placeholder="Company name"
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
                <Pressable
                  onPress={onSubmit}
                  disabled={submitting}
                  style={({ pressed }) => [{ opacity: pressed || submitting ? 0.85 : 1 }]}
                >
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
                  style={({ pressed }) => [
                    styles.googleBtn,
                    { opacity: pressed || googleSubmitting ? 0.85 : 1 },
                  ]}
                >
                  <Ionicons name="logo-google" size={18} color="#FFFFFF" />
                  <Text style={styles.googleBtnText}>
                    {googleSubmitting ? 'Signing in...' : 'Continue with Google'}
                  </Text>
                </Pressable>

                {/* Signup */}
                <View style={styles.signupRow}>
                  <Text style={styles.signupHint}>Don&apos;t have an account? </Text>
                  <Pressable onPress={() => navigation.navigate('Signup')} hitSlop={6}>
                    <Text style={styles.signupLink}>Signup</Text>
                  </Pressable>
                </View>

                {/* New company */}
                <View style={[styles.signupRow, styles.newCompanyRow]}>
                  <Text style={styles.signupHint}>Setting up VisiLog for your company? </Text>
                  <Pressable onPress={() => navigation.navigate('RegisterCompany')} hitSlop={6}>
                    <Text style={styles.signupLink}>Register your company</Text>
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
    backgroundColor:
      Platform.OS === 'android' ? 'rgba(255,255,255,0.12)' : 'rgba(255,255,255,0.05)',
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
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginVertical: spacing.sm,
  },
  remember: { flexDirection: 'row', alignItems: 'center' },
  forgotText: {
    fontFamily: fonts.medium,
    fontSize: 13,
    color: '#FFFFFF',
    textDecorationLine: 'underline',
  },
  checkbox: {
    width: 18,
    height: 18,
    borderRadius: 5,
    borderWidth: 1.5,
    borderColor: 'rgba(255,255,255,0.85)',
    alignItems: 'center',
    justifyContent: 'center',
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
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    marginTop: spacing.lg,
    paddingHorizontal: spacing.sm,
  },
  newCompanyRow: { marginTop: spacing.sm },
  signupHint: {
    fontFamily: fonts.regular,
    fontSize: 13,
    lineHeight: 20,
    color: 'rgba(255,255,255,0.85)',
    textAlign: 'center',
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

'@
$path = Join-Path (Get-Location) 'src\screens\LoginScreen.tsx'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/screens/LoginScreen.tsx'

$content = @'
// VisiLog color system
// -------------------------------------------------------------
// Brand identity: a deep institutional emerald green paired with a
// gold accent (the "access-granted / tap" colour) -- VRA's default.
// Functional status colours stay conventional (green / amber / red)
// so a receptionist can never misread a visitor's state at a glance
// -- kept distinct from any brand colour so the two don't get confused.
//
// buildColors(brandTheme, dark) makes this both multi-tenant and
// light/dark-aware: each Organization carries its own {brand, primary,
// ...} shades, and ThemeContext calls this factory with the signed-in
// user's org (and the current light/dark mode) to produce that org's
// full colors object. Status hues and the brand shades themselves stay
// the same hex in both modes (they're already saturated enough to read
// on a dark background); only neutrals/surfaces and the tint-derived
// primarySurface/primarySurfaceStrong swap per mode.

// An organization's brand shades, as returned by the backend's
// OrganizationDto.theme (see AuthContext) or one of Company Setup's
// preset palettes. These are computed for a light background --
// buildColors derives dark-mode-appropriate tinted surfaces from
// `primary` rather than using primarySurface/primarySurfaceStrong
// as-is when dark=true (see mix() below).
export interface BrandTheme {
  brand: string;
  brandDark: string;
  brandTint: string;
  primary: string;
  primaryPressed: string;
  primarySurface: string;
  primarySurfaceStrong: string;
}

export interface StatusColorSet {
  solid: string;
  bg: string;
  fg: string;
}

export type StatusKey =
  | 'onsite'
  | 'success'
  | 'pending'
  | 'rejected'
  | 'error'
  | 'info'
  | 'neutral';

export interface Colors extends BrandTheme {
  background: string;
  surface: string;
  surfaceAlt: string;

  textPrimary: string;
  textSecondary: string;
  textMuted: string;
  textInverse: string;

  border: string;
  borderStrong: string;

  status: Record<StatusKey, StatusColorSet>;

  palette: typeof palette;
}

const palette = {
  // Brand emerald green (VRA default)
  emerald900: '#0A2A1D', // deepest -- primary text on light surfaces
  emerald800: '#0F3D2A', // brand ink -- nav bars, dark surfaces, logo
  emerald700: '#155636',
  emerald600: '#1D7248',

  // Gold accent (VRA default)
  gold600: '#C9A227', // primary action colour
  gold500: '#D4AF37', // pressed / hover
  gold100: '#F5E6BC',
  gold050: '#FBF3DE',

  // Cool, lobby-clean neutrals (light mode)
  slate900: '#0F172A',
  slate700: '#334155',
  slate500: '#64748B',
  slate400: '#94A3B8',
  slate300: '#CBD5E1',
  slate200: '#E2E8F0',
  slate100: '#EEF2F7',
  slate050: '#F5F7FA',

  white: '#FFFFFF',
  black: '#000000',

  // Status families (high-clarity, conventional) -- solid/fg shared by
  // both modes, bg differs (see LIGHT_STATUS_BG/DARK_STATUS_BG below).
  green600: '#16A34A',
  green100: '#DCFCE7',
  greenDarkBg: '#123322',
  greenDarkFg: '#4ADE80',
  amber600: '#D97706',
  amber100: '#FEF3C7',
  amberDarkBg: '#3A2A0C',
  amberDarkFg: '#FBBF24',
  red600: '#DC2626',
  red100: '#FEE2E2',
  redDarkBg: '#3A1414',
  redDarkFg: '#F87171',
  blue600: '#2563EB',
  blue100: '#DBEAFE',
  blueDarkBg: '#122A4A',
  blueDarkFg: '#60A5FA',

  // Deep, near-black neutrals (dark mode). Deliberately neutral slate,
  // NOT brand-tinted: an earlier green-tinted set made the whole app
  // read as "dark green UI" rather than a dark theme. Brand identity in
  // dark mode comes from the gold/primary accents on buttons, chips and
  // highlights -- the surfaces underneath stay neutral so those accents
  // actually pop instead of blending into a green wash.
  ink900: '#0F1214', // background
  ink800: '#171B1F', // surface
  ink700: '#20262B', // surfaceAlt
  ink600: '#2C333A', // border
  ink500: '#3D454E', // borderStrong
  mist100: '#F2F4F6', // textPrimary
  mist300: '#AEB6BF', // textSecondary
  mist500: '#7C858F', // textMuted
};

// VRA's own brand shades, used when no organization theme is supplied
// (e.g. before login) or as the fallback for the default tenant.
const DEFAULT_BRAND_THEME: BrandTheme = {
  brand: palette.emerald800,
  brandDark: palette.emerald900,
  brandTint: palette.emerald700,
  primary: palette.gold600,
  primaryPressed: palette.gold500,
  primarySurface: palette.gold050,
  primarySurfaceStrong: palette.gold100,
};

// Blends two "#RRGGBB" hexes -- weight is how much of `hexA` to use
// (1 = all hexA, 0 = all hexB). Used to derive a dark-mode-appropriate
// tinted surface from an org's own `primary` color, since the stored
// primarySurface/primarySurfaceStrong are pale tints computed for a
// light background and would look wrong (a near-white chip) on a dark
// one -- this way the tint always scales with whatever brand color the
// org picked, without needing a separate dark value from the backend.
const mix = (hexA: string, hexB: string, weight: number): string => {
  const a = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hexA);
  const b = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hexB);
  if (!a || !b) return hexA;
  const blend = (i: number) => {
    const av = parseInt(a[i], 16);
    const bv = parseInt(b[i], 16);
    return Math.round(av * weight + bv * (1 - weight))
      .toString(16)
      .padStart(2, '0');
  };
  return `#${blend(1)}${blend(2)}${blend(3)}`;
};

// Rough relative luminance, 0 (black) to 1 (white). Good enough to
// answer "would this read as text on a near-black surface".
const luminance = (hex: string): number => {
  const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!m) return 1;
  const [r, g, bl] = [1, 2, 3].map((i) => parseInt(m[i], 16) / 255);
  return 0.2126 * r + 0.7152 * g + 0.0722 * bl;
};

// Lifts a brand colour until it reads against the dark surfaces.
//
// An org's brand shades are authored for a WHITE background -- the
// default brand is #0F3D2A, a near-black green. Used unchanged in dark
// mode (which is what happened before) it lands almost exactly on the
// #171B1F surface behind it, so anything drawn in the brand colour --
// secondary button labels, header icons, the "Change display name"
// button -- became invisible. Rather than asking every org to supply a
// second dark palette, the colour is blended toward the light neutral
// until it clears a legibility threshold. A brand that's already light
// enough passes through untouched.
const liftForDark = (hex: string): string => {
  let out = hex;
  for (let i = 0; i < 8 && luminance(out) < 0.42; i++) {
    out = mix(palette.mist100, out, 0.2);
  }
  return out;
};

export const buildColors = (brandTheme?: BrandTheme | null, dark = false): Colors => {
  const b = brandTheme || DEFAULT_BRAND_THEME;
  return {
    // Brand shades are used as FOREGROUNDS (labels, icons) far more
    // than as fills, so in dark mode they get lifted to stay legible.
    brand: dark ? liftForDark(b.brand) : b.brand,
    brandDark: dark ? liftForDark(b.brandDark) : b.brandDark,
    brandTint: dark ? liftForDark(b.brandTint) : b.brandTint,
    // primary is the opposite: it's mostly a button FILL with white
    // text on top, so lifting it would wreck that contrast instead of
    // helping. Left as the org chose it.
    primary: b.primary,
    primaryPressed: b.primaryPressed,

    // Tinted "chip" surfaces behind icons/badges -- derived from the
    // org's own primary color against the current mode's surface, not
    // used as-is in dark mode (see mix() above).
    primarySurface: dark ? mix(b.primary, palette.ink700, 0.18) : b.primarySurface,
    primarySurfaceStrong: dark ? mix(b.primary, palette.ink700, 0.32) : b.primarySurfaceStrong,

    // Surfaces
    background: dark ? palette.ink900 : palette.slate050,
    surface: dark ? palette.ink800 : palette.white,
    surfaceAlt: dark ? palette.ink700 : palette.slate100,

    // Text
    textPrimary: dark ? palette.mist100 : palette.emerald900,
    textSecondary: dark ? palette.mist300 : palette.slate500,
    textMuted: dark ? palette.mist500 : palette.slate400,
    textInverse: palette.white,

    // Lines
    border: dark ? palette.ink600 : palette.slate200,
    borderStrong: dark ? palette.ink500 : palette.slate300,

    // Status: each key carries a fill (solid), a soft surface (bg) and a
    // readable foreground (fg) for text/icons on that surface. `solid`
    // stays the same vivid hue in both modes; `bg`/`fg` swap for
    // contrast against a dark background.
    status: {
      onsite: {
        solid: palette.green600,
        bg: dark ? palette.greenDarkBg : palette.green100,
        fg: dark ? palette.greenDarkFg : '#0B6B33',
      },
      success: {
        solid: palette.green600,
        bg: dark ? palette.greenDarkBg : palette.green100,
        fg: dark ? palette.greenDarkFg : '#0B6B33',
      },
      pending: {
        solid: palette.amber600,
        bg: dark ? palette.amberDarkBg : palette.amber100,
        fg: dark ? palette.amberDarkFg : '#92400E',
      },
      rejected: {
        solid: palette.red600,
        bg: dark ? palette.redDarkBg : palette.red100,
        fg: dark ? palette.redDarkFg : '#991B1B',
      },
      error: {
        solid: palette.red600,
        bg: dark ? palette.redDarkBg : palette.red100,
        fg: dark ? palette.redDarkFg : '#991B1B',
      },
      info: {
        solid: palette.blue600,
        bg: dark ? palette.blueDarkBg : palette.blue100,
        fg: dark ? palette.blueDarkFg : '#1E40AF',
      },
      neutral: {
        solid: palette.slate500,
        bg: dark ? palette.ink700 : palette.slate100,
        fg: dark ? palette.mist300 : palette.slate700,
      },
    },

    // Escape hatch for raw values
    palette,
  };
};

// Default/back-compat static export -- VRA's own colors, light mode.
// Used by pre-login screens before ThemeProvider has resolved the
// device's actual light/dark setting, and as the context's fallback.
export const colors = buildColors();

// "#RRGGBB" -> "r,g,b", for building rgba() strings from a org's brand
// hex shades (e.g. AuthBackground's accent glow on post-login screens).
export const hexToRgb = (hex?: string | null): string => {
  const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex || '');
  if (!m) return '212,175,55';
  return [m[1], m[2], m[3]].map((h) => parseInt(h, 16)).join(',');
};

'@
$path = Join-Path (Get-Location) 'src\theme\colors.ts'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/theme/colors.ts'

$content = @'
import React, { type ReactNode } from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import type { IoniconName } from '../types';

interface HeaderAction {
  icon: IoniconName;
  onPress?: () => void;
  badge?: number;
  /** Red treatment for an action that signs you out of the app. Matches
   *  the `dangerSubtle` Button variant used by Sign out in Settings, so
   *  leaving VisiLog looks the same wherever you do it. */
  danger?: boolean;
}

interface HeaderProps {
  title: string;
  subtitle?: string;
  eyebrow?: string;
  rightIcon?: IoniconName;
  onRightPress?: () => void;
  /** Unread-count badge for the single rightIcon button. */
  badge?: number;
  /** A row of icon buttons (e.g. notifications bell + logout) -- takes
   * priority over rightIcon/right when given. */
  rightActions?: HeaderAction[];
  right?: ReactNode;
  onBackPress?: () => void;
}

function ActionButton({ icon, onPress, badge, danger }: HeaderAction) {
  const { colors } = useTheme();
  // A close button is always red, whether or not the caller thought to
  // say so. Every X in this app dismisses a screen, which is the same
  // "you're leaving" action as Sign out -- and there are a dozen of
  // them across the screens, so making each one remember to opt in
  // would guarantee some of them didn't.
  const isDanger = danger || icon === 'close';
  const background = isDanger ? colors.status.error.bg : colors.surface;
  const border = isDanger ? colors.status.error.fg : colors.border;
  const foreground = isDanger ? colors.status.error.fg : colors.brand;
  return (
    <Pressable
      onPress={onPress}
      hitSlop={8}
      style={({ pressed }) => [
        styles.iconBtn,
        { backgroundColor: background, borderColor: border },
        pressed && { opacity: 0.6 },
      ]}
    >
      <Ionicons name={icon} size={20} color={foreground} />
      {badge ? (
        <View style={[styles.badge, { backgroundColor: colors.palette.red600 }]}>
          <Text variant="caption" color={colors.textInverse} style={styles.badgeText}>
            {badge > 9 ? '9+' : badge}
          </Text>
        </View>
      ) : null}
    </Pressable>
  );
}

// Consistent page header. Pass `rightIcon` (+ onRightPress, optionally
// `badge`... via rightActions) for a quick action button, `rightActions`
// for several buttons in a row, or `right` to drop in a fully custom
// element. Pass `onBackPress` for a leading back chevron on screens
// pushed onto the stack (the app hides the native header, so this is
// the only back affordance those screens get).
export default function Header({
  title,
  subtitle,
  eyebrow,
  rightIcon,
  onRightPress,
  badge,
  rightActions,
  right,
  onBackPress,
}: HeaderProps) {
  const { colors } = useTheme();
  return (
    <View style={styles.row}>
      {onBackPress ? (
        <Pressable onPress={onBackPress} hitSlop={8} style={styles.backBtn}>
          <Ionicons name="chevron-back" size={22} color={colors.brand} />
        </Pressable>
      ) : null}
      <View style={styles.left}>
        {eyebrow ? (
          <Text variant="eyebrow" color={colors.primary} style={styles.eyebrow}>
            {eyebrow}
          </Text>
        ) : null}
        <Text variant="h1">{title}</Text>
        {subtitle ? (
          <Text variant="body" color={colors.textSecondary} style={styles.subtitle}>
            {subtitle}
          </Text>
        ) : null}
      </View>

      {rightActions && rightActions.length > 0 ? (
        <View style={styles.actionsRow}>
          {rightActions.map((action, i) => (
            <View key={action.icon + i} style={i > 0 ? styles.actionsGap : undefined}>
              <ActionButton {...action} />
            </View>
          ))}
        </View>
      ) : rightIcon ? (
        <ActionButton icon={rightIcon} onPress={onRightPress} badge={badge} />
      ) : (
        right || null
      )}
    </View>
  );
}

// row/left/backBtn/eyebrow/subtitle are layout-only; iconBtn's/badge's
// color values are applied inline above from useTheme() instead.
const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    marginBottom: spacing.lg,
  },
  left: { flex: 1, paddingRight: spacing.md },
  backBtn: {
    width: 36,
    height: 36,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing.xs,
    marginTop: 2,
  },
  eyebrow: { marginBottom: 4 },
  subtitle: { marginTop: 2 },
  iconBtn: {
    width: 40,
    height: 40,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
  },
  actionsRow: { flexDirection: 'row' },
  actionsGap: { marginLeft: spacing.xs },
  badge: {
    position: 'absolute',
    top: -4,
    right: -4,
    minWidth: 16,
    height: 16,
    borderRadius: 8,
    paddingHorizontal: 3,
    alignItems: 'center',
    justifyContent: 'center',
  },
  badgeText: { fontSize: 10, lineHeight: 12 },
});

'@
$path = Join-Path (Get-Location) 'src\components\Header.tsx'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/Header.tsx'

$content = @'
import React from 'react';
import { View, Image, StyleSheet } from 'react-native';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { fonts } from '../theme/typography';

// Shows a photo when `uri` is given, otherwise coloured initials. The
// colour is derived from the name so the same person is always the same
// hue across the app.
const TINTS = [
  '#0E9F8E',
  '#2563EB',
  '#7C3AED',
  '#DB2777',
  '#D97706',
  '#0891B2',
  '#4F46E5',
  '#059669',
];

function initials(name = ''): string {
  const parts = name.trim().split(/\s+/);
  const first = parts[0]?.[0] || '';
  const second = parts[1]?.[0] || '';
  return (first + second).toUpperCase() || '?';
}

function tintFor(name = ''): string {
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = (hash * 31 + name.charCodeAt(i)) >>> 0;
  return TINTS[hash % TINTS.length];
}

interface AvatarProps {
  name?: string;
  uri?: string | null;
  size?: number;
}

export default function Avatar({ name = '', uri, size = 44 }: AvatarProps) {
  const { colors } = useTheme();
  const dim = { width: size, height: size, borderRadius: size / 2 };

  if (uri) {
    return (
      <Image source={{ uri }} style={[dim, styles.img, { backgroundColor: colors.surfaceAlt }]} />
    );
  }

  // The signed-in org's own accent, not one of the hashed TINTS above.
  // A company that sets its brand colour in Company Setup expects to
  // see it on its own people -- the hashed palette ignored the theme
  // entirely, so the profile card stayed teal-or-whatever no matter
  // what the org picked. primarySurface is already derived per light/
  // dark mode, so the initials stay legible in both.
  return (
    <View style={[dim, styles.circle, { backgroundColor: colors.primarySurface }]}>
      <Text style={{ fontFamily: fonts.displayBold, fontSize: size * 0.36, color: colors.primary }}>
        {initials(name)}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  circle: { alignItems: 'center', justifyContent: 'center' },
  img: {},
});

'@
$path = Join-Path (Get-Location) 'src\components\Avatar.tsx'
[System.IO.File]::WriteAllText($path, $content)
Write-Host '  OK  src/components/Avatar.tsx'

Write-Host ''
Write-Host 'Done. 5 files written.'
Write-Host 'Next: run   npx tsc --noEmit'
