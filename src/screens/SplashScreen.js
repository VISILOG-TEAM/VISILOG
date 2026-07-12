import React from 'react';
import { View, Image, StyleSheet } from 'react-native';
import { AuthBackground } from '../components';

// SplashScreen — shown for a fixed window on cold start (see App.js,
// which owns the 7s timer). Purely presentational: assets/logo.png
// already bakes in the icon, "VisiLog" wordmark, and tagline as one
// image, so there's no separate text here duplicating any of it.
export default function SplashScreen() {
  return (
    <AuthBackground>
      <View style={styles.center}>
        <Image
          source={require('../../assets/logo.png')}
          style={styles.logo}
          resizeMode="contain"
        />
      </View>
    </AuthBackground>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  logo: {
    width: '100%',
    height: '75%',
    maxWidth: 560,
  },
});
