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
import { fonts } from '../theme/typography';
import { spacing, radius } from '../theme/spacing';

// RegisterCompanyScreen — the self-serve "sign your company up" entry
// point. Only *collects* the form here — a company can't actually use
// VisiLog (and doesn't get a company code) until the admin has agreed
// to the legal terms and gone through the subscription step on
// LegalAgreementScreen, which is what actually calls registerCompany().
export default function RegisterCompanyScreen({ navigation }) {
  const [companyName, setCompanyName] = useState('');
  const [adminName, setAdminName] = useState('');
  const [adminEmail, setAdminEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');

  const onSubmit = () => {
    if (!companyName.trim() || !adminName.trim() || !adminEmail.trim() || !password) {
      Alert.alert('Almost there', 'Please fill in every field above.');
      return;
    }
    if (password.length < 8) {
      Alert.alert('Password too short', 'Your password must be at least 8 characters.');
      return;
    }
    if (password !== confirm) {
      Alert.alert('Passwords don’t match', 'Please re-enter the same password twice.');
      return;
    }
    navigation.navigate('LegalAgreement', {
      pending: {
        companyName: companyName.trim(),
        adminName: adminName.trim(),
        adminEmail: adminEmail.trim(),
        password,
      },
    });
  };

  return (
    <ImageBackground
      source={require('../../assets/login-bg-plum.webp')}
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

            <BlurView intensity={25} tint="light" style={styles.card}>
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
                <Text style={styles.passwordHint}>Must be at least 8 characters.</Text>
                <Field icon="shield-checkmark-outline" placeholder="Confirm password" value={confirm} onChangeText={setConfirm}
                  secureTextEntry />

                <Pressable onPress={onSubmit} style={({ pressed }) => [{ opacity: pressed ? 0.85 : 1 }]}>
                  <LinearGradient
                    colors={['#F0D998', '#D4AF37', '#A9791B']}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={styles.submitBtn}
                  >
                    <Text style={styles.submitBtnText}>Continue</Text>
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

function Field({ icon, secureTextEntry, ...inputProps }) {
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
  bg: { flex: 1, backgroundColor: '#0E4E55' },
  wash: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(8, 30, 36, 0.25)' },
  safe: { flex: 1 },
  scroll: { flexGrow: 1, justifyContent: 'center', paddingHorizontal: spacing.lg, paddingVertical: spacing.xxl },

  back: { position: 'absolute', top: spacing.sm, left: spacing.sm, padding: 8, zIndex: 1 },

  card: { borderRadius: radius.xl, overflow: 'hidden', borderWidth: 1, borderColor: 'rgba(255,255,255,0.35)' },
  cardInner: {
    padding: spacing.xl,
    backgroundColor: Platform.OS === 'android' ? 'rgba(255,255,255,0.12)' : 'rgba(255,255,255,0.05)',
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
  passwordHint: {
    fontFamily: fonts.regular, fontSize: 11, color: 'rgba(255,255,255,0.7)',
    marginTop: -6, marginBottom: spacing.sm,
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
