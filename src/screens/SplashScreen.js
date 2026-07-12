import React from 'react';
import { View, Image, StyleSheet } from 'react-native';
import { AuthBackground, Text } from '../components';
import { fonts } from '../theme/typography';

// SplashScreen — shown for a fixed window on cold start (see App.js,
// which owns the 7s timer). Purely presentational: the logo + wordmark
// on the shared onboarding background.
//
// assets/logo.png is currently a generated placeholder (a plain green
// circle-on-green square) — replace that file with the real VisiLog
// logo image and this screen picks it up automatically, same path.
export default function SplashScreen() {
  return (
    <AuthBackground>
      <View style={styles.center}>
        <Image
          source={require('../../assets/logo.png')}
          style={styles.logo}
          resizeMode="contain"
        />
        <Text style={styles.wordmark}>VisiLog</Text>
        <Text style={styles.tagline}>Visitor Management & Reception Operations</Text>
      </View>
    </AuthBackground>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  logo: {
    width: 140,
    height: 140,
    marginBottom: 12,
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
