import 'react-native-url-polyfill/auto';
import React, { useEffect, useState } from 'react';
import { StatusBar } from 'expo-status-bar';
import { NavigationContainer, DefaultTheme, DarkTheme } from '@react-navigation/native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import {
  useFonts,
  Sora_400Regular, Sora_600SemiBold, Sora_700Bold, Sora_800ExtraBold,
} from '@expo-google-fonts/sora';
import {
  Inter_400Regular, Inter_500Medium, Inter_600SemiBold, Inter_700Bold,
} from '@expo-google-fonts/inter';

import { AuthProvider } from './src/context/AuthContext';
import { DataProvider } from './src/context/DataContext';
import { ThemeProvider, useTheme } from './src/theme/ThemeContext';
import RootNavigator from './src/navigation/RootNavigator';
import SplashScreen from './src/screens/SplashScreen';

const SPLASH_DURATION_MS = 7000;

// App entry point.
// Order of providers matters: AuthProvider must wrap RootNavigator
// because the navigator reads useAuth() to decide which stack to show.
export default function App() {
  // Load the two webfonts, and separately hold the splash screen up for
  // a fixed window so the branding always gets its full 7 seconds even
  // if fonts load instantly (e.g. on web).
  const [fontsLoaded] = useFonts({
    Sora_400Regular, Sora_600SemiBold, Sora_700Bold, Sora_800ExtraBold,
    Inter_400Regular, Inter_500Medium, Inter_600SemiBold, Inter_700Bold,
  });
  const [splashElapsed, setSplashElapsed] = useState(false);

  useEffect(() => {
    const t = setTimeout(() => setSplashElapsed(true), SPLASH_DURATION_MS);
    return () => clearTimeout(t);
  }, []);

  if (!fontsLoaded || !splashElapsed) {
    return <SplashScreen />;
  }

  return (
    <SafeAreaProvider>
      <ThemeProvider>
        <AppContent />
      </ThemeProvider>
    </SafeAreaProvider>
  );
}

// Reads the active theme, so it must live inside ThemeProvider rather
// than in App() itself -- drives both the OS status bar icon color and
// React Navigation's own screen-transition background/text colors.
function AppContent() {
  const { colors, dark } = useTheme();
  const navTheme = {
    ...(dark ? DarkTheme : DefaultTheme),
    colors: {
      ...(dark ? DarkTheme : DefaultTheme).colors,
      primary: colors.primary,
      background: colors.background,
      card: colors.surface,
      text: colors.textPrimary,
      border: colors.border,
    },
  };
  return (
    <AuthProvider>
      <DataProvider>
        <NavigationContainer theme={navTheme}>
          <StatusBar style={dark ? 'light' : 'dark'} />
          <RootNavigator />
        </NavigationContainer>
      </DataProvider>
    </AuthProvider>
  );
}