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
import { useData } from '../context/DataContext';
import { fonts } from '../theme/typography';
import { spacing, radius } from '../theme/spacing';

// Signup uses the exact same backdrop and glass card style as Login, so
// the two pages feel like one continuous flow.
export default function SignupScreen({ navigation }) {
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const { login } = useAuth();
  const { registerVisitorAccount } = useData();

  const onSubmit = () => {
    if (!fullName.trim() || !email.trim() || !password) {
      Alert.alert('Almost there', 'Please fill in every field above.');
      return;
    }
    if (password !== confirm) {
      Alert.alert('Passwords don\u2019t match', 'Please re-enter the same password twice.');
      return;
    }
    // Create the visitor account and immediately log them in.
    registerVisitorAccount({ fullName, email, password });
    login(email, password);
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
            {/* Back chevron */}
            <Pressable onPress={() => navigation.goBack()} style={styles.back} hitSlop={8}>
              <Ionicons name="chevron-back" size={22} color="#FFFFFF" />
            </Pressable>

            <BlurView intensity={40} tint="light" style={styles.card}>
              <View style={styles.cardInner}>
                <Text style={styles.wordmark}>VisiLog</Text>
                <Text style={styles.heading}>Create account</Text>
                <Text style={styles.subheading}>
                  Request access to the reception system.
                </Text>

                <Field icon="person-outline" placeholder="Full name" value={fullName} onChangeText={setFullName} />
                <Field icon="mail-outline" placeholder="Email address" value={email} onChangeText={setEmail}
                  autoCapitalize="none" keyboardType="email-address" />
                <Field icon="lock-closed-outline" placeholder="Password" value={password} onChangeText={setPassword}
                  secureTextEntry />
                <Field icon="shield-checkmark-outline" placeholder="Confirm password" value={confirm} onChangeText={setConfirm}
                  secureTextEntry />

                <Pressable onPress={onSubmit} style={({ pressed }) => [{ opacity: pressed ? 0.85 : 1 }]}>
                  <LinearGradient
                    colors={['#A7F37A', '#16A34A', '#0E9F8E']}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 1 }}
                    style={styles.signupBtn}
                  >
                    <Text style={styles.signupBtnText}>Create account</Text>
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
    </ImageBackground>
  );
}

// Small internal field component to keep the JSX above readable. Local
// because it's only used on this screen.
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

  wordmark: { fontFamily: fonts.displayExtra, fontSize: 28, color: '#FFFFFF', textAlign: 'center', marginBottom: spacing.md },
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

  signupBtn: {
    height: 50, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center',
    marginTop: spacing.sm,
  },
  signupBtnText: { fontFamily: fonts.bold, fontSize: 16, color: '#FFFFFF', letterSpacing: 0.3 },

  loginRow: { flexDirection: 'row', justifyContent: 'center', marginTop: spacing.lg },
  loginHint: { fontFamily: fonts.regular, fontSize: 13, color: 'rgba(255,255,255,0.85)' },
  loginLink: { fontFamily: fonts.bold, fontSize: 13, color: '#FFFFFF' },
});
