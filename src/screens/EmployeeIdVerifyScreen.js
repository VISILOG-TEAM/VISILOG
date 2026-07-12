import React, { useState } from 'react';
import { View, StyleSheet, Pressable, TextInput } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { AuthBackground, Text } from '../components';
import { fonts } from '../theme/typography';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';

// EmployeeIdVerifyScreen — shown once a signed-in user picks
// "Receptionist" on RoleSelectScreen. Stands in for "the app checks
// the company database": validates the typed ID against the mock
// employee directory (see AuthContext.verifyReceptionistId) and
// requires the match to be in the Reception department.
export default function EmployeeIdVerifyScreen() {
  const { verifyReceptionistId, logout } = useAuth();
  const [employeeId, setEmployeeId] = useState('');
  const [error, setError] = useState('');
  const [checking, setChecking] = useState(false);

  const onSubmit = () => {
    if (!employeeId.trim()) {
      setError('Enter your employee ID.');
      return;
    }
    setChecking(true);
    const result = verifyReceptionistId(employeeId);
    setChecking(false);
    if (!result.ok) {
      setError(result.error);
    }
  };

  return (
    <AuthBackground>
      <View style={styles.wrap}>
        <View style={styles.iconWrap}>
          <Ionicons name="finger-print-outline" size={40} color="#D4AF37" />
        </View>
        <Text style={styles.heading}>Confirm your employee ID</Text>
        <Text style={styles.subheading}>
          We’ll check this against the staff directory to confirm you’re registered as a
          receptionist.
        </Text>

        <View style={styles.fieldRow}>
          <Ionicons name="card-outline" size={18} color="rgba(255,255,255,0.85)" />
          <TextInput
            value={employeeId}
            onChangeText={(t) => { setEmployeeId(t); setError(''); }}
            placeholder="e.g. VRA-1004"
            placeholderTextColor="rgba(255,255,255,0.65)"
            autoCapitalize="characters"
            style={styles.input}
          />
        </View>
        {error ? <Text style={styles.error}>{error}</Text> : null}

        <Pressable onPress={onSubmit} disabled={checking} style={styles.submitBtn}>
          <Text style={styles.submitBtnText}>{checking ? 'Checking…' : 'Confirm'}</Text>
        </Pressable>

        <Pressable onPress={() => logout()} style={{ marginTop: spacing.md }}>
          <Text style={styles.backLink}>Not a receptionist? Sign out</Text>
        </Pressable>
      </View>
    </AuthBackground>
  );
}

const styles = StyleSheet.create({
  wrap: { flex: 1, justifyContent: 'center', paddingHorizontal: spacing.lg },
  iconWrap: {
    width: 72, height: 72, borderRadius: 20,
    borderWidth: 1.5, borderColor: 'rgba(212,175,55,0.5)',
    backgroundColor: 'rgba(212,175,55,0.10)',
    alignItems: 'center', justifyContent: 'center',
    alignSelf: 'center', marginBottom: spacing.lg,
  },
  heading: {
    fontFamily: fonts.displayBold, fontSize: 22, color: '#FFFFFF',
    textAlign: 'center', marginBottom: 6,
  },
  subheading: {
    fontFamily: fonts.regular, fontSize: 13, color: 'rgba(255,255,255,0.8)',
    textAlign: 'center', marginBottom: spacing.xl, lineHeight: 19,
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
  },
  input: {
    flex: 1, fontFamily: fonts.regular, fontSize: 15, color: '#FFFFFF',
    marginHorizontal: 8, paddingVertical: 0,
  },
  error: { fontFamily: fonts.medium, fontSize: 12, color: '#F5A3A3', marginTop: 8 },
  submitBtn: {
    height: 50, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center',
    marginTop: spacing.lg, backgroundColor: '#D4AF37',
  },
  submitBtnText: { fontFamily: fonts.bold, fontSize: 16, color: '#1B3324' },
  backLink: {
    fontFamily: fonts.medium, fontSize: 12, color: 'rgba(255,255,255,0.75)',
    textAlign: 'center', textDecorationLine: 'underline',
  },
});
