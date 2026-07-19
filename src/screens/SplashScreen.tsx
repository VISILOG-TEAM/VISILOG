import React from 'react';
import { View, Image, ImageBackground, StyleSheet } from 'react-native';
import { StatusBar } from 'expo-status-bar';

// SplashScreen — shown for a fixed window on cold start (see App.js,
// which owns the 7s timer). Uses the exact same background photo as
// Login/Signup/RegisterCompany (see assets/login-bg-plum.webp) so onboarding
// reads as one continuous, matching experience instead of a splash that
// looks like a different app. assets/logo.png already bakes in the
// icon, "VisiLog" wordmark, and tagline as one image, so there's no
// separate text here duplicating any of it.
export default function SplashScreen() {
  return (
    <ImageBackground
      source={require('../../assets/login-bg-plum.webp')}
      style={styles.bg}
      resizeMode="cover"
    >
      <StatusBar style="light" />
      <View style={styles.wash} />
      <View style={styles.center}>
        <Image
          source={require('../../assets/logo.png')}
          style={styles.logo}
          resizeMode="contain"
        />
      </View>
    </ImageBackground>
  );
}

const styles = StyleSheet.create({
  bg: { flex: 1, backgroundColor: '#0E4E55' },
  wash: { ...StyleSheet.absoluteFillObject, backgroundColor: 'rgba(8, 30, 36, 0.25)' },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  logo: {
    width: '100%',
    height: '75%',
    maxWidth: 560,
  },
});
