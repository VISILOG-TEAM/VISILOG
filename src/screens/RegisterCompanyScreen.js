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
import { useAuth } from '../context/AuthContext';
import { fonts } from '../theme/typography';
import { spacing, radius } from '../theme/spacing';

// RegisterCompanyScreen — the self-serve "sign your company up" entry
// point. Creates the Organization plus its first Administrator account
// in one step and hands back a company code; the admin shares that
// code with their staff and visitors afterwards (see Company Setup).
export default function RegisterCompanyScreen({ navigation }) {
  const [companyName, setCompanyName] = useState('');
  const [adminName, setAdminName] = useState('');
  const [adminEmail, setAdminEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const { registerCompany } = useAuth();

  const onSubmit = async () => {
    if (!companyName.trim() || !adminName.trim() || !adminEmail.trim() || !password) {
      Alert.alert('Almost there', 'Please fill in every field above.');
      return;
    }
    if (password !== confirm) {
      Alert.alert('Passwords don’t match', 'Please re-enter the same password twice.');
      return;
    }
    setSubmitting(true);
    const result = await registerCompany(companyName, adminName, adminEmail, password);
    setSubmitting(false);
    if (!result.ok) {
      Alert.alert('Could not register your company', result.error);
      return;
    }
    Alert.alert(
      'You’re all set',
      `${result.organization.name} is registered. Your company code is ${result.organization.code} — share it with your staff and visitors so they can sign up. You can find it again anytime in Company Setup.`
    );
    // On success the root navigator will swap to the manager tab shell.
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
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        >
          <ScrollView
            contentContainerStyle={styles.scroll}
            keyboardShouldPersistTaps="handled"
            showsVerticalScrollIndicator={false}
          >
            <Pressable onPress={() => navigation.goBack()} style={styles.back} hitSlop={8}>
              <Ionicons name="chevron-back" size={22} color="#FFFFFF" />
            </Pressable>

            <BlurView intensity={40} tint="light" style={styles.card}>
              <View style={styles.cardInner}>
                <Text style={styles.wordmark}>VisiLog</Text>
                <Text style={styles.heading}>Register your company</Text>
                <Text style={styles.subheading}>
                  Set up VisiLog for your organization. You’ll be the first
                  Administrator — add your staff roster and office details
                  afterwards in Company Setup.
                </Text>

                <Field icon="business-outline" placeholder="Company name" value={companyName} onChangeText={setCompanyName} />
                <Field icon="person-outline" placeholder="Your full name" value={adminName} onChangeText={setAdminName} />
                <Field icon="mail-outline" placeholder="Your work email" value={adminEmail} onChangeText={setAdminEmail}
                  autoCapitalize="none" keyboardType="email-address" />
                <Field icon="lock-closed-outline" placeholder="Password" value={password} onChangeText={setPassword}
                  secureTextEntry />
                <Field icon="shield-checkmark-outline" placeholder="Confirm password" value={confirm} onChangeText={setConfirm}
                  secureTextEntry />

                <Pressable onPress={onSubmit} disabled={submitting} style={({ pressed }) => [{ opacity: pressed || submitting ? 0.85 : 1 }]}>
                  <LinearGradient
                    colors={['#F0D998', '#D4AF37', '#A9791B']}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={styles.submitBtn}
                  >
                    <Text style={styles.submitBtnText}>
                      {submitting ? 'Registering…' : 'Register company'}
                    </Text>
                  </LinearGradient>
                </Pressable>

                <View style={styles.loginRow}>
                  <Text style={styles.loginHint}>Already have a company code? </Text>
                  <Pressable onPress={() => navigation.goBack()}>
                    <Text style={styles.loginLink}>Login</Text>
                  </Pressable>
                </View>
              </View>
            </BlurView>
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </ImageBackground>
  );
}

function Field({ icon, ...inputProps }) {
  return (
    <View style={styles.fieldRow}>
      <Ionicons name={icon} size={18} color="rgba(255,255,255,0.85)" />
      <TextInput
        placeholderTextColor="rgba(255,255,255,0.65)"
        style={styles.input}
        {...inputProps}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  bg: { flex: 1, backgroundColor: '#0E4E55' },
  wash: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(8, 30, 36, 0.25)' },
  safe: { flex: 1 },
  scroll: { flexGrow: 1, justifyContent: 'center', paddingHorizontal: spacing.lg, paddingVertical: spacing.xxl },

  back: { position: 'absolute', top: spacing.sm, left: spacing.sm, padding: 8, zIndex: 1 },

  card: { borderRadius: radius.xl, overflow: 'hidden', borderWidth: 1, borderColor: 'rgba(255,255,255,0.35)' },
  cardInner: {
    padding: spacing.xl,
    backgroundColor: Platform.OS === 'android' ? 'rgba(255,255,255,0.18)' : 'rgba(255,255,255,0.08)',
  },

  wordmark: { fontFamily: fonts.displayExtra, fontSize: 28, lineHeight: 36, color: '#FFFFFF', textAlign: 'center', marginBottom: spacing.md },
  heading: { fontFamily: fonts.displayBold, fontSize: 24, color: '#FFFFFF' },
  subheading: { fontFamily: fonts.regular, fontSize: 13, color: 'rgba(255,255,255,0.85)', marginBottom: spacing.lg },

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
    flex: 1, fontFamily: fonts.regular, fontSize: 15, color: '#FFFFFF',
    marginHorizontal: 8, paddingVertical: 0,
  },

  submitBtn: {
    height: 50, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center',
    marginTop: spacing.sm,
  },
  submitBtnText: { fontFamily: fonts.bold, fontSize: 16, color: '#1B3324', letterSpacing: 0.3 },

  loginRow: { flexDirection: 'row', justifyContent: 'center', marginTop: spacing.lg },
  loginHint: { fontFamily: fonts.regular, fontSize: 13, color: 'rgba(255,255,255,0.85)' },
  loginLink: { fontFamily: fonts.bold, fontSize: 13, color: '#FFFFFF' },
});
