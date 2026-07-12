import React from 'react';
import { StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { StatusBar } from 'expo-status-bar';

// Shared background for every pre-app screen (Splash, Login, Signup,
// RoleSelect, employee-ID verify) so the onboarding flow reads as one
// continuous experience. A code-built gradient rather than a photo —
// deep emerald fading to near-black, with a soft gold diagonal glow
// layered on top.
//
// Splash/Login/Signup show before an organization is known, so they
// always use the default VRA-green gradient below. Screens that run
// *after* a successful company-code login (RoleSelect, ID-verify) pass
// `gradientColors`/`accentColor` from the live org theme instead, so
// onboarding reflects the signed-in tenant's brand.
export default function AuthBackground({
  children,
  style,
  gradientColors = ['#155636', '#0A2A1D', '#081C13'],
  accentColor = '212,175,55',
}) {
  return (
    <LinearGradient
      colors={gradientColors}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={[styles.bg, style]}
    >
      <StatusBar style="light" />
      <LinearGradient
        colors={[`rgba(${accentColor},0.30)`, `rgba(${accentColor},0)`]}
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
