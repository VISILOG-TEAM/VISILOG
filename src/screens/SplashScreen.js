import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { AuthBackground, Text } from '../components';
import { fonts } from '../theme/typography';

// SplashScreen — shown for a fixed window on cold start (see App.js,
// which owns the 7s timer). Purely presentational: a big gold mark +
// wordmark on the shared onboarding background.
export default function SplashScreen() {
  return (
    <AuthBackground>
      <View style={styles.center}>
        <View style={styles.badge}>
          <Ionicons name="shield-checkmark" size={56} color="#D4AF37" />
        </View>
        <Text style={styles.wordmark}>VisiLog</Text>
        <Text style={styles.tagline}>Visitor Management & Reception Operations</Text>
      </View>
    </AuthBackground>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  badge: {
    width: 96, height: 96, borderRadius: 24,
    borderWidth: 2, borderColor: 'rgba(212,175,55,0.55)',
    alignItems: 'center', justifyContent: 'center',
    marginBottom: 20,
    backgroundColor: 'rgba(212,175,55,0.08)',
  },
  wordmark: {
    fontFamily: fonts.displayExtra,
    fontSize: 36,
    color: '#FFFFFF',
    letterSpacing: -0.5,
  },
  tagline: {
    fontFamily: fonts.medium,
    fontSize: 12,
    color: 'rgba(255,255,255,0.8)',
    marginTop: 4,
  },
});
