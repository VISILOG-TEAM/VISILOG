import React from 'react';
import { StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { StatusBar } from 'expo-status-bar';

// Shared background for every pre-app screen (Splash, Login, Signup,
// RoleSelect) so the onboarding flow reads as one continuous experience.
// A code-built gradient rather than a photo — deep emerald fading to
// near-black, with a soft gold diagonal glow layered on top.
export default function AuthBackground({ children, style }) {
  return (
    <LinearGradient
      colors={['#155636', '#0A2A1D', '#081C13']}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={[styles.bg, style]}
    >
      <StatusBar style="light" />
      <LinearGradient
        colors={['rgba(212,175,55,0.30)', 'rgba(212,175,55,0)']}
        start={{ x: 0, y: 0 }}
        end={{ x: 0.65, y: 0.55 }}
        style={StyleSheet.absoluteFillObject}
        pointerEvents="none"
      />
      {children}
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  bg: { flex: 1 },
});
