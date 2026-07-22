import React from 'react';
import { View, Image, StyleSheet } from 'react-native';
import { StatusBar } from 'expo-status-bar';

// SplashScreen -- shown for a fixed window on cold start (see App.js,
// which owns the 7s timer). A solid dark background rather than the
// login photo, by design -- Login/Signup/RegisterCompany keep the
// photo background (see assets/login-bg.jpg). assets/logo.png already
// bakes in the icon, "VisiLog" wordmark, and tagline as one image, so
// there's no separate text here duplicating any of it.
export default function SplashScreen() {
  return (
    <View style={styles.bg}>
      <StatusBar style="light" />
      <View style={styles.center}>
        <Image
          source={require('../../assets/logo.png')}
          style={styles.logo}
          resizeMode="contain"
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  bg: { flex: 1, backgroundColor: '#172326' },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  logo: {
    width: '100%',
    height: '75%',
    maxWidth: 560,
  },
});
