# Dark mode delivery script -- writes all 49 changed/added files, then verifies.
# Run this from your VisiLog-frontend folder (the one with App.tsx and package.json in it) in PowerShell / VS Code terminal.
[Environment]::CurrentDirectory = (Get-Location).Path
Start-Transcript -Path darkmode-log.txt -Force

# --- App.tsx ---
[System.IO.File]::WriteAllText('App.tsx', @'
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
'@)

# --- src\theme\colors.ts ---
[System.IO.File]::WriteAllText('src\theme\colors.ts', @'
// VisiLog color system
// -------------------------------------------------------------
// Brand identity: a deep institutional emerald green paired with a
// gold accent (the "access-granted / tap" colour) -- VRA's default.
// Functional status colours stay conventional (green / amber / red)
// so a receptionist can never misread a visitor's state at a glance
// -- kept distinct from any brand colour so the two don't get confused.
//
// buildColors(brandTheme, dark) makes this both multi-tenant and
// light/dark-aware: each Organization carries its own {brand, primary,
// ...} shades, and ThemeContext calls this factory with the signed-in
// user's org (and the current light/dark mode) to produce that org's
// full colors object. Status hues and the brand shades themselves stay
// the same hex in both modes (they're already saturated enough to read
// on a dark background); only neutrals/surfaces and the tint-derived
// primarySurface/primarySurfaceStrong swap per mode.

// An organization's brand shades, as returned by the backend's
// OrganizationDto.theme (see AuthContext) or one of Company Setup's
// preset palettes. These are computed for a light background --
// buildColors derives dark-mode-appropriate tinted surfaces from
// `primary` rather than using primarySurface/primarySurfaceStrong
// as-is when dark=true (see mix() below).
export interface BrandTheme {
  brand: string;
  brandDark: string;
  brandTint: string;
  primary: string;
  primaryPressed: string;
  primarySurface: string;
  primarySurfaceStrong: string;
}

export interface StatusColorSet {
  solid: string;
  bg: string;
  fg: string;
}

export type StatusKey = 'onsite' | 'success' | 'pending' | 'rejected' | 'error' | 'info' | 'neutral';

export interface Colors extends BrandTheme {
  background: string;
  surface: string;
  surfaceAlt: string;

  textPrimary: string;
  textSecondary: string;
  textMuted: string;
  textInverse: string;

  border: string;
  borderStrong: string;

  status: Record<StatusKey, StatusColorSet>;

  palette: typeof palette;
}

const palette = {
  // Brand emerald green (VRA default)
  emerald900: '#0A2A1D', // deepest -- primary text on light surfaces
  emerald800: '#0F3D2A', // brand ink -- nav bars, dark surfaces, logo
  emerald700: '#155636',
  emerald600: '#1D7248',

  // Gold accent (VRA default)
  gold600: '#C9A227', // primary action colour
  gold500: '#D4AF37', // pressed / hover
  gold100: '#F5E6BC',
  gold050: '#FBF3DE',

  // Cool, lobby-clean neutrals (light mode)
  slate900: '#0F172A',
  slate700: '#334155',
  slate500: '#64748B',
  slate400: '#94A3B8',
  slate300: '#CBD5E1',
  slate200: '#E2E8F0',
  slate100: '#EEF2F7',
  slate050: '#F5F7FA',

  white: '#FFFFFF',
  black: '#000000',

  // Status families (high-clarity, conventional) -- solid/fg shared by
  // both modes, bg differs (see LIGHT_STATUS_BG/DARK_STATUS_BG below).
  green600: '#16A34A', green100: '#DCFCE7', greenDarkBg: '#123322', greenDarkFg: '#4ADE80',
  amber600: '#D97706', amber100: '#FEF3C7', amberDarkBg: '#3A2A0C', amberDarkFg: '#FBBF24',
  red600: '#DC2626', red100: '#FEE2E2', redDarkBg: '#3A1414', redDarkFg: '#F87171',
  blue600: '#2563EB', blue100: '#DBEAFE', blueDarkBg: '#122A4A', blueDarkFg: '#60A5FA',

  // Deep, near-black neutrals (dark mode) -- slightly green-tinted to
  // stay consistent with the brand rather than reading as pure grey.
  ink900: '#0B1512', // background
  ink800: '#132019', // surface
  ink700: '#1A2921', // surfaceAlt
  ink600: '#24352B', // border
  ink500: '#34493D', // borderStrong
  mist100: '#F1F5F2', // textPrimary
  mist300: '#A9B7AF', // textSecondary
  mist500: '#78877E', // textMuted
};

// VRA's own brand shades, used when no organization theme is supplied
// (e.g. before login) or as the fallback for the default tenant.
const DEFAULT_BRAND_THEME: BrandTheme = {
  brand: palette.emerald800,
  brandDark: palette.emerald900,
  brandTint: palette.emerald700,
  primary: palette.gold600,
  primaryPressed: palette.gold500,
  primarySurface: palette.gold050,
  primarySurfaceStrong: palette.gold100,
};

// Blends two "#RRGGBB" hexes -- weight is how much of `hexA` to use
// (1 = all hexA, 0 = all hexB). Used to derive a dark-mode-appropriate
// tinted surface from an org's own `primary` color, since the stored
// primarySurface/primarySurfaceStrong are pale tints computed for a
// light background and would look wrong (a near-white chip) on a dark
// one -- this way the tint always scales with whatever brand color the
// org picked, without needing a separate dark value from the backend.
const mix = (hexA: string, hexB: string, weight: number): string => {
  const a = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hexA);
  const b = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hexB);
  if (!a || !b) return hexA;
  const blend = (i: number) => {
    const av = parseInt(a[i], 16);
    const bv = parseInt(b[i], 16);
    return Math.round(av * weight + bv * (1 - weight)).toString(16).padStart(2, '0');
  };
  return `#${blend(1)}${blend(2)}${blend(3)}`;
};

export const buildColors = (brandTheme?: BrandTheme | null, dark = false): Colors => {
  const b = brandTheme || DEFAULT_BRAND_THEME;
  return {
    // Brand + primary action -- same hex in both modes (already
    // saturated enough to read on a dark background).
    brand: b.brand,
    brandDark: b.brandDark,
    brandTint: b.brandTint,
    primary: b.primary,
    primaryPressed: b.primaryPressed,

    // Tinted "chip" surfaces behind icons/badges -- derived from the
    // org's own primary color against the current mode's surface, not
    // used as-is in dark mode (see mix() above).
    primarySurface: dark ? mix(b.primary, palette.ink700, 0.18) : b.primarySurface,
    primarySurfaceStrong: dark ? mix(b.primary, palette.ink700, 0.32) : b.primarySurfaceStrong,

    // Surfaces
    background: dark ? palette.ink900 : palette.slate050,
    surface: dark ? palette.ink800 : palette.white,
    surfaceAlt: dark ? palette.ink700 : palette.slate100,

    // Text
    textPrimary: dark ? palette.mist100 : palette.emerald900,
    textSecondary: dark ? palette.mist300 : palette.slate500,
    textMuted: dark ? palette.mist500 : palette.slate400,
    textInverse: palette.white,

    // Lines
    border: dark ? palette.ink600 : palette.slate200,
    borderStrong: dark ? palette.ink500 : palette.slate300,

    // Status: each key carries a fill (solid), a soft surface (bg) and a
    // readable foreground (fg) for text/icons on that surface. `solid`
    // stays the same vivid hue in both modes; `bg`/`fg` swap for
    // contrast against a dark background.
    status: {
      onsite: {
        solid: palette.green600,
        bg: dark ? palette.greenDarkBg : palette.green100,
        fg: dark ? palette.greenDarkFg : '#0B6B33',
      },
      success: {
        solid: palette.green600,
        bg: dark ? palette.greenDarkBg : palette.green100,
        fg: dark ? palette.greenDarkFg : '#0B6B33',
      },
      pending: {
        solid: palette.amber600,
        bg: dark ? palette.amberDarkBg : palette.amber100,
        fg: dark ? palette.amberDarkFg : '#92400E',
      },
      rejected: {
        solid: palette.red600,
        bg: dark ? palette.redDarkBg : palette.red100,
        fg: dark ? palette.redDarkFg : '#991B1B',
      },
      error: {
        solid: palette.red600,
        bg: dark ? palette.redDarkBg : palette.red100,
        fg: dark ? palette.redDarkFg : '#991B1B',
      },
      info: {
        solid: palette.blue600,
        bg: dark ? palette.blueDarkBg : palette.blue100,
        fg: dark ? palette.blueDarkFg : '#1E40AF',
      },
      neutral: {
        solid: palette.slate500,
        bg: dark ? palette.ink700 : palette.slate100,
        fg: dark ? palette.mist300 : palette.slate700,
      },
    },

    // Escape hatch for raw values
    palette,
  };
};

// Default/back-compat static export -- VRA's own colors, light mode.
// Used by pre-login screens before ThemeProvider has resolved the
// device's actual light/dark setting, and as the context's fallback.
export const colors = buildColors();

// "#RRGGBB" -> "r,g,b", for building rgba() strings from a org's brand
// hex shades (e.g. AuthBackground's accent glow on post-login screens).
export const hexToRgb = (hex?: string | null): string => {
  const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex || '');
  if (!m) return '212,175,55';
  return [m[1], m[2], m[3]].map((h) => parseInt(h, 16)).join(',');
};
'@)

# --- src\theme\ThemeContext.tsx ---
[System.IO.File]::WriteAllText('src\theme\ThemeContext.tsx', @'
import React, { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { useColorScheme } from 'react-native';
import { buildColors, colors as defaultColors, type BrandTheme, type Colors } from './colors';
import { loadDarkModeOverride, saveDarkModeOverride } from '../api/themePreference';

interface ThemeContextValue {
  colors: Colors;
  dark: boolean;
  setOrgTheme: (theme: BrandTheme | null) => void;
  // null = follow the device's own light/dark setting; true/false = the
  // user explicitly picked one on the Settings screen, which then wins
  // (and is remembered) until they change it again.
  setDarkOverride: (value: boolean | null) => void;
}

// ThemeContext -- makes the color palette both multi-tenant and
// light/dark-aware. `setOrgTheme` is called by AuthContext whenever the
// signed-in organization changes (login, signup, registerCompany, or
// restoring a session on boot); every screen that reads colors via
// useTheme() re-renders with that org's brand colors live, no reload
// needed. `dark` follows the device's system setting by default and
// falls back to the user's own Settings toggle once they've set one.
const ThemeContext = createContext<ThemeContextValue>({
  colors: defaultColors,
  dark: false,
  setOrgTheme: () => {},
  setDarkOverride: () => {},
});

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [orgTheme, setOrgTheme] = useState<BrandTheme | null>(null);
  const systemScheme = useColorScheme();
  const [darkOverride, setDarkOverrideState] = useState<boolean | null>(null);

  useEffect(() => {
    loadDarkModeOverride().then(setDarkOverrideState);
  }, []);

  const setDarkOverride = (value: boolean | null) => {
    setDarkOverrideState(value);
    saveDarkModeOverride(value);
  };

  const dark = darkOverride ?? systemScheme === 'dark';
  const colors = useMemo(() => buildColors(orgTheme, dark), [orgTheme, dark]);

  return (
    <ThemeContext.Provider value={{ colors, dark, setOrgTheme, setDarkOverride }}>
      {children}
    </ThemeContext.Provider>
  );
}

export const useTheme = () => useContext(ThemeContext);
'@)

# --- src\api\themePreference.ts ---
[System.IO.File]::WriteAllText('src\api\themePreference.ts', @'
import AsyncStorage from '@react-native-async-storage/async-storage';

// Persists the user's explicit dark-mode choice from Settings, if
// they've made one -- null means "not set yet, follow the device's
// own light/dark setting" (see ThemeContext).
const STORAGE_KEY = 'visilog.darkModeOverride';

export const saveDarkModeOverride = async (value: boolean | null): Promise<void> => {
  if (value === null) {
    await AsyncStorage.removeItem(STORAGE_KEY);
  } else {
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(value));
  }
};

export const loadDarkModeOverride = async (): Promise<boolean | null> => {
  const raw = await AsyncStorage.getItem(STORAGE_KEY);
  if (raw === null) return null;
  try {
    return JSON.parse(raw) as boolean;
  } catch {
    return null;
  }
};
'@)

# --- src\components\Text.tsx ---
[System.IO.File]::WriteAllText('src\components\Text.tsx', @'
import React from 'react';
import { Text as RNText, type TextProps as RNTextProps } from 'react-native';
import { typeScale, type TypeScaleVariant } from '../theme/typography';
import { useTheme } from '../theme/ThemeContext';

interface TextProps extends RNTextProps {
  variant?: TypeScaleVariant;
  color?: string;
  align?: 'auto' | 'left' | 'right' | 'center' | 'justify';
}

// One Text to rule them all: pick a typographic role with `variant`,
// and the right font/size/spacing comes from the type scale. Falls
// back to the current theme's textPrimary (light or dark) when no
// explicit `color` is passed.
export default function Text({
  variant = 'body',
  color,
  align,
  style,
  children,
  numberOfLines,
  ...rest
}: TextProps) {
  const { colors } = useTheme();
  const base = typeScale[variant] || typeScale.body;
  return (
    <RNText
      numberOfLines={numberOfLines}
      style={[base, { color: color || colors.textPrimary }, align && { textAlign: align }, style]}
      {...rest}
    >
      {children}
    </RNText>
  );
}
'@)

# --- src\components\Card.tsx ---
[System.IO.File]::WriteAllText('src\components\Card.tsx', @'
import React, { type ReactNode } from 'react';
import { View, Pressable, StyleSheet, type StyleProp, type ViewStyle } from 'react-native';
import type { StatusKey } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { shadows } from '../theme/shadows';

interface CardProps {
  children?: ReactNode;
  accent?: StatusKey;
  onPress?: () => void;
  padded?: boolean;
  elevated?: boolean;
  style?: StyleProp<ViewStyle>;
}

// Signature element: an optional coloured edge stripe that echoes the
// coloured border of a visitor pass. A visitor's status is information,
// so we encode it structurally on the card's leading edge rather than
// relying on a badge alone. Pass accent="onsite" | "pending" | "rejected" | ...
export default function Card({
  children,
  accent,
  onPress,
  padded = true,
  elevated = true,
  style,
}: CardProps) {
  const { colors } = useTheme();
  const accentColor = accent ? colors.status[accent]?.solid || colors.primary : null;

  const padStyle = padded
    ? { padding: spacing.md, ...(accentColor ? { paddingLeft: spacing.md + 6 } : null) }
    : null;

  const inner = (
    <View
      style={[
        styles.card,
        { backgroundColor: colors.surface, borderColor: colors.border },
        elevated && shadows.sm,
        padStyle,
        style,
      ]}
    >
      {accentColor ? <View style={[styles.stripe, { backgroundColor: accentColor }]} /> : null}
      {children}
    </View>
  );

  if (onPress) {
    return (
      <Pressable
        onPress={onPress}
        style={({ pressed }) => (pressed ? styles.pressed : null)}
      >
        {inner}
      </Pressable>
    );
  }
  return inner;
}

// Card background/border are neutral (identical across every
// organization's theme) but still light/dark-aware, so their actual
// color values are applied inline above from useTheme() -- this
// StyleSheet only carries the layout, not the colors themselves.
const styles = StyleSheet.create({
  card: {
    borderRadius: radius.lg,
    borderWidth: 1,
    overflow: 'hidden',
  },
  stripe: { position: 'absolute', left: 0, top: 0, bottom: 0, width: 4 },
  pressed: { transform: [{ scale: 0.99 }], opacity: 0.95 },
});
'@)

# --- src\components\Badge.tsx ---
[System.IO.File]::WriteAllText('src\components\Badge.tsx', @'
import React from 'react';
import { View, StyleSheet } from 'react-native';
import Text from './Text';
import type { StatusKey } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { radius } from '../theme/spacing';

interface BadgeProps {
  label: string;
  status?: StatusKey;
  solid?: boolean;
  dot?: boolean;
  size?: 'sm' | 'md';
}

// Status pill. `status` selects the colour family; `solid` fills it for
// high-emphasis cases. The leading dot reinforces the state for quick
// scanning (and for anyone who reads colour less easily).
export default function Badge({
  label,
  status = 'neutral',
  solid = false,
  dot = true,
  size = 'md',
}: BadgeProps) {
  const { colors } = useTheme();
  const s = colors.status[status] || colors.status.neutral;
  const small = size === 'sm';
  const textVariant = small ? 'caption' : 'label';

  if (solid) {
    return (
      <View style={[styles.pill, small && styles.pillSm, { backgroundColor: s.solid }]}>
        <Text variant={textVariant} color={colors.textInverse}>
          {label}
        </Text>
      </View>
    );
  }

  return (
    <View style={[styles.pill, small && styles.pillSm, { backgroundColor: s.bg }]}>
      {dot ? <View style={[styles.dot, { backgroundColor: s.solid }]} /> : null}
      <Text variant={textVariant} color={s.fg}>
        {label}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  pill: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: radius.pill,
  },
  pillSm: { paddingHorizontal: 8, paddingVertical: 3 },
  dot: { width: 6, height: 6, borderRadius: 3, marginRight: 6 },
});
'@)

# --- src\components\Avatar.tsx ---
[System.IO.File]::WriteAllText('src\components\Avatar.tsx', @'
import React from 'react';
import { View, Image, StyleSheet } from 'react-native';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { fonts } from '../theme/typography';

// Shows a photo when `uri` is given, otherwise coloured initials. The
// colour is derived from the name so the same person is always the same
// hue across the app.
const TINTS = ['#0E9F8E', '#2563EB', '#7C3AED', '#DB2777', '#D97706', '#0891B2', '#4F46E5', '#059669'];

function initials(name = ''): string {
  const parts = name.trim().split(/\s+/);
  const first = parts[0]?.[0] || '';
  const second = parts[1]?.[0] || '';
  return (first + second).toUpperCase() || '?';
}

function tintFor(name = ''): string {
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = (hash * 31 + name.charCodeAt(i)) >>> 0;
  return TINTS[hash % TINTS.length];
}

interface AvatarProps {
  name?: string;
  uri?: string | null;
  size?: number;
}

export default function Avatar({ name = '', uri, size = 44 }: AvatarProps) {
  const { colors } = useTheme();
  const dim = { width: size, height: size, borderRadius: size / 2 };

  if (uri) {
    return <Image source={{ uri }} style={[dim, styles.img, { backgroundColor: colors.surfaceAlt }]} />;
  }

  const tint = tintFor(name);
  return (
    <View style={[dim, styles.circle, { backgroundColor: tint + '22' }]}>
      <Text style={{ fontFamily: fonts.displayBold, fontSize: size * 0.36, color: tint }}>
        {initials(name)}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  circle: { alignItems: 'center', justifyContent: 'center' },
  img: {},
});
'@)

# --- src\components\Input.tsx ---
[System.IO.File]::WriteAllText('src\components\Input.tsx', @'
import React, { useState } from 'react';
import {
  View, TextInput, StyleSheet, Pressable,
  type KeyboardTypeOptions, type StyleProp, type ViewStyle,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import type { IoniconName } from '../types';

interface InputProps {
  label?: string;
  value: string;
  onChangeText: (text: string) => void;
  placeholder?: string;
  icon?: IoniconName;
  error?: string;
  hint?: string;
  keyboardType?: KeyboardTypeOptions;
  secureTextEntry?: boolean;
  autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters';
  multiline?: boolean;
  style?: StyleProp<ViewStyle>;
}

// Form field with a label, optional leading icon, focus highlight and an
// inline error message. Errors are specific and actionable, never vague.
export default function Input({
  label,
  value,
  onChangeText,
  placeholder,
  icon,
  error,
  hint,
  keyboardType,
  secureTextEntry,
  autoCapitalize = 'sentences',
  multiline = false,
  style,
}: InputProps) {
  const { colors } = useTheme();
  const [focused, setFocused] = useState(false);
  // Password fields get their own reveal toggle instead of the caller
  // having to wire one up on every screen -- this is a bit of state per
  // field, so it only kicks in when secureTextEntry is actually passed.
  const [revealed, setRevealed] = useState(false);
  const isPassword = !!secureTextEntry;

  return (
    <View style={[styles.wrap, style]}>
      {label ? (
        <Text variant="label" color={colors.textSecondary} style={styles.label}>
          {label}
        </Text>
      ) : null}

      <View
        style={[
          styles.field,
          { backgroundColor: colors.surface, borderColor: colors.border },
          multiline && styles.multiline,
          focused && { borderColor: colors.primary },
          error && { borderColor: colors.status.error.solid },
        ]}
      >
        {icon ? (
          <Ionicons
            name={icon}
            size={18}
            color={focused ? colors.primary : colors.textMuted}
            style={styles.icon}
          />
        ) : null}
        <TextInput
          style={[styles.input, { color: colors.textPrimary }]}
          value={value}
          onChangeText={onChangeText}
          placeholder={placeholder}
          placeholderTextColor={colors.textMuted}
          keyboardType={keyboardType}
          secureTextEntry={isPassword && !revealed}
          autoCapitalize={autoCapitalize}
          multiline={multiline}
          textAlignVertical={multiline ? 'top' : 'center'}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
        />
        {isPassword ? (
          <Pressable onPress={() => setRevealed((r) => !r)} hitSlop={8} style={styles.eyeIcon}>
            <Ionicons
              name={revealed ? 'eye-outline' : 'eye-off-outline'}
              size={18}
              color={colors.textMuted}
            />
          </Pressable>
        ) : null}
      </View>

      {error ? (
        <Text variant="caption" color={colors.status.error.solid} style={styles.error}>
          {error}
        </Text>
      ) : hint ? (
        <Text variant="caption" color={colors.textMuted} style={styles.error}>
          {hint}
        </Text>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { marginBottom: spacing.md },
  label: { marginBottom: 6 },
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    height: 48,
  },
  multiline: { height: 100, alignItems: 'flex-start', paddingTop: 12 },
  icon: { marginRight: 8 },
  eyeIcon: { marginLeft: 8 },
  input: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 15,
    paddingVertical: 0,
  },
  error: { marginTop: 4 },
});
'@)

# --- src\components\Header.tsx ---
[System.IO.File]::WriteAllText('src\components\Header.tsx', @'
import React, { type ReactNode } from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import type { IoniconName } from '../types';

interface HeaderAction {
  icon: IoniconName;
  onPress?: () => void;
  badge?: number;
}

interface HeaderProps {
  title: string;
  subtitle?: string;
  eyebrow?: string;
  rightIcon?: IoniconName;
  onRightPress?: () => void;
  /** Unread-count badge for the single rightIcon button. */
  badge?: number;
  /** A row of icon buttons (e.g. notifications bell + logout) -- takes
   * priority over rightIcon/right when given. */
  rightActions?: HeaderAction[];
  right?: ReactNode;
  onBackPress?: () => void;
}

function ActionButton({ icon, onPress, badge }: HeaderAction) {
  const { colors } = useTheme();
  return (
    <Pressable
      onPress={onPress}
      hitSlop={8}
      style={({ pressed }) => [
        styles.iconBtn,
        { backgroundColor: colors.surface, borderColor: colors.border },
        pressed && { opacity: 0.6 },
      ]}
    >
      <Ionicons name={icon} size={20} color={colors.brand} />
      {badge ? (
        <View style={[styles.badge, { backgroundColor: colors.palette.red600 }]}>
          <Text variant="caption" color={colors.textInverse} style={styles.badgeText}>
            {badge > 9 ? '9+' : badge}
          </Text>
        </View>
      ) : null}
    </Pressable>
  );
}

// Consistent page header. Pass `rightIcon` (+ onRightPress, optionally
// `badge`... via rightActions) for a quick action button, `rightActions`
// for several buttons in a row, or `right` to drop in a fully custom
// element. Pass `onBackPress` for a leading back chevron on screens
// pushed onto the stack (the app hides the native header, so this is
// the only back affordance those screens get).
export default function Header({
  title,
  subtitle,
  eyebrow,
  rightIcon,
  onRightPress,
  badge,
  rightActions,
  right,
  onBackPress,
}: HeaderProps) {
  const { colors } = useTheme();
  return (
    <View style={styles.row}>
      {onBackPress ? (
        <Pressable onPress={onBackPress} hitSlop={8} style={styles.backBtn}>
          <Ionicons name="chevron-back" size={22} color={colors.brand} />
        </Pressable>
      ) : null}
      <View style={styles.left}>
        {eyebrow ? (
          <Text variant="eyebrow" color={colors.primary} style={styles.eyebrow}>
            {eyebrow}
          </Text>
        ) : null}
        <Text variant="h1">{title}</Text>
        {subtitle ? (
          <Text variant="body" color={colors.textSecondary} style={styles.subtitle}>
            {subtitle}
          </Text>
        ) : null}
      </View>

      {rightActions && rightActions.length > 0 ? (
        <View style={styles.actionsRow}>
          {rightActions.map((action, i) => (
            <View key={action.icon + i} style={i > 0 ? styles.actionsGap : undefined}>
              <ActionButton {...action} />
            </View>
          ))}
        </View>
      ) : rightIcon ? (
        <ActionButton icon={rightIcon} onPress={onRightPress} badge={badge} />
      ) : (
        right || null
      )}
    </View>
  );
}

// row/left/backBtn/eyebrow/subtitle are layout-only; iconBtn's/badge's
// color values are applied inline above from useTheme() instead.
const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    marginBottom: spacing.lg,
  },
  left: { flex: 1, paddingRight: spacing.md },
  backBtn: {
    width: 36, height: 36, borderRadius: radius.md,
    alignItems: 'center', justifyContent: 'center',
    marginRight: spacing.xs, marginTop: 2,
  },
  eyebrow: { marginBottom: 4 },
  subtitle: { marginTop: 2 },
  iconBtn: {
    width: 40,
    height: 40,
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
  },
  actionsRow: { flexDirection: 'row' },
  actionsGap: { marginLeft: spacing.xs },
  badge: {
    position: 'absolute',
    top: -4,
    right: -4,
    minWidth: 16,
    height: 16,
    borderRadius: 8,
    paddingHorizontal: 3,
    alignItems: 'center',
    justifyContent: 'center',
  },
  badgeText: { fontSize: 10, lineHeight: 12 },
});
'@)

# --- src\components\ListItem.tsx ---
[System.IO.File]::WriteAllText('src\components\ListItem.tsx', @'
import React, { type ReactNode } from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import Avatar from './Avatar';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import type { IoniconName } from '../types';

interface ListItemProps {
  avatarName?: string;
  leftIcon?: IoniconName;
  left?: ReactNode;
  title: string;
  subtitle?: string;
  meta?: string;
  right?: ReactNode;
  chevron?: boolean;
  onPress?: () => void;
}

// Used by every list screen (visitors, employees, calls, NFC cards, etc.).
// Pass either `avatarName` for initials, a `leftIcon`, or a custom `left`
// node. `right` can be anything (a badge, text, an icon). `chevron` adds
// a trailing arrow when the row is tappable.
export default function ListItem({
  avatarName,
  leftIcon,
  left,
  title,
  subtitle,
  meta,
  right,
  chevron = false,
  onPress,
}: ListItemProps) {
  const { colors } = useTheme();
  const content = (
    <>
      {left ? (
        left
      ) : avatarName ? (
        <Avatar name={avatarName} size={40} />
      ) : leftIcon ? (
        <View style={[styles.iconWrap, { backgroundColor: colors.surfaceAlt }]}>
          <Ionicons name={leftIcon} size={18} color={colors.brand} />
        </View>
      ) : null}

      <View style={styles.middle}>
        <Text variant="bodySemibold" numberOfLines={1}>
          {title}
        </Text>
        {subtitle ? (
          <Text variant="caption" color={colors.textSecondary} numberOfLines={1}>
            {subtitle}
          </Text>
        ) : null}
      </View>

      <View style={styles.rightCol}>
        {meta ? (
          <Text variant="caption" color={colors.textMuted}>
            {meta}
          </Text>
        ) : null}
        {right}
        {chevron ? (
          <Ionicons
            name="chevron-forward"
            size={18}
            color={colors.textMuted}
            style={{ marginLeft: 6 }}
          />
        ) : null}
      </View>
    </>
  );

  // Pressable supports the (pressed) => style render-prop form; a plain View
  // does not, so non-interactive rows (no onPress) get a static style instead.
  if (onPress) {
    return (
      <Pressable
        onPress={onPress}
        style={({ pressed }) => [
          styles.row,
          pressed && { backgroundColor: colors.surfaceAlt },
        ]}
      >
        {content}
      </Pressable>
    );
  }

  return <View style={styles.row}>{content}</View>;
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
    gap: spacing.sm,
    minHeight: 56,
  },
  iconWrap: {
    width: 40, height: 40, borderRadius: 10,
    alignItems: 'center', justifyContent: 'center',
  },
  middle: { flex: 1, marginHorizontal: spacing.xs },
  rightCol: { flexDirection: 'row', alignItems: 'center' },
});
'@)

# --- src\components\Segmented.tsx ---
[System.IO.File]::WriteAllText('src\components\Segmented.tsx', @'
import React from 'react';
import { View, Pressable, StyleSheet, type StyleProp, type ViewStyle } from 'react-native';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { radius, spacing } from '../theme/spacing';
import type { Option } from '../types';

interface SegmentedProps<T extends string> {
  options: Option<T>[];
  value: T;
  onChange: (value: T) => void;
  style?: StyleProp<ViewStyle>;
}

// Pill-style filter group used at the top of list screens (e.g. Visitors:
// All · On-site · Completed). Pass an array of { label, value } options
// and the selected value; emits the new value on press.
export default function Segmented<T extends string>({ options, value, onChange, style }: SegmentedProps<T>) {
  const { colors } = useTheme();
  return (
    <View style={[styles.wrap, { backgroundColor: colors.surfaceAlt }, style]}>
      {options.map((opt) => {
        const active = opt.value === value;
        return (
          <Pressable
            key={opt.value}
            onPress={() => onChange?.(opt.value)}
            style={[styles.btn, active && { backgroundColor: colors.brand }]}
          >
            <Text
              variant="bodyMd"
              color={active ? colors.textInverse : colors.textSecondary}
            >
              {opt.label}
            </Text>
          </Pressable>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    borderRadius: radius.pill,
    padding: 4,
  },
  btn: {
    flex: 1,
    paddingVertical: 8,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.pill,
  },
});
'@)

# --- src\components\StatTile.tsx ---
[System.IO.File]::WriteAllText('src\components\StatTile.tsx', @'
import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { shadows } from '../theme/shadows';
import { fonts } from '../theme/typography';
import type { IoniconName } from '../types';

type StatTileTint = 'primary' | 'info' | 'success' | 'pending';

interface StatTileProps {
  icon?: IoniconName;
  label: string;
  value: number | string;
  tint?: StatTileTint;
}

// One of the four big numbers on the Dashboard. A coloured icon chip on
// the left and a big display number on the right. The `tint` prop selects
// which status colour family the icon chip uses.
export default function StatTile({ icon = 'people', label, value, tint = 'primary' }: StatTileProps) {
  const { colors } = useTheme();
  // 'primary' pulls the signed-in org's brand accent; the rest are fixed
  // status colors that don't vary per organization.
  const TINTS = {
    primary: { bg: colors.primarySurface, fg: colors.primary },
    info: { bg: colors.status.info.bg, fg: colors.status.info.solid },
    success: { bg: colors.status.success.bg, fg: colors.status.success.solid },
    pending: { bg: colors.status.pending.bg, fg: colors.status.pending.solid },
  };
  const t = TINTS[tint] || TINTS.primary;
  return (
    <View style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.border }, shadows.sm]}>
      <View style={[styles.icon, { backgroundColor: t.bg }]}>
        <Ionicons name={icon} size={18} color={t.fg} />
      </View>
      <Text variant="caption" color={colors.textSecondary} style={styles.label}>
        {label}
      </Text>
      <Text style={[styles.value, { color: colors.textPrimary }]}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    flex: 1,
    borderRadius: radius.lg,
    borderWidth: 1,
    padding: spacing.md,
  },
  icon: {
    width: 32, height: 32, borderRadius: radius.md,
    alignItems: 'center', justifyContent: 'center',
    marginBottom: spacing.xs,
  },
  label: { marginTop: 2 },
  value: {
    fontFamily: fonts.displayBold,
    fontSize: 26,
    marginTop: 2,
    letterSpacing: -0.5,
  },
});
'@)

# --- src\components\Select.tsx ---
[System.IO.File]::WriteAllText('src\components\Select.tsx', @'
import React, { useState } from 'react';
import { View, Modal, Pressable, FlatList, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import type { IoniconName, Option } from '../types';

interface SelectProps<T> {
  label?: string;
  placeholder?: string;
  value?: T | null;
  options?: Option<T>[];
  onChange?: (value: T) => void;
  icon?: IoniconName;
  error?: string;
}

// A labelled "select"-style field. Tapping it opens a modal list of
// options. Use for: purpose of visit, host employee, call type, etc.
export default function Select<T>({
  label,
  placeholder = 'Select...',
  value,
  options = [],
  onChange,
  icon,
  error,
}: SelectProps<T>) {
  const { colors } = useTheme();
  const [open, setOpen] = useState(false);
  const selected = options.find((o) => o.value === value);

  return (
    <View style={{ marginBottom: spacing.md }}>
      {label ? (
        <Text variant="label" color={colors.textSecondary} style={{ marginBottom: 6 }}>
          {label}
        </Text>
      ) : null}

      <Pressable
        onPress={() => setOpen(true)}
        style={[
          styles.field,
          { backgroundColor: colors.surface, borderColor: colors.border },
          error && { borderColor: colors.status.error.solid },
        ]}
      >
        {icon ? (
          <Ionicons name={icon} size={18} color={colors.textMuted} style={{ marginRight: 8 }} />
        ) : null}
        <Text
          variant="body"
          color={selected ? colors.textPrimary : colors.textMuted}
          style={{ flex: 1 }}
          numberOfLines={1}
        >
          {selected ? selected.label : placeholder}
        </Text>
        <Ionicons name="chevron-down" size={18} color={colors.textMuted} />
      </Pressable>

      {error ? (
        <Text variant="caption" color={colors.status.error.solid} style={{ marginTop: 4 }}>
          {error}
        </Text>
      ) : null}

      <Modal
        visible={open}
        transparent
        animationType="fade"
        onRequestClose={() => setOpen(false)}
      >
        <Pressable style={styles.backdrop} onPress={() => setOpen(false)}>
          <Pressable style={[styles.sheet, { backgroundColor: colors.surface }]} onPress={(e) => e.stopPropagation()}>
            <View style={[styles.handle, { backgroundColor: colors.borderStrong }]} />
            {label ? (
              <Text variant="h3" style={{ marginBottom: spacing.sm }}>
                {label}
              </Text>
            ) : null}

            <FlatList
              data={options}
              keyExtractor={(item) => String(item.value)}
              ItemSeparatorComponent={() => <View style={[styles.sep, { backgroundColor: colors.border }]} />}
              renderItem={({ item }) => {
                const active = item.value === value;
                return (
                  <Pressable
                    onPress={() => {
                      onChange?.(item.value);
                      setOpen(false);
                    }}
                    style={styles.row}
                  >
                    <View style={{ flex: 1 }}>
                      <Text variant="bodySemibold">{item.label}</Text>
                      {item.sublabel ? (
                        <Text variant="caption" color={colors.textSecondary}>
                          {item.sublabel}
                        </Text>
                      ) : null}
                    </View>
                    {active ? (
                      <Ionicons name="checkmark-circle" size={20} color={colors.primary} />
                    ) : null}
                  </Pressable>
                );
              }}
            />
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    height: 48,
  },
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(14, 27, 44, 0.45)',
    justifyContent: 'flex-end',
  },
  sheet: {
    borderTopLeftRadius: radius.xl,
    borderTopRightRadius: radius.xl,
    paddingHorizontal: spacing.md,
    paddingTop: spacing.sm,
    paddingBottom: spacing.xl,
    maxHeight: '70%',
  },
  handle: {
    width: 36, height: 4, borderRadius: 2,
    alignSelf: 'center',
    marginBottom: spacing.sm,
  },
  row: {
    flexDirection: 'row', alignItems: 'center',
    paddingVertical: spacing.sm,
  },
  sep: { height: 1 },
});
'@)

# --- src\components\MultiSelect.tsx ---
[System.IO.File]::WriteAllText('src\components\MultiSelect.tsx', @'
import React, { useState } from 'react';
import { View, Modal, Pressable, FlatList, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import Button from './Button';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import type { IoniconName, Option } from '../types';

interface MultiSelectProps<T> {
  label?: string;
  placeholder?: string;
  values?: T[];
  options?: Option<T>[];
  onChange?: (values: T[]) => void;
  icon?: IoniconName;
}

// Like Select, but lets the user tick more than one option before
// closing the sheet -- used for picking meeting attendees from the
// whole staff directory (not just a single host).
export default function MultiSelect<T>({
  label,
  placeholder = 'Select...',
  values = [],
  options = [],
  onChange,
  icon,
}: MultiSelectProps<T>) {
  const { colors } = useTheme();
  const [open, setOpen] = useState(false);
  const selectedLabels = options
    .filter((o) => values.includes(o.value))
    .map((o) => o.label);

  const toggle = (value: T) => {
    if (values.includes(value)) {
      onChange?.(values.filter((v) => v !== value));
    } else {
      onChange?.([...values, value]);
    }
  };

  const summary = selectedLabels.length === 0
    ? placeholder
    : selectedLabels.length <= 2
      ? selectedLabels.join(', ')
      : `${selectedLabels.length} people selected`;

  return (
    <View style={{ marginBottom: spacing.md }}>
      {label ? (
        <Text variant="label" color={colors.textSecondary} style={{ marginBottom: 6 }}>
          {label}
        </Text>
      ) : null}

      <Pressable
        onPress={() => setOpen(true)}
        style={[styles.field, { backgroundColor: colors.surface, borderColor: colors.border }]}
      >
        {icon ? (
          <Ionicons name={icon} size={18} color={colors.textMuted} style={{ marginRight: 8 }} />
        ) : null}
        <Text
          variant="body"
          color={selectedLabels.length ? colors.textPrimary : colors.textMuted}
          style={{ flex: 1 }}
          numberOfLines={1}
        >
          {summary}
        </Text>
        <Ionicons name="chevron-down" size={18} color={colors.textMuted} />
      </Pressable>

      <Modal
        visible={open}
        transparent
        animationType="fade"
        onRequestClose={() => setOpen(false)}
      >
        <Pressable style={styles.backdrop} onPress={() => setOpen(false)}>
          <Pressable style={[styles.sheet, { backgroundColor: colors.surface }]} onPress={(e) => e.stopPropagation()}>
            <View style={[styles.handle, { backgroundColor: colors.borderStrong }]} />
            {label ? (
              <Text variant="h3" style={{ marginBottom: spacing.sm }}>
                {label}
              </Text>
            ) : null}

            <FlatList
              data={options}
              keyExtractor={(item) => String(item.value)}
              ItemSeparatorComponent={() => <View style={[styles.sep, { backgroundColor: colors.border }]} />}
              renderItem={({ item }) => {
                const active = values.includes(item.value);
                return (
                  <Pressable onPress={() => toggle(item.value)} style={styles.row}>
                    <View
                      style={[
                        styles.checkbox,
                        { borderColor: colors.borderStrong },
                        active && { backgroundColor: colors.primary, borderColor: colors.primary },
                      ]}
                    >
                      {active ? <Ionicons name="checkmark" size={14} color="#FFF" /> : null}
                    </View>
                    <View style={{ flex: 1, marginLeft: spacing.sm }}>
                      <Text variant="bodySemibold">{item.label}</Text>
                      {item.sublabel ? (
                        <Text variant="caption" color={colors.textSecondary}>
                          {item.sublabel}
                        </Text>
                      ) : null}
                    </View>
                  </Pressable>
                );
              }}
            />

            <Button label="Done" onPress={() => setOpen(false)} style={{ marginTop: spacing.sm }} />
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    height: 48,
  },
  backdrop: {
    flex: 1,
    backgroundColor: 'rgba(14, 27, 44, 0.45)',
    justifyContent: 'flex-end',
  },
  sheet: {
    borderTopLeftRadius: radius.xl,
    borderTopRightRadius: radius.xl,
    paddingHorizontal: spacing.md,
    paddingTop: spacing.sm,
    paddingBottom: spacing.xl,
    maxHeight: '70%',
  },
  handle: {
    width: 36, height: 4, borderRadius: 2,
    alignSelf: 'center',
    marginBottom: spacing.sm,
  },
  row: {
    flexDirection: 'row', alignItems: 'center',
    paddingVertical: spacing.sm,
  },
  checkbox: {
    width: 20, height: 20, borderRadius: 6,
    borderWidth: 1.5,
    alignItems: 'center', justifyContent: 'center',
  },
  sep: { height: 1 },
});
'@)

# --- src\components\RescheduleModal.tsx ---
[System.IO.File]::WriteAllText('src\components\RescheduleModal.tsx', @'
import React, { useState } from 'react';
import {
  View, StyleSheet, Modal, TextInput, Pressable, Alert,
  KeyboardAvoidingView, type TextInputProps,
} from 'react-native';
import Text from './Text';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useData } from '../context/DataContext';
import { ApiError } from '../api/client';
import type { Appointment } from '../types';

interface RescheduleModalProps {
  appointment: Appointment | null;
  visible: boolean;
  onClose: () => void;
}

// RescheduleModal -- lets an Employee or Visitor move an appointment's
// time, but only with a reason on record (per spec). Shared between
// AppointmentsScreen (Employee tab) and VisitorVisitsScreen.
export default function RescheduleModal({ appointment, visible, onClose }: RescheduleModalProps) {
  const { colors } = useTheme();
  const { rescheduleAppointment } = useData();
  const [date, setDate] = useState('');
  const [time, setTime] = useState('');
  const [reason, setReason] = useState('');

  const onSave = async () => {
    if (!appointment) return;
    if (!date.trim() || !time.trim() || !reason.trim()) {
      Alert.alert('Almost there', 'New date, time and a reason are all required.');
      return;
    }
    try {
      await rescheduleAppointment(appointment.id, toInstant(date, time), reason.trim());
      setDate(''); setTime(''); setReason('');
      onClose();
    } catch (err) {
      Alert.alert('Could not reschedule', err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <KeyboardAvoidingView
        style={styles.wrap}
        behavior="padding"
      >
        <View style={[styles.card, { backgroundColor: colors.surface }]}>
          <Text variant="h3">Reschedule visit</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            {appointment?.visitorName}
          </Text>

          <Field label="New date (YYYY-MM-DD)" value={date} onChangeText={setDate} />
          <Field label="New time (HH:MM)" value={time} onChangeText={setTime} />
          <Field label="Reason for change" value={reason} onChangeText={setReason} multiline />

          <View style={styles.row}>
            <Pressable onPress={onClose} style={[styles.btn, { backgroundColor: colors.surfaceAlt }]}>
              <Text variant="bodySemibold" color={colors.textSecondary}>Cancel</Text>
            </Pressable>
            <Pressable onPress={onSave} style={[styles.btn, { backgroundColor: colors.brand }]}>
              <Text variant="bodySemibold" color={colors.textInverse}>Save</Text>
            </Pressable>
          </View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

// The backend expects a full ISO instant (with seconds + timezone);
// "YYYY-MM-DDTHH:MM" alone isn't parseable as one.
function toInstant(dateStr: string, timeStr: string): string {
  return new Date(`${dateStr}T${timeStr}:00`).toISOString();
}

function Field({ label, ...inputProps }: TextInputProps & { label: string }) {
  const { colors } = useTheme();
  return (
    <View style={{ marginBottom: spacing.sm }}>
      <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: 4 }}>{label}</Text>
      <TextInput
        {...inputProps}
        style={[styles.input, { borderColor: colors.border, color: colors.textPrimary }]}
        placeholderTextColor={colors.textMuted}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flex: 1, backgroundColor: 'rgba(10,42,29,0.55)',
    alignItems: 'center', justifyContent: 'center', padding: spacing.lg,
  },
  card: {
    width: '100%', maxWidth: 360,
    borderRadius: radius.lg,
    padding: spacing.lg,
  },
  input: {
    borderWidth: 1, borderRadius: radius.md,
    paddingHorizontal: spacing.sm, paddingVertical: 10,
    fontFamily: fonts.regular, fontSize: 14,
  },
  row: { flexDirection: 'row', marginTop: spacing.sm, gap: spacing.sm },
  btn: { flex: 1, height: 44, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center' },
});
'@)

# --- src\components\CompanyMapSection.tsx ---
[System.IO.File]::WriteAllText('src\components\CompanyMapSection.tsx', @'
import React, { useMemo, useState } from 'react';
import { View, Image, StyleSheet, Pressable, Modal } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import Card from './Card';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import type { IoniconName } from '../types';

interface MapLocation {
  id: string;
  name: string;
  floor: string;
  icon: IoniconName;
  directions: string[];
  capacity?: number | null;
  photoUrl?: string | null;
}

// A simplified "tour" map: a stylized floor-plan grid with tappable
// pins for reception + each meeting room. There's no real indoor
// positioning here (that needs BLE beacons / indoor GPS infrastructure
// this demo doesn't have) -- tapping a pin shows the room's real photo
// (if Company Setup added one) plus short walking directions, giving
// the tour feel without it. Falls back to a stylized icon when no
// photo has been uploaded for that room.
export default function CompanyMapSection() {
  const { colors } = useTheme();
  const { meetingRooms } = useData();
  const [selected, setSelected] = useState<MapLocation | null>(null);

  const LOCATIONS = useMemo<MapLocation[]>(() => [
    {
      id: 'reception', name: 'Reception', floor: 'Ground Floor', icon: 'desktop-outline',
      directions: ['Enter through the main doors.', 'Reception desk is straight ahead.'],
    },
    ...meetingRooms.map((r, i) => ({
      id: r.id,
      name: r.name,
      floor: r.floor,
      capacity: r.capacity,
      icon: 'business-outline' as IoniconName,
      photoUrl: r.photoUrl,
      directions: r.description ? [r.description] : [
        'From reception, take the lift or stairs up.',
        `Follow signage to ${r.floor}.`,
        `${r.name} is the ${i === 0 ? 'first' : i === 1 ? 'second' : 'third'} door on the left.`,
      ],
    })),
  ], [meetingRooms]);

  return (
    <View>
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Find your way around
      </Text>
      <Card padded={false} style={styles.mapCard}>
        <View style={[styles.floor, { backgroundColor: colors.surfaceAlt }]}>
          {LOCATIONS.map((loc) => (
            <Pressable
              key={loc.id}
              onPress={() => setSelected(loc)}
              style={[styles.room, { backgroundColor: colors.surface, borderColor: colors.border }]}
            >
              <View style={[styles.pin, { backgroundColor: colors.primarySurface }]}>
                <Ionicons name={loc.icon} size={16} color={colors.brand} />
              </View>
              <Text variant="caption" color={colors.textPrimary} numberOfLines={1} style={styles.roomLabel}>
                {loc.name}
              </Text>
            </Pressable>
          ))}
        </View>
      </Card>

      <Modal visible={!!selected} transparent animationType="fade" onRequestClose={() => setSelected(null)}>
        <View style={styles.modalWrap}>
          <View style={[styles.modalCard, { backgroundColor: colors.surface }]}>
            <View style={[styles.modalPhoto, { backgroundColor: colors.primarySurface }]}>
              {selected?.photoUrl ? (
                <Image source={{ uri: selected.photoUrl }} style={styles.modalPhotoImage} resizeMode="cover" />
              ) : (
                <Ionicons name={selected?.icon || 'business-outline'} size={40} color={colors.primary} />
              )}
            </View>
            <Text variant="h3">{selected?.name}</Text>
            <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.sm }}>
              {selected?.floor}{selected?.capacity ? ` · Capacity ${selected.capacity}` : ''}
            </Text>
            {selected?.directions.map((step, i) => (
              <View key={i} style={styles.stepRow}>
                <View style={[styles.stepNum, { backgroundColor: colors.brand }]}>
                  <Text variant="caption" color={colors.textInverse}>{i + 1}</Text>
                </View>
                <Text variant="bodyMd" style={{ flex: 1 }}>{step}</Text>
              </View>
            ))}
            <Pressable onPress={() => setSelected(null)} style={[styles.closeBtn, { backgroundColor: colors.brand }]}>
              <Text variant="bodySemibold" color={colors.textInverse}>Got it</Text>
            </Pressable>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  mapCard: { overflow: 'hidden' },
  // A wrapping grid rather than fixed absolute slots -- a fixed 4-slot
  // layout silently stacked any 5th+ room directly on top of an
  // earlier one (i % 4 reused the same position), which looked like
  // "only 4 rooms show up" no matter how many Company Setup had.
  floor: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    minHeight: 140,
    padding: spacing.md,
    gap: spacing.sm,
  },
  room: {
    width: 110,
    alignItems: 'center',
    borderRadius: radius.md,
    borderWidth: 1,
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.xs,
  },
  pin: {
    width: 30, height: 30, borderRadius: 15,
    alignItems: 'center', justifyContent: 'center',
    marginBottom: 4,
  },
  roomLabel: { textAlign: 'center' },

  modalWrap: {
    flex: 1, backgroundColor: 'rgba(10,42,29,0.55)',
    alignItems: 'center', justifyContent: 'center', padding: spacing.lg,
  },
  modalCard: {
    width: '100%', maxWidth: 360,
    borderRadius: radius.lg,
    padding: spacing.lg,
  },
  modalPhoto: {
    height: 140, borderRadius: radius.md,
    alignItems: 'center', justifyContent: 'center',
    marginBottom: spacing.sm,
    overflow: 'hidden',
  },
  modalPhotoImage: { width: '100%', height: '100%' },
  stepRow: { flexDirection: 'row', alignItems: 'flex-start', marginTop: spacing.xs, gap: 8 },
  stepNum: {
    width: 20, height: 20, borderRadius: 10,
    alignItems: 'center', justifyContent: 'center',
    marginTop: 2,
  },
  closeBtn: {
    marginTop: spacing.md, height: 44, borderRadius: radius.md,
    alignItems: 'center', justifyContent: 'center',
  },
});
'@)

# --- src\components\QuickDateTime.tsx ---
[System.IO.File]::WriteAllText('src\components\QuickDateTime.tsx', @'
import React, { useMemo, useState } from 'react';
import { ScrollView, View, Pressable, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Text from './Text';
import Input from './Input';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';

const pad = (n: number): string => String(n).padStart(2, '0');
const toDateStr = (d: Date): string => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

interface DateChipsProps {
  value: string;
  onChange: (dateStr: string) => void;
  days?: number;
}

// Tap-to-pick date, no native picker module (so it works in plain Expo
// Go, not just a custom dev client) -- a row of the next N days as
// chips, plus a "Pick a date" fallback for anything further out or in
// the past, since the quick-pick row alone was too restrictive.
export function DateChips({ value, onChange, days = 10 }: DateChipsProps) {
  const { colors } = useTheme();
  const [customOpen, setCustomOpen] = useState(false);
  const options = useMemo(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return Array.from({ length: days }, (_, i) => {
      const d = new Date(today);
      d.setDate(d.getDate() + i);
      const dateStr = toDateStr(d);
      const label = i === 0 ? 'Today' : i === 1 ? 'Tomorrow' : `${WEEKDAYS[d.getDay()]} ${d.getDate()}`;
      return { dateStr, label };
    });
  }, [days]);
  const isQuickPick = options.some((opt) => opt.dateStr === value);

  return (
    <View>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.row}>
        {options.map((opt) => {
          const selected = opt.dateStr === value;
          return (
            <Pressable
              key={opt.dateStr}
              onPress={() => { onChange(opt.dateStr); setCustomOpen(false); }}
              style={[
                styles.chip,
                { borderColor: colors.border, backgroundColor: colors.surface },
                selected && { backgroundColor: colors.primary, borderColor: colors.primary },
              ]}
            >
              <Text variant="label" color={selected ? colors.textInverse : colors.textPrimary}>
                {opt.label}
              </Text>
            </Pressable>
          );
        })}
      </ScrollView>
      <Pressable
        onPress={() => setCustomOpen((o) => !o)}
        style={[
          styles.customToggle,
          { borderColor: colors.border, backgroundColor: colors.surface },
          (customOpen || !isQuickPick) && { backgroundColor: colors.primary, borderColor: colors.primary },
        ]}
      >
        <Ionicons
          name="calendar-outline"
          size={16}
          color={(customOpen || !isQuickPick) ? colors.textInverse : colors.textPrimary}
        />
        <Text
          variant="label"
          color={(customOpen || !isQuickPick) ? colors.textInverse : colors.textPrimary}
          style={{ marginLeft: 6 }}
        >
          Pick a date
        </Text>
      </Pressable>
      {customOpen || !isQuickPick ? (
        <Input
          value={value}
          onChangeText={onChange}
          placeholder="YYYY-MM-DD"
          icon="calendar-outline"
          style={{ marginTop: spacing.xs }}
        />
      ) : null}
    </View>
  );
}

interface TimeChipsProps {
  value: string;
  onChange: (timeStr: string) => void;
  startHour?: number;
  endHour?: number;
  stepMinutes?: number;
}

// Same idea for time -- half-hour slots across the working day as
// chips, plus a tap-to-open hour/minute stepper (up/down arrows) for
// anything off the half-hour grid.
export function TimeChips({ value, onChange, startHour = 7, endHour = 19, stepMinutes = 30 }: TimeChipsProps) {
  const { colors } = useTheme();
  const [customOpen, setCustomOpen] = useState(false);
  const options = useMemo(() => {
    const slots: string[] = [];
    for (let mins = startHour * 60; mins <= endHour * 60; mins += stepMinutes) {
      slots.push(`${pad(Math.floor(mins / 60))}:${pad(mins % 60)}`);
    }
    return slots;
  }, [startHour, endHour, stepMinutes]);
  const isQuickPick = options.includes(value);

  return (
    <View>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.row}>
        {options.map((t) => {
          const selected = t === value;
          return (
            <Pressable
              key={t}
              onPress={() => { onChange(t); setCustomOpen(false); }}
              style={[
                styles.chip,
                { borderColor: colors.border, backgroundColor: colors.surface },
                selected && { backgroundColor: colors.primary, borderColor: colors.primary },
              ]}
            >
              <Text variant="label" color={selected ? colors.textInverse : colors.textPrimary}>
                {t}
              </Text>
            </Pressable>
          );
        })}
      </ScrollView>
      <Pressable
        onPress={() => setCustomOpen((o) => !o)}
        style={[
          styles.customToggle,
          { borderColor: colors.border, backgroundColor: colors.surface },
          (customOpen || !isQuickPick) && { backgroundColor: colors.primary, borderColor: colors.primary },
        ]}
      >
        <Ionicons
          name="time-outline"
          size={16}
          color={(customOpen || !isQuickPick) ? colors.textInverse : colors.textPrimary}
        />
        <Text
          variant="label"
          color={(customOpen || !isQuickPick) ? colors.textInverse : colors.textPrimary}
          style={{ marginLeft: 6 }}
        >
          Pick a time
        </Text>
      </Pressable>
      {customOpen || !isQuickPick ? <TimeStepper value={value} onChange={onChange} /> : null}
    </View>
  );
}

function TimeStepper({ value, onChange }: { value: string; onChange: (t: string) => void }) {
  const { colors } = useTheme();
  const [hStr, mStr] = value.split(':');
  const h = Number(hStr) || 0;
  const m = Number(mStr) || 0;

  const setHour = (next: number) => onChange(`${pad(((next % 24) + 24) % 24)}:${pad(m)}`);
  const setMinute = (next: number) => onChange(`${pad(h)}:${pad(((next % 60) + 60) % 60)}`);

  return (
    <View style={[stepperStyles.wrap, { borderColor: colors.border }]}>
      <StepperColumn value={pad(h)} onUp={() => setHour(h + 1)} onDown={() => setHour(h - 1)} colors={colors} />
      <Text variant="h2" style={stepperStyles.colon}>:</Text>
      <StepperColumn value={pad(m)} onUp={() => setMinute(m + 1)} onDown={() => setMinute(m - 1)} colors={colors} />
    </View>
  );
}

function StepperColumn({
  value, onUp, onDown, colors,
}: { value: string; onUp: () => void; onDown: () => void; colors: { primarySurface: string; primary: string } }) {
  return (
    <View style={stepperStyles.col}>
      <Pressable onPress={onUp} style={[stepperStyles.btn, { backgroundColor: colors.primarySurface }]}>
        <Ionicons name="chevron-up" size={18} color={colors.primary} />
      </Pressable>
      <Text variant="h2" style={stepperStyles.value}>{value}</Text>
      <Pressable onPress={onDown} style={[stepperStyles.btn, { backgroundColor: colors.primarySurface }]}>
        <Ionicons name="chevron-down" size={18} color={colors.primary} />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  row: { marginBottom: spacing.xs },
  chip: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.pill,
    borderWidth: 1,
    marginRight: spacing.xs,
  },
  customToggle: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: radius.pill,
    borderWidth: 1,
    marginBottom: spacing.md,
  },
});

const stepperStyles = StyleSheet.create({
  wrap: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingVertical: spacing.md,
    marginBottom: spacing.md,
  },
  col: { alignItems: 'center', width: 64 },
  btn: { width: 44, height: 32, borderRadius: radius.sm, alignItems: 'center', justifyContent: 'center' },
  value: { marginVertical: 4 },
  colon: { marginHorizontal: spacing.sm },
});
'@)

# --- src\components\ClockCard.tsx ---
[System.IO.File]::WriteAllText('src\components\ClockCard.tsx', @'
import React, { useState } from 'react';
import {
  View, StyleSheet, Alert, Modal, TextInput, Pressable,
  KeyboardAvoidingView,
} from 'react-native';
import * as LocalAuthentication from 'expo-local-authentication';
import Text from './Text';
import Card from './Card';
import Button from './Button';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime } from '../data/format';
import { isOnWifi } from '../data/wifiCheck';
import { isAtOffice } from '../data/locationCheck';
import { ApiError } from '../api/client';

// ClockCard -- the personal "on the clock" card shared by every role's
// home screen. Backed by DataContext's shared clock ledger (not local
// state) so the Manager's Clock-ins screen sees the same records.
//
// Clocking IN requires: (1) a best-effort WiFi check, (2) a best-effort
// GPS geofence check against the signed-in org's office location, (3)
// confirming it's really you -- an on-device biometric prompt (Face
// ID/fingerprint) when the device has one enrolled, falling back to
// re-entering your own password otherwise (or if the biometric prompt
// itself is cancelled/fails) -- and (4) not having already clocked in
// once today. None of this stops someone who genuinely knows a
// coworker's password/has their fingerprint, but it blocks the far
// more common case of clocking in from a phone someone else left
// signed in and unattended. Clocking OUT never blocks.
export default function ClockCard() {
  const { colors } = useTheme();
  const { user, organization, verifyPassword } = useAuth();
  const { clockRecords, clockIn, clockOut, isClockedIn, hasClockedInToday } = useData();
  const [checking, setChecking] = useState(false);
  const [confirmVisible, setConfirmVisible] = useState(false);
  const [password, setPassword] = useState('');
  const [confirming, setConfirming] = useState(false);

  const employeeId = (user?.employeeId || user?.id) as string;
  const clockedIn = isClockedIn(employeeId);
  const lastRecord = clockRecords.find((c) => c.employeeId === employeeId);
  const doneForToday = !clockedIn && hasClockedInToday(employeeId);

  const performClockIn = async () => {
    try {
      const r = await clockIn(employeeId, user!.name);
      Alert.alert('Checked in', `Welcome. Clocked in at ${fmtTime(r.timestamp)}.`);
    } catch (err) {
      Alert.alert('Could not clock in', err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  const toggle = async () => {
    if (!clockedIn) {
      if (hasClockedInToday(employeeId)) {
        Alert.alert('Already clocked in today', 'You can only clock in once per day -- see you tomorrow.');
        return;
      }
      setChecking(true);
      const onWifi = await isOnWifi();
      if (!onWifi) {
        setChecking(false);
        Alert.alert('Company network required', 'Connect to the company WiFi to clock in.');
        return;
      }
      const locationResult = await isAtOffice(organization?.officeLocation);
      if (!locationResult.ok) {
        setChecking(false);
        Alert.alert('Location check failed', locationResult.error);
        return;
      }

      const hasHardware = await LocalAuthentication.hasHardwareAsync();
      const isEnrolled = hasHardware && await LocalAuthentication.isEnrolledAsync();
      if (isEnrolled) {
        const result = await LocalAuthentication.authenticateAsync({
          promptMessage: 'Confirm it is you to clock in',
          cancelLabel: 'Use password instead',
        });
        setChecking(false);
        if (result.success) {
          await performClockIn();
          return;
        }
        // Cancelled, failed, or "Use password instead" was tapped --
        // fall back to the password modal rather than blocking the
        // clock-in outright (e.g. a dirty fingerprint sensor shouldn't
        // strand someone off the clock all day).
        setPassword('');
        setConfirmVisible(true);
        return;
      }

      setChecking(false);
      setPassword('');
      setConfirmVisible(true);
    } else {
      try {
        const r = await clockOut(employeeId, user!.name);
        Alert.alert('Checked out', `See you next time. Clocked out at ${fmtTime(r.timestamp)}.`);
      } catch (err) {
        Alert.alert('Could not clock out', err instanceof ApiError ? err.message : 'Something went wrong.');
      }
    }
  };

  const onConfirmClockIn = async () => {
    if (!password) return;
    setConfirming(true);
    const result = await verifyPassword(password);
    if (!result.ok) {
      setConfirming(false);
      Alert.alert('Could not verify you', result.error);
      return;
    }
    setConfirmVisible(false);
    setPassword('');
    setConfirming(false);
    await performClockIn();
  };

  return (
    <Card accent={clockedIn ? 'onsite' : 'neutral'}>
      <View style={styles.row}>
        <View style={{ flex: 1 }}>
          <Text variant="caption" color={colors.textSecondary}>Work status</Text>
          <Text variant="h2">{clockedIn ? 'On the clock' : 'Off the clock'}</Text>
          {clockedIn && lastRecord ? (
            <Text variant="caption" color={colors.textMuted}>
              Since {fmtTime(lastRecord.timestamp)}
            </Text>
          ) : doneForToday ? (
            <Text variant="caption" color={colors.textMuted}>
              Done for today -- see you tomorrow.
            </Text>
          ) : null}
        </View>
        <Button
          label={checking ? 'Checking...' : clockedIn ? 'Check out' : doneForToday ? 'Done for today' : 'Check in'}
          icon={clockedIn ? 'log-out-outline' : 'log-in-outline'}
          variant={clockedIn ? 'danger' : 'primary'}
          onPress={toggle}
          disabled={checking || doneForToday}
        />
      </View>

      <ConfirmClockInModal
        visible={confirmVisible}
        password={password}
        onChangePassword={setPassword}
        confirming={confirming}
        onCancel={() => { setConfirmVisible(false); setPassword(''); }}
        onConfirm={onConfirmClockIn}
      />
    </Card>
  );
}

interface ConfirmClockInModalProps {
  visible: boolean;
  password: string;
  onChangePassword: (password: string) => void;
  confirming: boolean;
  onCancel: () => void;
  onConfirm: () => void;
}

// Fallback for devices with no biometric enrolled (or when the
// biometric prompt itself was cancelled/failed) -- see the note on
// ClockCard above.
function ConfirmClockInModal({
  visible, password, onChangePassword, confirming, onCancel, onConfirm,
}: ConfirmClockInModalProps) {
  const { colors } = useTheme();
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onCancel}>
      <KeyboardAvoidingView
        style={styles.modalWrap}
        behavior="padding"
      >
        <View style={[styles.modalCard, { backgroundColor: colors.surface }]}>
          <Text variant="h3">Confirm it's you</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            Re-enter your password to clock in.
          </Text>
          <TextInput
            value={password}
            onChangeText={onChangePassword}
            placeholder="Password"
            placeholderTextColor={colors.textMuted}
            secureTextEntry
            autoFocus
            style={[styles.modalInput, { borderColor: colors.border, color: colors.textPrimary }]}
          />
          <View style={styles.modalRow}>
            <Pressable onPress={onCancel} style={[styles.modalBtn, { backgroundColor: colors.surfaceAlt }]}>
              <Text variant="bodySemibold" color={colors.textSecondary}>Cancel</Text>
            </Pressable>
            <Pressable
              onPress={onConfirm}
              disabled={!password || confirming}
              style={[
                styles.modalBtn,
                { backgroundColor: colors.primary, opacity: !password || confirming ? 0.6 : 1 },
              ]}
            >
              <Text variant="bodySemibold" color={colors.textInverse}>
                {confirming ? 'Checking...' : 'Clock in'}
              </Text>
            </Pressable>
          </View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center' },
  modalWrap: {
    flex: 1, backgroundColor: 'rgba(10,42,29,0.55)',
    alignItems: 'center', justifyContent: 'center', padding: spacing.lg,
  },
  modalCard: {
    width: '100%', maxWidth: 360,
    borderRadius: radius.lg,
    padding: spacing.lg,
  },
  modalInput: {
    borderWidth: 1, borderRadius: radius.md,
    paddingHorizontal: spacing.sm, paddingVertical: 10,
    fontFamily: fonts.regular, fontSize: 14,
    marginBottom: spacing.sm,
  },
  modalRow: { flexDirection: 'row', marginTop: spacing.xs, gap: spacing.sm },
  modalBtn: { flex: 1, height: 44, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center' },
});
'@)

# --- src\components\Screen.tsx ---
[System.IO.File]::WriteAllText('src\components\Screen.tsx', @'
import React, { type ReactNode } from 'react';
import {
  View, Image, ScrollView, StyleSheet, KeyboardAvoidingView, RefreshControl,
  type StyleProp, type ViewStyle,
} from 'react-native';
import { SafeAreaView, type Edge } from 'react-native-safe-area-context';
import { spacing } from '../theme/spacing';
import { useTheme } from '../theme/ThemeContext';
import { useAuth } from '../context/AuthContext';

interface ScreenProps {
  children?: ReactNode;
  scroll?: boolean;
  padded?: boolean;
  style?: StyleProp<ViewStyle>;
  contentStyle?: StyleProp<ViewStyle>;
  edges?: Edge[];
  // Pull-to-refresh -- only wired up on the scroll={true} (default)
  // variant, since scroll={false} screens manage their own FlatList
  // (which takes its own refreshControl prop directly).
  refreshing?: boolean;
  onRefresh?: () => void;
}

// A big, faint, diagonal brand mark behind every screen's content --
// purely decorative (pointerEvents="none" so it never intercepts
// taps). Shows the signed-in org's own uploaded logo once they've set
// one (Company Setup > Branding), so a company's app actually looks
// like their own; falls back to the static VisiLog mark before
// sign-in and for orgs that haven't uploaded a logo yet. Sits under
// the ScrollView/View as an absolutely positioned sibling so it never
// scrolls with the content.
function Watermark() {
  const { organization } = useAuth();
  return (
    <View style={styles.watermarkWrap} pointerEvents="none">
      <Image
        source={organization?.logoUrl ? { uri: organization.logoUrl } : require('../../assets/logo.png')}
        style={styles.watermarkImage}
        resizeMode="contain"
      />
    </View>
  );
}

// Standard page shell: respects the notch/home-indicator, paints the app
// background, and gives you a scroll view by default. Set scroll={false}
// for screens that manage their own list or need vertical centring.
//
// Wrapped in KeyboardAvoidingView so forms (Register visitor, Add
// employee, Book a visit, etc.) don't get their lower fields hidden
// behind the on-screen keyboard -- every screen built on Screen gets
// this for free instead of each one having to wire it up itself.
export default function Screen({
  children,
  scroll = true,
  padded = true,
  style,
  contentStyle,
  edges = ['top'],
  refreshing,
  onRefresh,
}: ScreenProps) {
  const { colors: themeColors } = useTheme();
  if (scroll) {
    return (
      <SafeAreaView style={[styles.safe, { backgroundColor: themeColors.background }, style]} edges={edges}>
        <Watermark />
        <KeyboardAvoidingView
          style={styles.flex}
          behavior="padding"
        >
          <ScrollView
            contentContainerStyle={[padded && styles.padded, contentStyle]}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
            refreshControl={
              onRefresh ? (
                <RefreshControl refreshing={!!refreshing} onRefresh={onRefresh} tintColor={themeColors.primary} />
              ) : undefined
            }
          >
            {children}
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    );
  }
  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: themeColors.background }, style]} edges={edges}>
      <Watermark />
      <KeyboardAvoidingView
        style={styles.flex}
        behavior="padding"
      >
        <View style={[styles.flex, padded && styles.padded, contentStyle]}>{children}</View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  flex: { flex: 1 },
  padded: { padding: spacing.md, paddingBottom: spacing.xxxl },
  watermarkWrap: {
    ...StyleSheet.absoluteFillObject,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  watermarkImage: {
    width: '180%',
    height: '60%',
    opacity: 0.05,
    transform: [{ rotate: '-25deg' }],
  },
});
'@)

# --- src\components\CsvImportModal.tsx ---
[System.IO.File]::WriteAllText('src\components\CsvImportModal.tsx', @'
import React, { useState } from 'react';
import {
  View, Modal, StyleSheet, Alert, ActivityIndicator, ScrollView,
} from 'react-native';
import * as DocumentPicker from 'expo-document-picker';
import * as FileSystem from 'expo-file-system/legacy';
import Text from './Text';
import Button from './Button';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { parseCsv, csvRowsToRecords } from '../data/csv';
import { ApiError } from '../api/client';
import type { BulkImportResult } from '../types';

interface CsvImportModalProps<T> {
  visible: boolean;
  onClose: () => void;
  title: string;
  columnsHint: string;
  mapRow: (record: Record<string, string>) => T;
  onImport: (rows: T[]) => Promise<BulkImportResult<unknown>>;
}

// CsvImportModal -- bulk-add staff or meeting rooms from a spreadsheet
// export instead of one-at-a-time. The backend still validates every
// row and reports back what failed and why (see EmployeeService/
// MeetingRoomService.bulkCreate) -- a CSV can have typos a single-add
// form would never let through.
export default function CsvImportModal<T>({
  visible, onClose, title, columnsHint, mapRow, onImport,
}: CsvImportModalProps<T>) {
  const { colors } = useTheme();
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<BulkImportResult<unknown> | null>(null);

  const onPickFile = async () => {
    let picked: DocumentPicker.DocumentPickerResult;
    try {
      picked = await DocumentPicker.getDocumentAsync({ type: '*/*', copyToCacheDirectory: true });
    } catch {
      Alert.alert('Could not open file picker', 'Please try again.');
      return;
    }
    if (picked.canceled || !picked.assets?.[0]) return;

    setBusy(true);
    try {
      const text = await FileSystem.readAsStringAsync(picked.assets[0].uri, { encoding: 'utf8' });
      const records = csvRowsToRecords(parseCsv(text));
      if (records.length === 0) {
        Alert.alert('Empty file', 'That file has no data rows to import.');
        return;
      }
      const rows = records.map(mapRow);
      const res = await onImport(rows);
      setResult(res);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : 'Check the file is a valid CSV and try again.';
      Alert.alert('Could not import', message);
    } finally {
      setBusy(false);
    }
  };

  const onDoneClose = () => {
    setResult(null);
    onClose();
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onDoneClose}>
      <View style={styles.wrap}>
        <View style={[styles.card, { backgroundColor: colors.surface }]}>
          <Text variant="h3">{title}</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            {columnsHint}
          </Text>

          {result ? (
            <ScrollView style={styles.resultScroll}>
              <Text variant="bodySemibold" color={colors.brand}>
                {result.created.length} added
              </Text>
              {result.errors.length > 0 ? (
                <>
                  <Text variant="bodySemibold" color={colors.status.rejected.solid} style={{ marginTop: spacing.sm }}>
                    {result.errors.length} skipped
                  </Text>
                  {result.errors.map((e) => (
                    <Text key={e.row} variant="caption" color={colors.textSecondary}>
                      Row {e.row}: {e.message}
                    </Text>
                  ))}
                </>
              ) : null}
            </ScrollView>
          ) : busy ? (
            <View style={styles.busyWrap}>
              <ActivityIndicator color={colors.primary} />
            </View>
          ) : (
            <Button label="Choose CSV file" icon="document-attach-outline" onPress={onPickFile} />
          )}

          <Button
            label={result ? 'Done' : 'Cancel'}
            variant="secondary"
            onPress={onDoneClose}
            style={{ marginTop: spacing.sm }}
          />
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flex: 1, backgroundColor: 'rgba(10,42,29,0.55)',
    alignItems: 'center', justifyContent: 'center', padding: spacing.lg,
  },
  card: {
    width: '100%', maxWidth: 380,
    borderRadius: radius.lg,
    padding: spacing.lg,
  },
  resultScroll: { maxHeight: 260 },
  busyWrap: { paddingVertical: spacing.lg, alignItems: 'center' },
});
'@)

# --- src\components\ExportModal.tsx ---
[System.IO.File]::WriteAllText('src\components\ExportModal.tsx', @'
import React, { useState } from 'react';
import { View, Modal, StyleSheet, Alert } from 'react-native';
import Text from './Text';
import Button from './Button';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';

interface ExportModalProps {
  visible: boolean;
  title: string;
  onClose: () => void;
  onExportCsv: () => Promise<void>;
  onExportPdf: () => Promise<void>;
}

// A tiny CSV-or-PDF picker, shared by any screen with a log to export
// (Visitors, Attendance). Both formats hand off to the OS share sheet
// once built -- see src/data/export.ts -- so this only needs to track
// which one is currently running.
export default function ExportModal({ visible, title, onClose, onExportCsv, onExportPdf }: ExportModalProps) {
  const { colors } = useTheme();
  const [busy, setBusy] = useState<'csv' | 'pdf' | null>(null);

  const run = async (kind: 'csv' | 'pdf', fn: () => Promise<void>) => {
    setBusy(kind);
    try {
      await fn();
      onClose();
    } catch (err) {
      Alert.alert('Could not export', err instanceof Error ? err.message : 'Something went wrong.');
    } finally {
      setBusy(null);
    }
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <View style={styles.wrap}>
        <View style={[styles.card, { backgroundColor: colors.surface }]}>
          <Text variant="h3">{title}</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            Choose a format to share or save.
          </Text>
          <Button
            label="Export as CSV"
            icon="document-text-outline"
            loading={busy === 'csv'}
            disabled={!!busy}
            onPress={() => run('csv', onExportCsv)}
            style={{ marginBottom: spacing.xs }}
          />
          <Button
            label="Export as PDF"
            icon="document-outline"
            variant="secondary"
            loading={busy === 'pdf'}
            disabled={!!busy}
            onPress={() => run('pdf', onExportPdf)}
          />
          <Button
            label="Cancel"
            variant="secondary"
            disabled={!!busy}
            onPress={onClose}
            style={{ marginTop: spacing.sm }}
          />
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flex: 1, backgroundColor: 'rgba(10,42,29,0.55)',
    alignItems: 'center', justifyContent: 'center', padding: spacing.lg,
  },
  card: {
    width: '100%', maxWidth: 360,
    borderRadius: radius.lg,
    padding: spacing.lg,
  },
});
'@)

# --- src\components\BookMeetingForm.tsx ---
[System.IO.File]::WriteAllText('src\components\BookMeetingForm.tsx', @'
import React, { useRef, useState } from 'react';
import { View, Pressable, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import Card from './Card';
import Button from './Button';
import Input from './Input';
import Select from './Select';
import MultiSelect from './MultiSelect';
import Segmented from './Segmented';
import Text from './Text';
import { DateChips, TimeChips } from './QuickDateTime';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { ApiError } from '../api/client';
import type { ExternalGuest } from '../types';

type LocationType = 'room' | 'outside';
type Priority = 'normal' | 'important' | 'urgent';

interface BookMeetingFormProps {
  onDone?: () => void;
}

// BookMeetingForm -- self-service internal meeting booking. Shared by
// Employee, Manager (EmployeeBookScreen) and Receptionist (the
// "Internal meeting" pane on VisitorBookingScreen), so an
// Administrator or anyone else can invite whoever they need -- not
// just their own direct reports -- and can book either one of the
// company's meeting rooms or an outside location (a client's office,
// a restaurant, etc.) for meetings that don't happen on-site. The
// organiser is derived server-side from the signed-in user's own
// employee record -- see RoomBookingController.
export default function BookMeetingForm({ onDone }: BookMeetingFormProps) {
  const { colors } = useTheme();
  const { employees, meetingRooms, bookRoom } = useData();

  const [title, setTitle] = useState('');
  const [locationType, setLocationType] = useState<LocationType>('room');
  const [roomId, setRoomId] = useState<string | null>(null);
  const [outsideLocation, setOutsideLocation] = useState('');
  const [attendeeIds, setAttendeeIds] = useState<string[]>([]);
  const [externalGuests, setExternalGuests] = useState<ExternalGuest[]>([]);
  const [guestName, setGuestName] = useState('');
  const [guestEmail, setGuestEmail] = useState('');
  const [guestPhone, setGuestPhone] = useState('');
  const [priority, setPriority] = useState<Priority>('normal');
  const [date, setDate] = useState(formatDate(new Date()));
  const [startTime, setStartTime] = useState('10:00');
  const [endTime, setEndTime] = useState('11:00');
  const [submitting, setSubmitting] = useState(false);
  const submittingRef = useRef(false);

  const onAddGuest = () => {
    if (!guestName.trim()) {
      Alert.alert('Almost there', "Give the guest's name.");
      return;
    }
    if (!guestEmail.trim() && !guestPhone.trim()) {
      Alert.alert('Almost there', 'Add an email or phone number so the guest can actually be reached.');
      return;
    }
    setExternalGuests((gs) => [...gs, {
      name: guestName.trim(), email: guestEmail.trim() || null, phone: guestPhone.trim() || null,
    }]);
    setGuestName(''); setGuestEmail(''); setGuestPhone('');
  };

  const onRemoveGuest = (index: number) => {
    setExternalGuests((gs) => gs.filter((_, i) => i !== index));
  };

  const onSubmit = async () => {
    if (submittingRef.current) return;
    const hasPlace = locationType === 'room' ? !!roomId : !!outsideLocation.trim();
    if (!title.trim() || !hasPlace) {
      Alert.alert('Almost there', locationType === 'room'
        ? 'Give the meeting a title and pick a room.'
        : 'Give the meeting a title and enter a location.');
      return;
    }
    submittingRef.current = true;
    setSubmitting(true);
    try {
      await bookRoom({
        title: title.trim(),
        roomId: locationType === 'room' ? roomId : null,
        location: locationType === 'outside' ? outsideLocation.trim() : '',
        startTime: toInstant(date, startTime),
        endTime: toInstant(date, endTime),
        participantIds: attendeeIds,
        externalGuests,
        priority,
      });
      Alert.alert('Booked', `${title} is on the calendar.`, [
        { text: 'Done', onPress: onDone },
      ]);
    } catch (err) {
      Alert.alert('Could not book meeting', err instanceof ApiError ? err.message : 'Something went wrong.');
    } finally {
      submittingRef.current = false;
      setSubmitting(false);
    }
  };

  return (
    <>
      <Card>
        <Input
          label="Meeting title"
          value={title}
          onChangeText={setTitle}
          placeholder="e.g. Candidate interview"
          icon="briefcase-outline"
        />

        <Segmented
          value={locationType}
          onChange={(v) => { setLocationType(v); setRoomId(null); setOutsideLocation(''); }}
          options={[
            { label: 'Meeting room', value: 'room' },
            { label: 'Outside location', value: 'outside' },
          ]}
          style={{ marginBottom: spacing.md }}
        />

        <Segmented
          value={priority}
          onChange={setPriority}
          options={[
            { label: 'Normal', value: 'normal' },
            { label: 'Important', value: 'important' },
            { label: 'Urgent', value: 'urgent' },
          ]}
          style={{ marginBottom: spacing.md }}
        />

        {locationType === 'room' ? (
          <Select
            label="Room"
            placeholder="Pick a room..."
            value={roomId}
            onChange={setRoomId}
            icon="business-outline"
            options={meetingRooms.map((r) => ({
              label: r.name, value: r.id, sublabel: `${r.floor} · Capacity ${r.capacity}`,
            }))}
          />
        ) : (
          <Input
            label="Location"
            value={outsideLocation}
            onChangeText={setOutsideLocation}
            placeholder="e.g. Client's office, Accra Mall"
            icon="location-outline"
          />
        )}

        <MultiSelect
          label="Invite staff (optional)"
          placeholder="Anyone from the staff directory..."
          values={attendeeIds}
          onChange={setAttendeeIds}
          icon="people-outline"
          options={employees.map((e) => ({
            label: e.name, value: e.id, sublabel: e.department,
          }))}
        />

        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>
          Outside guests (optional)
        </Text>
        {externalGuests.map((g, i) => (
          <View key={i} style={[styles.guestRow, { borderColor: colors.border }]}>
            <View style={{ flex: 1 }}>
              <Text variant="bodySemibold">{g.name}</Text>
              <Text variant="caption" color={colors.textSecondary}>
                {[g.email, g.phone].filter(Boolean).join(' - ')}
              </Text>
            </View>
            <Pressable onPress={() => onRemoveGuest(i)} hitSlop={8}>
              <Ionicons name="close-circle" size={20} color={colors.textMuted} />
            </Pressable>
          </View>
        ))}
        <Input
          label="Guest name"
          value={guestName}
          onChangeText={setGuestName}
          placeholder="e.g. Kwame Mensah (client)"
          icon="person-add-outline"
        />
        <View style={styles.guestContactRow}>
          <View style={{ flex: 1 }}>
            <Input label="Email" value={guestEmail} onChangeText={setGuestEmail}
              placeholder="them@example.com" icon="mail-outline" autoCapitalize="none" keyboardType="email-address" />
          </View>
          <View style={{ width: spacing.sm }} />
          <View style={{ flex: 1 }}>
            <Input label="Phone" value={guestPhone} onChangeText={setGuestPhone}
              placeholder="Optional" icon="call-outline" keyboardType="phone-pad" />
          </View>
        </View>
        <Pressable
          onPress={onAddGuest}
          style={[styles.addGuestBtn, { borderColor: colors.primary }]}
        >
          <Ionicons name="add-circle-outline" size={18} color={colors.primary} />
          <Text variant="bodySemibold" color={colors.primary} style={{ marginLeft: 6 }}>
            Add guest
          </Text>
        </Pressable>

        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>Date</Text>
        <DateChips value={date} onChange={setDate} />
        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>Start time</Text>
        <TimeChips value={startTime} onChange={setStartTime} />
        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>End time</Text>
        <TimeChips value={endTime} onChange={setEndTime} />
      </Card>

      <Button
        label="Book meeting"
        icon="checkmark-circle-outline"
        onPress={onSubmit}
        loading={submitting}
        style={{ marginTop: spacing.md }}
      />
    </>
  );
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

// The backend expects a full ISO instant (with seconds + timezone);
// "YYYY-MM-DDTHH:MM" alone isn't parseable as one and was silently
// failing every booking with a generic "Something went wrong" error.
// Routing through a real Date and toISOString() also correctly
// converts from the device's local time to UTC.
function toInstant(dateStr: string, timeStr: string): string {
  return new Date(`${dateStr}T${timeStr}:00`).toISOString();
}

const styles = StyleSheet.create({
  chipsLabel: { marginBottom: spacing.xs },
  guestRow: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    borderWidth: 1, borderRadius: radius.md,
    paddingHorizontal: spacing.sm, paddingVertical: spacing.sm,
    marginBottom: spacing.sm,
  },
  guestContactRow: { flexDirection: 'row' },
  addGuestBtn: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
    borderWidth: 1, borderRadius: radius.md, borderStyle: 'dashed',
    height: 44, marginBottom: spacing.md,
  },
});
'@)

# --- src\screens\DashboardScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\DashboardScreen.tsx', @'
import React, { useState } from 'react';
import { View, StyleSheet, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, StatTile, ListItem, ClockCard,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';
import type { IoniconName } from '../types';

interface DashboardScreenProps {
  navigation: RootStackNavigation;
}

// DashboardScreen -- the receptionist's landing page.
// Implements the four headline stats from the VisiLog User Guide:
//   1. Visitors Today
//   2. Currently Checked-In
//   3. Calls Today
//   4. Visitors This Month
// Plus pending appointment approvals and a Recent Visitor Logs preview.
export default function DashboardScreen({ navigation }: DashboardScreenProps) {
  const { colors } = useTheme();
  const { user } = useAuth();
  const { stats, visitors, appointments, employeeById, unreadNotificationCount, refreshAll } = useData();
  const [refreshing, setRefreshing] = useState(false);

  // Previously the only way to see something that changed server-side
  // (e.g. a pending appointment someone else booked) was to sign out
  // and back in -- pull down to refetch everything instead.
  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshAll();
    } finally {
      setRefreshing(false);
    }
  };

  // Personalise the greeting by time of day.
  const greeting = (() => {
    const h = new Date().getHours();
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  })();

  // Show the 5 most recent visitor records, newest first.
  const recent = [...visitors]
    .sort((a, b) => new Date(b.checkInAt).getTime() - new Date(a.checkInAt).getTime())
    .slice(0, 5);

  const pending = appointments.filter((a) => a.status === 'pending');

  return (
    <Screen refreshing={refreshing} onRefresh={onRefresh}>
      <Header
        eyebrow="VisiLog · Reception"
        title={`${greeting},`}
        subtitle={`${user?.name?.split(' ')[0] || 'there'} · Front desk`}
        rightIcon="notifications-outline"
        onRightPress={() => navigation.navigate('Notifications')}
        badge={unreadNotificationCount}
      />

      <ClockCard />

      {/* Four headline stats -- rendered as a 2x2 grid */}
      <View style={[styles.statsRow, { marginTop: spacing.md }]}>
        <StatTile icon="people" tint="primary" label="Visitors today" value={stats.visitorsToday} />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="checkmark-circle" tint="success" label="Currently on-site" value={stats.onsite} />
      </View>
      <View style={[styles.statsRow, { marginTop: spacing.sm }]}>
        <StatTile icon="call" tint="info" label="Calls today" value={stats.callsToday} />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="calendar" tint="pending" label="Visitors this month" value={stats.visitorsThisMonth} />
      </View>

      {/* Pending approvals call-out - only shown when there are some */}
      {pending.length > 0 && (
        <Pressable
          onPress={() => navigation.navigate('Appointments')}
          style={({ pressed }) => [styles.alert, { backgroundColor: colors.status.pending.bg }, pressed && { opacity: 0.9 }]}
        >
          <View style={styles.alertIcon}>
            <Ionicons name="time-outline" size={18} color={colors.status.pending.solid} />
          </View>
          <View style={{ flex: 1 }}>
            <Text variant="bodySemibold" color={colors.brand}>
              {pending.length} appointment{pending.length === 1 ? '' : 's'} need your review
            </Text>
            <Text variant="caption" color={colors.textSecondary}>
              Tap to admit or reject pending visitors.
            </Text>
          </View>
          <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
        </Pressable>
      )}

      {/* Quick actions -- Visitors, Directory, NFC lookup/cards & Call
          log all live here now instead of as their own tabs/More menu,
          since the bottom bar shrank to 4 tabs. */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.sectionEyebrow}>
        Quick actions
      </Text>
      <View style={styles.quickGrid}>
        <QuickAction
          icon="person-add" label="Register visitor"
          onPress={() => navigation.navigate('RegisterVisitor')}
        />
        <QuickAction
          icon="people-outline" label="Visitors"
          onPress={() => navigation.navigate('Visitors')}
        />
        <QuickAction
          icon="book-outline" label="Directory"
          onPress={() => navigation.navigate('Directory')}
        />
        <QuickAction
          icon="call-outline" label="Call log"
          onPress={() => navigation.navigate('CallLog')}
        />
        <QuickAction
          icon="scan-outline" label="NFC lookup"
          onPress={() => navigation.navigate('NFCLookup')}
        />
        <QuickAction
          icon="card-outline" label="NFC cards"
          onPress={() => navigation.navigate('NFCCards')}
        />
        <QuickAction
          icon="finger-print-outline" label="Attendance"
          onPress={() => navigation.navigate('Attendance')}
        />
        <QuickAction
          icon="document-text-outline" label="Reports"
          onPress={() => navigation.navigate('Reports')}
        />
        <QuickAction
          icon="time-outline" label="History"
          onPress={() => navigation.navigate('History')}
        />
      </View>

      {/* Recent visitor logs - preview that links to the full Visitors screen */}
      <View style={styles.sectionHeader}>
        <Text variant="h2">Recent visitor logs</Text>
        <Pressable onPress={() => navigation.navigate('Visitors')}>
          <Text variant="label" color={colors.primary}>
            View all
          </Text>
        </Pressable>
      </View>

      <Card padded={false}>
        {recent.map((v, i) => {
          const host = employeeById(v.hostId);
          return (
            <View key={v.id}>
              <ListItem
                avatarName={v.fullName}
                title={v.fullName}
                subtitle={`${v.purpose} - ${host?.name || 'No host'}`}
                meta={fmtTime(v.checkInAt)}
                right={
                  <Badge
                    label={v.status === 'onsite' ? 'On-site' : 'Completed'}
                    status={v.status === 'onsite' ? 'onsite' : 'neutral'}
                    size="sm"
                  />
                }
                chevron
                onPress={() => navigation.navigate('VisitorDetail', { visitorId: v.id })}
              />
              {i < recent.length - 1 ? <View style={[styles.sep, { backgroundColor: colors.border }]} /> : null}
            </View>
          );
        })}
      </Card>
    </Screen>
  );
}

// Local quick-action button - vertical icon-over-label tile.
function QuickAction({
  icon, label, onPress,
}: { icon: IoniconName; label: string; onPress: () => void }) {
  const { colors } = useTheme();
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [styles.qa, { backgroundColor: colors.surface, borderColor: colors.border }, pressed && { opacity: 0.85 }]}
    >
      <View style={[styles.qaIcon, { backgroundColor: colors.primarySurface }]}>
        <Ionicons name={icon} size={22} color={colors.primary} />
      </View>
      <Text variant="caption" color={colors.textPrimary} align="center" numberOfLines={2}>
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  statsRow: { flexDirection: 'row' },

  alert: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: radius.lg,
    padding: spacing.md,
    marginTop: spacing.md,
  },
  alertIcon: {
    width: 32, height: 32, borderRadius: 16,
    backgroundColor: '#FFFFFF',
    alignItems: 'center', justifyContent: 'center',
    marginRight: spacing.sm,
  },

  sectionEyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  quickGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.xs },
  qa: {
    width: '31%',
    borderRadius: radius.lg,
    borderWidth: 1,
    padding: spacing.sm,
    alignItems: 'center',
    minHeight: 84,
  },
  qaIcon: {
    width: 36, height: 36, borderRadius: 12,
    alignItems: 'center', justifyContent: 'center',
    marginBottom: 6,
  },

  sectionHeader: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-end',
    marginTop: spacing.xl, marginBottom: spacing.sm,
  },
  sep: { height: 1, marginLeft: spacing.md + 40 + spacing.sm },
});
'@)

# --- src\screens\ManagerHomeScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\ManagerHomeScreen.tsx', @'
import React, { useState } from 'react';
import { View, Pressable, StyleSheet } from 'react-native';
import {
  Screen, Header, Text, Card, Badge, StatTile, Avatar, ClockCard,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';

interface ManagerHomeScreenProps {
  navigation: RootStackNavigation;
}

// Manager dashboard: organisation-wide insight, plus the same
// clock-in/out card every other role gets -- an Administrator is staff
// too, and shows up on their own Clock-ins screen like everyone else.
export default function ManagerHomeScreen({ navigation }: ManagerHomeScreenProps) {
  const { colors, setOrgTheme } = useTheme();
  const { user, logout } = useAuth();
  const {
    stats, visitors, calls, employees, employeeById, unreadNotificationCount, refreshAll,
  } = useData();
  const onLogout = () => { logout(); setOrgTheme(null); };
  const [refreshing, setRefreshing] = useState(false);
  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshAll();
    } finally {
      setRefreshing(false);
    }
  };

  // Top hosts (employees with the most visitors).
  const hostCounts: Record<string, number> = {};
  visitors.forEach((v) => {
    hostCounts[v.hostId] = (hostCounts[v.hostId] || 0) + 1;
  });
  const topHosts = Object.entries(hostCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([id, count]) => ({ employee: employeeById(id), count }));

  return (
    <Screen refreshing={refreshing} onRefresh={onRefresh}>
      <Header
        eyebrow="Manager view"
        title="Overview"
        subtitle="Insight & attendance across the organisation"
        rightActions={[
          { icon: 'notifications-outline', onPress: () => navigation.navigate('Notifications'), badge: unreadNotificationCount },
          { icon: 'log-out-outline', onPress: onLogout },
        ]}
      />

      <ClockCard />

      <View style={{ flexDirection: 'row', marginTop: spacing.md }}>
        <StatTile icon="people" tint="primary" label="Visitors today" value={stats.visitorsToday} />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="checkmark-circle" tint="success" label="On-site" value={stats.onsite} />
      </View>
      <View style={{ flexDirection: 'row', marginTop: spacing.sm }}>
        <StatTile icon="call" tint="info" label="Calls today" value={stats.callsToday} />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="calendar" tint="pending" label="This month" value={stats.visitorsThisMonth} />
      </View>

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Top hosts
      </Text>
      <Card>
        {topHosts.map((h, i) => (
          <View key={h.employee?.id || i} style={styles.row}>
            <Text variant="bodySemibold" style={{ width: 24 }}>{i + 1}</Text>
            <Avatar name={h.employee?.name || '?'} size={36} />
            <View style={{ flex: 1, marginLeft: spacing.sm }}>
              <Text variant="bodySemibold">{h.employee?.name || 'Unknown'}</Text>
              <Text variant="caption" color={colors.textSecondary}>
                {h.employee?.department}
              </Text>
            </View>
            <Badge label={`${h.count} visits`} status="info" size="sm" dot={false} />
          </View>
        ))}
      </Card>

      <View style={styles.sectionHeader}>
        <Text variant="eyebrow" color={colors.textMuted}>
          Currently on-site
        </Text>
        <Pressable onPress={() => navigation.navigate('Visitors')}>
          <Text variant="label" color={colors.primary}>View all visitors</Text>
        </Pressable>
      </View>
      <Card>
        {visitors.filter((v) => v.status === 'onsite').map((v) => (
          <View key={v.id} style={styles.row}>
            <Avatar name={v.fullName} size={36} />
            <View style={{ flex: 1, marginLeft: spacing.sm }}>
              <Text variant="bodySemibold">{v.fullName}</Text>
              <Text variant="caption" color={colors.textSecondary}>
                {employeeById(v.hostId)?.name} - {fmtTime(v.checkInAt)}
              </Text>
            </View>
          </View>
        ))}
      </Card>
    </Screen>
  );
}

const styles = StyleSheet.create({
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: 8 },
  sectionHeader: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    marginTop: spacing.xl, marginBottom: spacing.sm,
  },
});
'@)

# --- src\screens\EmployeeHomeScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\EmployeeHomeScreen.tsx', @'
import React, { useState } from 'react';
import { View, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Button, Avatar, StatTile, ClockCard,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';

interface EmployeeHomeScreenProps {
  navigation: RootStackNavigation;
}

// Employee dashboard: check in/out for work, accept/decline visitors
// who picked them as host, view incoming calls, see their NFC card.
export default function EmployeeHomeScreen({ navigation }: EmployeeHomeScreenProps) {
  const { colors, setOrgTheme } = useTheme();
  const { user, logout } = useAuth();
  const {
    appointments, calls, updateAppointmentStatus, admitAppointment, unreadNotificationCount, refreshAll,
  } = useData();
  const onLogout = () => { logout(); setOrgTheme(null); };
  const [refreshing, setRefreshing] = useState(false);
  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshAll();
    } finally {
      setRefreshing(false);
    }
  };

  // The backend already scopes GET /appointments to only this employee's
  // own hosted visits (see AppointmentService.list) -- reception is the
  // only role that ever gets the whole org's list.
  const myPending = appointments.filter((a) => a.status === 'pending');
  const myCalls = calls.slice(0, 3);

  return (
    <Screen refreshing={refreshing} onRefresh={onRefresh}>
      <Header
        eyebrow="Employee dashboard"
        title={`Hi, ${user!.name?.split(' ')[0]}`}
        subtitle={user!.email}
        rightActions={[
          { icon: 'notifications-outline', onPress: () => navigation.navigate('Notifications'), badge: unreadNotificationCount },
          { icon: 'log-out-outline', onPress: onLogout },
        ]}
      />

      <ClockCard />

      {/* Stats */}
      <View style={{ flexDirection: 'row', marginTop: spacing.md }}>
        <StatTile icon="people" tint="primary"
          label="Pending visitors" value={myPending.length} />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="call" tint="info"
          label="Recent calls" value={myCalls.length} />
      </View>

      {/* Pending visitor requests */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Visitors waiting for you
      </Text>
      {myPending.length === 0 ? (
        <Card>
          <Text variant="body" color={colors.textSecondary}>
            No visitor requests at the moment.
          </Text>
        </Card>
      ) : (
        myPending.map((a) => (
          <Card key={a.id} style={{ marginBottom: spacing.sm }}>
            <View style={styles.requestRow}>
              <Avatar name={a.visitorName} size={40} />
              <View style={{ flex: 1, marginLeft: spacing.sm }}>
                <Text variant="bodySemibold">{a.visitorName}</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {a.purpose} - Code {a.nfcCode}
                </Text>
              </View>
            </View>
            <View style={{ flexDirection: 'row', marginTop: spacing.sm }}>
              <Button label="Decline" variant="secondary"
                onPress={() => updateAppointmentStatus(a.id, 'rejected')}
                style={{ flex: 1, marginRight: spacing.xs }} />
              <Button label="Accept"
                onPress={() => admitAppointment(a)}
                style={{ flex: 1, marginLeft: spacing.xs }} />
            </View>
          </Card>
        ))
      )}

      {/* Calls preview */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Recent calls for you
      </Text>
      <Card>
        {myCalls.length === 0 ? (
          <Text variant="body" color={colors.textSecondary}>No recent calls.</Text>
        ) : (
          myCalls.map((c) => (
            <View key={c.id} style={styles.callRow}>
              <Ionicons name="call" size={16} color={colors.primary} />
              <Text variant="bodyMd" style={{ flex: 1, marginLeft: 8 }}>
                {c.callerName}
              </Text>
              <Text variant="caption" color={colors.textMuted}>
                {fmtTime(c.timestamp)}
              </Text>
            </View>
          ))
        )}
      </Card>
    </Screen>
  );
}

const styles = StyleSheet.create({
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  requestRow: { flexDirection: 'row', alignItems: 'center' },
  callRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 6 },
});
'@)

# --- src\screens\VisitorHomeScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\VisitorHomeScreen.tsx', @'
import React, { useState } from 'react';
import { View, StyleSheet, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Text, Card, Badge, Avatar, CompanyMapSection,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtDate, fmtTime } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';
import type { IoniconName } from '../types';

interface VisitorHomeScreenProps {
  navigation: RootStackNavigation;
}

// VisitorHomeScreen -- the visitor's tab-bar landing page. The booking
// form itself now lives on its own "Book" tab (VisitorBookScreen); this
// screen is a dashboard: profile + notifications up top, a full-bleed
// virtual pass card in the org's own brand colors (or a prompt to
// book, if there isn't one yet), the submitted details, a visit-status
// timeline, and the company map/tour section.
export default function VisitorHomeScreen({ navigation }: VisitorHomeScreenProps) {
  const { colors } = useTheme();
  const { user } = useAuth();
  const { employees, appointments, unreadNotificationCount, refreshAll } = useData();
  const [refreshing, setRefreshing] = useState(false);
  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshAll();
    } finally {
      setRefreshing(false);
    }
  };

  const myBooking = appointments
    .filter((a) => a.bookedByEmail === user!.email)
    .sort((a, b) => new Date(b.scheduledAt).getTime() - new Date(a.scheduledAt).getTime())[0];

  const host = myBooking ? employees.find((e) => e.id === myBooking.hostId) : null;

  return (
    <Screen refreshing={refreshing} onRefresh={onRefresh}>
      <View style={styles.topRow}>
        <Pressable onPress={() => navigation.navigate('Settings')}>
          <Avatar name={user?.name || 'You'} size={44} />
        </Pressable>
        <Pressable
          onPress={() => navigation.navigate('Notifications')}
          style={[styles.bellBtn, { backgroundColor: colors.primarySurface }]}
          hitSlop={8}
        >
          <Ionicons name="notifications-outline" size={22} color={colors.brand} />
          {unreadNotificationCount > 0 ? (
            <View style={[styles.bellBadge, { backgroundColor: colors.status.rejected.solid }]}>
              <Text variant="caption" color="#FFFFFF" style={styles.bellBadgeText}>
                {unreadNotificationCount > 9 ? '9+' : unreadNotificationCount}
              </Text>
            </View>
          ) : null}
        </Pressable>
      </View>

      <Text style={[styles.welcome, { color: colors.textPrimary }]}>
        {myBooking
          ? `Welcome back, ${user!.name?.split(' ')[0] || 'there'}`
          : 'Ready to book your first appointment?'}
      </Text>
      <Text variant="body" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
        {myBooking
          ? "Here's your latest visit pass."
          : 'Head to the Book tab to schedule a visit and get your NFC pass.'}
      </Text>

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Your virtual card
      </Text>
      {myBooking ? (
        <>
          {/* Full-bleed pass card in the org's own brand colors */}
          <View style={[styles.passCard, { backgroundColor: colors.brand }]}>
            <View style={styles.passHead}>
              <View style={[styles.chip, { backgroundColor: colors.primary }]}>
                <Ionicons name="hardware-chip" size={20} color={colors.brandDark} />
              </View>
              <Ionicons name="wifi" size={22} color="rgba(255,255,255,0.6)" style={{ transform: [{ rotate: '90deg' }] }} />
            </View>

            <Text style={styles.passEyebrow}>
              {myBooking.nfcCode ? `VISITOR PASS - #${myBooking.nfcCode}` : 'VISITOR PASS - PENDING APPROVAL'}
            </Text>
            <Text style={styles.passName} numberOfLines={1}>{user?.name || 'Visitor'}</Text>

            <View style={styles.passMetaRow}>
              <View style={{ flex: 1 }}>
                <Text style={styles.passMetaLabel}>Host</Text>
                <Text style={styles.passMetaValue} numberOfLines={1}>
                  {host?.name || '--'}
                </Text>
              </View>
              <View style={{ flex: 1 }}>
                <Text style={styles.passMetaLabel}>Scheduled</Text>
                <Text style={styles.passMetaValue} numberOfLines={1}>
                  {fmtDate(myBooking.scheduledAt)} · {fmtTime(myBooking.scheduledAt)}
                </Text>
              </View>
            </View>

            <View style={[styles.passDivider, { backgroundColor: 'rgba(255,255,255,0.18)' }]} />

            <View style={styles.passStatusRow}>
              <View style={[styles.passDot, { backgroundColor: colors.primary }]} />
              <Text style={[styles.passStatusText, { color: colors.primary }]}>
                Present this card at reception to check in
              </Text>
            </View>
          </View>

          {/* Details you submitted */}
          <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
            Details you submitted
          </Text>
          <Card>
            <DetailRow label="Company" value={myBooking.visitorCompany || '--'} />
            <View style={[styles.hairline, { backgroundColor: colors.border }]} />
            <DetailRow label="Purpose" value={myBooking.purpose || '--'} />
            <View style={[styles.hairline, { backgroundColor: colors.border }]} />
            <DetailRow label="Contact" value={myBooking.visitorPhone || '--'} />
          </Card>

          {/* Visit status timeline */}
          <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
            Visit status
          </Text>
          <Card>
            <TimelineStep
              done
              icon="checkmark"
              label="Details submitted"
              sub={`${fmtDate(myBooking.scheduledAt)} · ${fmtTime(myBooking.scheduledAt)}`}
              isLast={false}
            />
            {myBooking.status === 'rejected' ? (
              <TimelineStep
                done
                negative
                icon="close"
                label="Request declined"
                sub="This visit was not approved."
                isLast
              />
            ) : myBooking.status === 'admitted' ? (
              <TimelineStep
                done
                icon="checkmark"
                label="Approved · card issued"
                sub="You're all set for your visit."
                isLast
              />
            ) : (
              <TimelineStep
                done={false}
                icon="time-outline"
                label="Awaiting approval"
                sub="Reception will review your visit shortly."
                isLast
              />
            )}
          </Card>
        </>
      ) : (
        <Card>
          <View style={styles.emptyCard}>
            <Ionicons name="card-outline" size={28} color={colors.textMuted} />
            <Text variant="bodySemibold" color={colors.textSecondary} style={{ marginTop: 8 }}>
              No upcoming visit
            </Text>
            <Text variant="caption" color={colors.textMuted}>
              Book one below to get your NFC pass.
            </Text>
          </View>
        </Card>
      )}

      <CompanyMapSection />
    </Screen>
  );
}

function DetailRow({ label, value }: { label: string; value: string }) {
  const { colors } = useTheme();
  return (
    <View style={styles.detailRow}>
      <Text variant="body" color={colors.textSecondary}>{label}</Text>
      <Text variant="bodySemibold">{value}</Text>
    </View>
  );
}

interface TimelineStepProps {
  done: boolean;
  negative?: boolean;
  icon: IoniconName;
  label: string;
  sub: string;
  isLast: boolean;
}

function TimelineStep({ done, negative, icon, label, sub, isLast }: TimelineStepProps) {
  const { colors } = useTheme();
  const dotColor = negative ? colors.status.rejected.solid : done ? colors.status.success.solid : colors.borderStrong;
  return (
    <View style={styles.timelineRow}>
      <View style={styles.timelineRail}>
        <View style={[styles.timelineDot, { backgroundColor: dotColor }]}>
          {done ? <Ionicons name={icon} size={12} color="#FFFFFF" /> : null}
        </View>
        {!isLast ? <View style={[styles.timelineLine, { backgroundColor: colors.border }]} /> : null}
      </View>
      <View style={{ flex: 1, paddingBottom: isLast ? 0 : spacing.md }}>
        <Text variant="bodySemibold" color={done ? colors.textPrimary : colors.textSecondary}>
          {label}
        </Text>
        <Text variant="caption" color={colors.textMuted}>{sub}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  topRow: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    marginBottom: spacing.md,
  },
  bellBtn: {
    width: 40, height: 40, borderRadius: 20,
    alignItems: 'center', justifyContent: 'center',
  },
  bellBadge: {
    position: 'absolute', top: 2, right: 2,
    minWidth: 16, height: 16, borderRadius: 8, paddingHorizontal: 3,
    alignItems: 'center', justifyContent: 'center',
  },
  bellBadgeText: { fontSize: 10, lineHeight: 12 },
  welcome: { fontFamily: fonts.displayBold, fontSize: 22 },
  eyebrow: { marginTop: spacing.md, marginBottom: spacing.sm },

  // Pass card
  passCard: {
    borderRadius: radius.xl,
    padding: spacing.lg,
  },
  passHead: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    marginBottom: spacing.lg,
  },
  chip: {
    width: 40, height: 28, borderRadius: 6,
    alignItems: 'center', justifyContent: 'center',
  },
  passEyebrow: {
    fontFamily: fonts.semibold, fontSize: 11, letterSpacing: 1,
    color: 'rgba(255,255,255,0.65)', marginBottom: 6,
  },
  passName: {
    fontFamily: fonts.displayExtra, fontSize: 26, lineHeight: 32,
    color: '#FFFFFF', marginBottom: spacing.md,
  },
  passMetaRow: { flexDirection: 'row' },
  passMetaLabel: {
    fontFamily: fonts.medium, fontSize: 11,
    color: 'rgba(255,255,255,0.6)', marginBottom: 2,
  },
  passMetaValue: {
    fontFamily: fonts.semibold, fontSize: 14, color: '#FFFFFF',
  },
  passDivider: { height: 1, marginVertical: spacing.md },
  passStatusRow: { flexDirection: 'row', alignItems: 'center' },
  passDot: { width: 8, height: 8, borderRadius: 4, marginRight: 8 },
  passStatusText: { fontFamily: fonts.semibold, fontSize: 12, flex: 1 },

  // Details
  detailRow: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingVertical: spacing.xs,
  },
  hairline: { height: 1 },

  // Timeline
  timelineRow: { flexDirection: 'row' },
  timelineRail: { alignItems: 'center', width: 24, marginRight: spacing.sm },
  timelineDot: {
    width: 22, height: 22, borderRadius: 11,
    alignItems: 'center', justifyContent: 'center',
  },
  timelineLine: { width: 2, flex: 1, marginVertical: 4 },

  emptyCard: { alignItems: 'center', paddingVertical: spacing.sm },
});
'@)

# --- src\screens\NotificationsScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\NotificationsScreen.tsx', @'
import React, { useCallback, useState } from 'react';
import {
  View, FlatList, Pressable, StyleSheet, Modal, TextInput, KeyboardAvoidingView, Alert,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Button, EmptyState } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtRelative } from '../data/format';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type { AppNotification, IoniconName, NotificationType, RoomBookingResponse } from '../types';

// One icon per notification type -- anything not listed (shouldn't
// happen, but keeps this forward-compatible with a type this build
// doesn't know about yet) falls back to a plain bell.
const NOTIFICATION_ICONS: Record<NotificationType, IoniconName> = {
  meeting_invite: 'calendar-outline',
  meeting_declined: 'close-circle-outline',
  visit_admitted: 'card-outline',
  visit_rejected: 'close-circle-outline',
  visit_checked_out: 'exit-outline',
  appointment_requested: 'person-add-outline',
  appointment_rescheduled: 'swap-horizontal-outline',
  call_logged: 'call-outline',
  participant_absent: 'close-circle-outline',
};

interface NotificationsScreenProps {
  navigation: RootStackNavigation;
}

// NotificationsScreen -- in-app alerts (meeting invites, and an
// organiser being told someone declined). Reached from the bell icon
// on the Home header. There's no push/SMS delivery in this build, so
// this list (fetched on focus) is the only place these show up -- see
// NotificationService on the backend.
export default function NotificationsScreen({ navigation }: NotificationsScreenProps) {
  const { user } = useAuth();
  const {
    notifications, refreshNotifications, markNotificationRead, roomBookings, respondToMeeting,
  } = useData();
  const [refreshing, setRefreshing] = useState(false);
  const [declining, setDeclining] = useState<AppNotification | null>(null);

  useFocusEffect(
    useCallback(() => {
      refreshNotifications();
    }, [])
  );

  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshNotifications();
    } finally {
      setRefreshing(false);
    }
  };

  const sorted = [...notifications].sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
  );

  // A participant's own response row for the meeting a notification
  // points at -- undefined once the organiser sees it (they don't get
  // a response row for their own meeting) or for non-invite types.
  const myResponseFor = (n: AppNotification): RoomBookingResponse | undefined => {
    if (n.type !== 'meeting_invite' || !n.relatedId || !user?.employeeId) return undefined;
    const booking = roomBookings.find((b) => b.id === n.relatedId);
    return booking?.responses.find((r) => r.employeeId === user.employeeId);
  };

  const onAcknowledge = async (n: AppNotification) => {
    if (!n.relatedId) return;
    try {
      await respondToMeeting(n.relatedId, 'acknowledged');
      markNotificationRead(n.id);
    } catch (err) {
      Alert.alert('Could not respond', err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  const onConfirmDecline = async (reason: string) => {
    if (!declining?.relatedId) return;
    try {
      await respondToMeeting(declining.relatedId, 'declined', reason);
      markNotificationRead(declining.id);
      setDeclining(null);
    } catch (err) {
      Alert.alert('Could not decline', err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Notifications"
          subtitle={sorted.length ? `${sorted.length} total` : undefined}
          onBackPress={() => navigation.goBack()}
        />
      </View>

      <FlatList
        data={sorted}
        keyExtractor={(n) => n.id}
        contentContainerStyle={styles.list}
        refreshing={refreshing}
        onRefresh={onRefresh}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="notifications-outline"
            title="No notifications yet"
            message="Meeting invites and other alerts will show up here."
          />
        }
        renderItem={({ item }) => (
          <NotificationRow
            notification={item}
            myResponse={myResponseFor(item)}
            onPress={() => markNotificationRead(item.id)}
            onAcknowledge={() => onAcknowledge(item)}
            onDecline={() => setDeclining(item)}
          />
        )}
      />

      <DeclineReasonModal
        visible={!!declining}
        onCancel={() => setDeclining(null)}
        onConfirm={onConfirmDecline}
      />
    </Screen>
  );
}

function NotificationRow({
  notification, myResponse, onPress, onAcknowledge, onDecline,
}: {
  notification: AppNotification;
  myResponse: RoomBookingResponse | undefined;
  onPress: () => void;
  onAcknowledge: () => void;
  onDecline: () => void;
}) {
  const { colors: themeColors } = useTheme();
  const canRespond = notification.type === 'meeting_invite' && myResponse?.status === 'pending';

  return (
    <Pressable onPress={onPress} disabled={notification.read}>
      <Card padded={false} style={{ marginHorizontal: spacing.md }}>
        <View style={styles.row}>
          <View style={[styles.iconWrap, { backgroundColor: themeColors.primarySurface }]}>
            <Ionicons
              name={NOTIFICATION_ICONS[notification.type] || 'notifications-outline'}
              size={18}
              color={themeColors.primary}
            />
          </View>
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <View style={styles.rowTop}>
              <Text variant="bodySemibold" numberOfLines={1}>{notification.title}</Text>
              {!notification.read ? (
                <View style={[styles.unreadDot, { backgroundColor: themeColors.palette.red600 }]} />
              ) : null}
            </View>
            <Text variant="body" color={themeColors.textSecondary}>{notification.body}</Text>
            <Text variant="caption" color={themeColors.textMuted} style={{ marginTop: 2 }}>
              {fmtRelative(notification.createdAt)}
            </Text>

            {canRespond ? (
              <View style={styles.actionRow}>
                <Button
                  label="Seen it"
                  icon="checkmark-circle-outline"
                  variant="secondary"
                  size="sm"
                  onPress={onAcknowledge}
                  style={{ flex: 1, marginRight: spacing.xs }}
                />
                <Button
                  label="Can't make it"
                  icon="close-circle-outline"
                  variant="secondary"
                  size="sm"
                  onPress={onDecline}
                  style={{ flex: 1, marginLeft: spacing.xs }}
                />
              </View>
            ) : myResponse?.status === 'acknowledged' ? (
              <View style={styles.respondedRow}>
                <Ionicons name="checkmark-circle" size={14} color={themeColors.primary} />
                <Text variant="caption" color={themeColors.primary} style={{ marginLeft: 4 }}>
                  You said you've seen this
                </Text>
              </View>
            ) : myResponse?.status === 'declined' ? (
              <View style={styles.respondedRow}>
                <Ionicons name="close-circle" size={14} color={themeColors.status.rejected.solid} />
                <Text variant="caption" color={themeColors.status.rejected.solid} style={{ marginLeft: 4 }}>
                  You declined
                </Text>
              </View>
            ) : null}
          </View>
        </View>
      </Card>
    </Pressable>
  );
}

// A reason is required to decline (per RoomBookingService.respond),
// and Android has no built-in Alert.prompt, so this is a small custom
// modal -- same pattern as RescheduleModal's reason field.
function DeclineReasonModal({
  visible, onCancel, onConfirm,
}: { visible: boolean; onCancel: () => void; onConfirm: (reason: string) => void }) {
  const { colors } = useTheme();
  const [reason, setReason] = useState('');

  const onSubmit = () => {
    if (!reason.trim()) {
      Alert.alert('Almost there', "Let the organiser know why you can't make it.");
      return;
    }
    onConfirm(reason.trim());
    setReason('');
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onCancel}>
      <KeyboardAvoidingView style={modalStyles.wrap} behavior="padding">
        <View style={[modalStyles.card, { backgroundColor: colors.surface }]}>
          <Text variant="h3">Can't make it?</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            Let the organiser know why -- they'll see this right away.
          </Text>
          <TextInput
            value={reason}
            onChangeText={setReason}
            placeholder="e.g. I have another commitment that day"
            placeholderTextColor={colors.textMuted}
            style={[modalStyles.input, { borderColor: colors.border, color: colors.textPrimary }]}
            multiline
          />
          <View style={modalStyles.row}>
            <Pressable onPress={onCancel} style={[modalStyles.btn, { backgroundColor: colors.surfaceAlt }]}>
              <Text variant="bodySemibold" color={colors.textSecondary}>Cancel</Text>
            </Pressable>
            <Pressable onPress={onSubmit} style={[modalStyles.btn, { backgroundColor: colors.brand }]}>
              <Text variant="bodySemibold" color={colors.textInverse}>Send</Text>
            </Pressable>
          </View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  row: { flexDirection: 'row', alignItems: 'flex-start', padding: spacing.md },
  iconWrap: {
    width: 40, height: 40, borderRadius: radius.md,
    alignItems: 'center', justifyContent: 'center',
  },
  rowTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: 8 },
  unreadDot: {
    width: 8, height: 8, borderRadius: 4,
  },
  actionRow: { flexDirection: 'row', marginTop: spacing.sm },
  respondedRow: { flexDirection: 'row', alignItems: 'center', marginTop: spacing.xs },
});

const modalStyles = StyleSheet.create({
  wrap: {
    flex: 1, backgroundColor: 'rgba(10,42,29,0.55)',
    alignItems: 'center', justifyContent: 'center', padding: spacing.lg,
  },
  card: {
    width: '100%', maxWidth: 360,
    borderRadius: radius.lg,
    padding: spacing.lg,
  },
  input: {
    borderWidth: 1, borderRadius: radius.md,
    paddingHorizontal: spacing.sm, paddingVertical: 10, minHeight: 80, textAlignVertical: 'top',
    fontFamily: fonts.regular, fontSize: 14,
  },
  row: { flexDirection: 'row', marginTop: spacing.md, gap: spacing.sm },
  btn: { flex: 1, height: 44, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center' },
});
'@)

# --- src\screens\AppointmentsScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\AppointmentsScreen.tsx', @'
import React, { useCallback, useMemo, useRef, useState } from 'react';
import {
  View, FlatList, StyleSheet, Alert, Modal, TextInput, Pressable, KeyboardAvoidingView, ScrollView,
  RefreshControl,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, Button, Segmented, EmptyState, Avatar, RescheduleModal,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtTime, fmtDate } from '../data/format';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type {
  Appointment, AppointmentStatus, IoniconName, MeetingRoom, RoomBooking, StatusKey,
} from '../types';

interface AppointmentsScreenProps {
  navigation: RootStackNavigation;
}

type AppointmentsView = 'appointments' | 'rooms';

// AppointmentsScreen
// Pre-scheduled visits with three statuses from the spec:
//   - Pending  (needs receptionist action)
//   - Admitted (already approved + checked in)
//   - Rejected (denied entry)
// Each pending row has one-tap Admit / Reject buttons. A top-level
// slider also switches over to a Meeting Rooms view (available /
// booked / in-use), since reception manages both from one screen.
export default function AppointmentsScreen({ navigation }: AppointmentsScreenProps) {
  const [view, setView] = useState<AppointmentsView>('appointments');

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title={view === 'appointments' ? 'Appointments' : 'Meetings'}
          subtitle={view === 'appointments' ? 'Pre-booked visits & approvals' : 'Everything booked, on-site or outside'}
          rightIcon="time-outline"
          onRightPress={() => navigation.navigate('History', { tab: view === 'appointments' ? 'appointments' : 'meetings' })}
        />
        <Segmented
          value={view}
          onChange={setView}
          options={[
            { label: 'Appointments', value: 'appointments' },
            { label: 'Meetings', value: 'rooms' },
          ]}
          style={{ marginBottom: spacing.sm }}
        />
      </View>

      {view === 'appointments' ? <AppointmentsList /> : <MeetingsView />}
    </Screen>
  );
}

type AppointmentFilter = AppointmentStatus | 'all';

function AppointmentsList() {
  const { user } = useAuth();
  const { appointments, updateAppointmentStatus, admitAppointment, refreshAll } = useData();
  const [filter, setFilter] = useState<AppointmentFilter>('pending');
  const [rescheduling, setRescheduling] = useState<Appointment | null>(null);
  const [rejecting, setRejecting] = useState<Appointment | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  // Previously the only way to see a new pending appointment someone
  // else just booked was to sign out and back in -- pull down to
  // refetch everything instead.
  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshAll();
    } finally {
      setRefreshing(false);
    }
  };
  // Only Employees (and Visitors, on their own Visits screen) can edit
  // an appointment's time -- Receptionist/Manager use Admit/Reject instead.
  const canReschedule = user?.role === 'employee';
  // Tapping "Admit" twice before the first request finishes used to
  // check the same visitor in twice -- the row doesn't leave the
  // pending list until the response comes back, so a second tap in
  // that window fired a second, real admit. Track in-flight ids
  // synchronously (a ref, not state) so the second tap is ignored.
  const admittingRef = useRef(new Set<string>());

  const filtered = useMemo(
    () => appointments
      .filter((a) => filter === 'all' || a.status === filter)
      .sort((a, b) => new Date(b.scheduledAt).getTime() - new Date(a.scheduledAt).getTime()),
    [appointments, filter]
  );

  const onAdmit = (appt: Appointment) => {
    if (admittingRef.current.has(appt.id)) return;
    Alert.alert(
      'Admit visitor?',
      `${appt.visitorName} will be registered and checked in.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Admit',
          onPress: async () => {
            if (admittingRef.current.has(appt.id)) return;
            admittingRef.current.add(appt.id);
            try {
              const v = await admitAppointment(appt);
              Alert.alert('Admitted', `${v.fullName} - ${v.badgeId}`);
            } catch (err) {
              Alert.alert('Could not admit visitor', err instanceof ApiError ? err.message : 'Something went wrong.');
            } finally {
              admittingRef.current.delete(appt.id);
            }
          },
        },
      ]
    );
  };

  const onReject = (appt: Appointment) => setRejecting(appt);

  const onConfirmReject = async (reason: string) => {
    if (!rejecting) return;
    try {
      await updateAppointmentStatus(rejecting.id, 'rejected', reason);
      setRejecting(null);
    } catch (err) {
      Alert.alert('Could not reject', err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  return (
    <>
      <View style={styles.subHead}>
        <Segmented
          value={filter}
          onChange={setFilter}
          options={[
            { label: 'Pending', value: 'pending' },
            { label: 'Admitted', value: 'admitted' },
            { label: 'Rejected', value: 'rejected' },
            { label: 'All', value: 'all' },
          ]}
        />
      </View>

      <FlatList
        data={filtered}
        keyExtractor={(a) => a.id}
        contentContainerStyle={styles.list}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="calendar-outline"
            title="No appointments here"
            message={
              filter === 'pending'
                ? "You're all caught up - no visitors waiting for approval."
                : 'Try a different filter to see appointments in other states.'
            }
          />
        }
        renderItem={({ item }) => (
          <AppointmentRow
            appointment={item}
            canAct={!!user?.employeeId && user.employeeId === item.hostId}
            onAdmit={() => onAdmit(item)}
            onReject={() => onReject(item)}
            onReschedule={canReschedule ? () => setRescheduling(item) : null}
          />
        )}
      />

      <RescheduleModal
        appointment={rescheduling}
        visible={!!rescheduling}
        onClose={() => setRescheduling(null)}
      />

      <RejectReasonModal
        visible={!!rejecting}
        visitorName={rejecting?.visitorName || ''}
        canReschedule={canReschedule}
        onCancel={() => setRejecting(null)}
        onConfirm={onConfirmReject}
        onRescheduleInstead={() => {
          const appt = rejecting;
          setRejecting(null);
          if (appt) setRescheduling(appt);
        }}
      />
    </>
  );
}

interface AppointmentRowProps {
  appointment: Appointment;
  canAct: boolean;
  onAdmit: () => void;
  onReject: () => void;
  onReschedule: (() => void) | null;
}

function AppointmentRow({ appointment, canAct, onAdmit, onReject, onReschedule }: AppointmentRowProps) {
  const { colors } = useTheme();
  const { employeeById } = useData();
  const host = employeeById(appointment.hostId);
  const accent: StatusKey =
    appointment.status === 'admitted' ? 'success' :
    appointment.status === 'rejected' ? 'rejected' :
    'pending';
  const badgeStatus: StatusKey =
    appointment.status === 'admitted' ? 'success' :
    appointment.status === 'rejected' ? 'rejected' :
    'pending';

  return (
    <Card accent={accent} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.headRow}>
        <Avatar name={appointment.visitorName} size={44} />
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold">{appointment.visitorName}</Text>
          <Text variant="caption" color={colors.textSecondary}>
            {appointment.visitorCompany || 'Visitor'}
          </Text>
        </View>
        <Badge label={appointment.status} status={badgeStatus} size="sm" />
      </View>

      <View style={styles.metaList}>
        <MetaRow icon="people-outline" text={`Host: ${host?.name || 'Unassigned'}`} />
        <MetaRow icon="briefcase-outline" text={appointment.purpose} />
        <MetaRow
          icon="time-outline"
          text={`${fmtDate(appointment.scheduledAt)} - ${fmtTime(appointment.scheduledAt)}`}
        />
        {/* NFC code, visible so reception can read it aloud if a card fails --
            only assigned once admitted, see AppointmentService.admit */}
        <MetaRow icon="card-outline" text={`Code: ${appointment.nfcCode || 'Not yet issued'}`} />
        {appointment.rescheduleReason ? (
          <MetaRow icon="swap-horizontal-outline" text={`Rescheduled: ${appointment.rescheduleReason}`} />
        ) : null}
        {appointment.rejectReason ? (
          <MetaRow icon="close-circle-outline" text={`Rejected: ${appointment.rejectReason}`} />
        ) : null}
      </View>

      {onReschedule && (
        <Button
          label="Reschedule"
          variant="secondary"
          icon="calendar-outline"
          onPress={onReschedule}
          style={{ marginBottom: spacing.xs }}
        />
      )}

      {appointment.status === 'pending' && canAct && (
        <View style={styles.actionRow}>
          <Button
            label="Reject"
            variant="secondary"
            icon="close-circle-outline"
            onPress={onReject}
            style={{ flex: 1, marginRight: spacing.xs }}
          />
          <Button
            label="Admit"
            icon="checkmark-circle-outline"
            onPress={onAdmit}
            style={{ flex: 1, marginLeft: spacing.xs }}
          />
        </View>
      )}
    </Card>
  );
}

interface RejectReasonModalProps {
  visible: boolean;
  visitorName: string;
  canReschedule: boolean;
  onCancel: () => void;
  onConfirm: (reason: string) => void;
  onRescheduleInstead: () => void;
}

// A reason is now required to reject a visit (per the backend guard in
// AppointmentService.updateStatus) so the host always has a record of
// why -- and if the real issue is just bad timing, "Reschedule instead"
// routes to RescheduleModal rather than turning the visitor away.
function RejectReasonModal({
  visible, visitorName, canReschedule, onCancel, onConfirm, onRescheduleInstead,
}: RejectReasonModalProps) {
  const { colors } = useTheme();
  const [reason, setReason] = useState('');

  const onSubmit = () => {
    if (!reason.trim()) {
      Alert.alert('Almost there', 'Please give a reason for rejecting this visit.');
      return;
    }
    onConfirm(reason.trim());
    setReason('');
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onCancel}>
      <KeyboardAvoidingView style={rejectStyles.wrap} behavior="padding">
        <View style={[rejectStyles.card, { backgroundColor: colors.surface }]}>
          <Text variant="h3">Reject visitor?</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            {visitorName} will be denied entry. Let them know why.
          </Text>
          <TextInput
            value={reason}
            onChangeText={setReason}
            placeholder="e.g. No availability that day"
            placeholderTextColor={colors.textMuted}
            style={[rejectStyles.input, { borderColor: colors.border, color: colors.textPrimary }]}
            multiline
          />
          {canReschedule ? (
            <Pressable onPress={onRescheduleInstead} style={rejectStyles.rescheduleLink}>
              <Ionicons name="calendar-outline" size={16} color={colors.primary} />
              <Text variant="caption" color={colors.primary} style={{ marginLeft: 6 }}>
                Just a scheduling conflict? Reschedule instead
              </Text>
            </Pressable>
          ) : null}
          <View style={rejectStyles.row}>
            <Pressable onPress={onCancel} style={[rejectStyles.btn, { backgroundColor: colors.surfaceAlt }]}>
              <Text variant="bodySemibold" color={colors.textSecondary}>Cancel</Text>
            </Pressable>
            <Pressable onPress={onSubmit} style={[rejectStyles.btn, { backgroundColor: colors.brand }]}>
              <Text variant="bodySemibold" color={colors.textInverse}>Reject</Text>
            </Pressable>
          </View>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

function MetaRow({ icon, text }: { icon: IoniconName; text: string }) {
  const { colors } = useTheme();
  return (
    <View style={styles.metaRow}>
      <Ionicons name={icon} size={14} color={colors.textMuted} />
      <Text variant="caption" color={colors.textSecondary} style={{ marginLeft: 6 }}>
        {text}
      </Text>
    </View>
  );
}

// ---- Meeting Rooms view: available / booked / in-use ----

type RoomStatus = 'available' | 'booked' | 'inuse';

function roomStatus(
  room: MeetingRoom, roomBookings: RoomBooking[]
): { status: RoomStatus; booking: RoomBooking | null } {
  const now = Date.now();
  const forRoom = roomBookings.filter((b) => b.roomId === room.id);
  const live = forRoom.find(
    (b) => new Date(b.startTime).getTime() <= now && new Date(b.endTime).getTime() > now
  );
  if (live) return { status: 'inuse', booking: live };
  const upcoming = forRoom
    .filter((b) => new Date(b.startTime).getTime() > now)
    .sort((a, b) => new Date(a.startTime).getTime() - new Date(b.startTime).getTime())[0];
  if (upcoming) return { status: 'booked', booking: upcoming };
  return { status: 'available', booking: null };
}

const ROOM_STATUS_META: Record<RoomStatus, { label: string; badge: StatusKey }> = {
  available: { label: 'Available', badge: 'success' },
  booked: { label: 'Booked', badge: 'pending' },
  inuse: { label: 'In use', badge: 'onsite' },
};

// A single FlatList drives the whole screen (every upcoming meeting,
// room-based or an outside location -- previously an outside-location
// booking never showed up *anywhere* after you made it, and a room
// with several bookings only ever showed the single soonest one). The
// per-room availability cards sit in the header as a plain, short,
// non-virtualized list -- nesting a second FlatList in there would
// trigger RN's "VirtualizedLists should never be nested" warning.
// Lets the organiser tell at a glance who's seen the invite and who's
// declined (and see the reason via the row itself is enough detail for
// now -- a full per-person breakdown wasn't asked for).
function responseSummary(responses: RoomBooking['responses']): string {
  const acknowledged = responses.filter((r) => r.status === 'acknowledged').length;
  const declined = responses.filter((r) => r.status === 'declined').length;
  const pending = responses.length - acknowledged - declined;
  const parts: string[] = [];
  if (acknowledged) parts.push(`${acknowledged} seen`);
  if (declined) parts.push(`${declined} declined`);
  if (pending) parts.push(`${pending} pending`);
  return parts.join(' · ') || 'No responses yet';
}

function MeetingsView() {
  const { colors } = useTheme();
  const { user } = useAuth();
  const {
    roomBookings, meetingRooms, employeeById, roomById, refreshRoomBookings, markParticipantAbsent,
  } = useData();
  const [attendanceForId, setAttendanceForId] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  useFocusEffect(
    useCallback(() => {
      refreshRoomBookings().catch(() => {});
    }, [])
  );

  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshRoomBookings();
    } finally {
      setRefreshing(false);
    }
  };

  const attendanceBooking = roomBookings.find((b) => b.id === attendanceForId) || null;

  const onToggleAbsent = (employeeId: string, absent: boolean) => {
    if (!attendanceForId) return;
    markParticipantAbsent(attendanceForId, employeeId, absent).catch(
      (err) => Alert.alert('Could not update attendance', err instanceof ApiError ? err.message : 'Something went wrong.')
    );
  };

  const rooms = useMemo(
    () => meetingRooms.map((r) => ({ room: r, ...roomStatus(r, roomBookings) })),
    [roomBookings, meetingRooms]
  );

  // Not filtered by time at all -- BookMeetingForm defaults to today's
  // date with a fixed 10:00-11:00 window, so a meeting booked later in
  // the day is technically "in the past" the instant it's created; an
  // "upcoming only" filter made it vanish immediately with no way to
  // find it. Newest-booked first, so whatever you just booked is right
  // at the top regardless of what time you picked.
  const sortedMeetings = useMemo(
    () => [...roomBookings].sort((a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime()),
    [roomBookings]
  );

  return (
    <>
    <FlatList
      data={sortedMeetings}
      keyExtractor={(b) => b.id}
      contentContainerStyle={styles.list}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
      ListHeaderComponent={
        <>
          {rooms.length > 0 ? (
            <>
              <Text variant="eyebrow" color={colors.textMuted} style={styles.sectionLabel}>
                Rooms
              </Text>
              {rooms.map(({ room, status, booking }) => {
                const meta = ROOM_STATUS_META[status];
                return (
                  <Card key={room.id} style={{ marginBottom: spacing.sm }}>
                    <View style={styles.headRow}>
                      <View style={[styles.roomIcon, { backgroundColor: colors.primarySurface }]}>
                        <Ionicons name="business" size={20} color={colors.primary} />
                      </View>
                      <View style={{ flex: 1, marginLeft: spacing.sm }}>
                        <Text variant="bodySemibold">{room.name}</Text>
                        <Text variant="caption" color={colors.textSecondary}>
                          {room.floor} · Capacity {room.capacity}
                        </Text>
                      </View>
                      <Badge label={meta.label} status={meta.badge} size="sm" />
                    </View>
                    {booking && status !== 'available' ? (
                      <MetaRow icon="time-outline"
                        text={`Next: ${fmtTime(booking.startTime)} → ${fmtTime(booking.endTime)}`} />
                    ) : null}
                  </Card>
                );
              })}
            </>
          ) : null}
          <Text variant="eyebrow" color={colors.textMuted} style={styles.sectionLabel}>
            All meetings
          </Text>
        </>
      }
      ListEmptyComponent={
        <EmptyState
          icon="calendar-outline"
          title="No meetings booked"
          message="Meetings booked from Book a meeting will show up here, whether they're in a room or an outside location."
        />
      }
      renderItem={({ item }) => {
        const organiser = employeeById(item.organiserId);
        const room = item.roomId ? roomById(item.roomId) : null;
        return (
          <Card style={{ marginHorizontal: spacing.md }}>
            <View style={styles.headRow}>
              <View style={{ flex: 1 }}>
                <Text variant="bodySemibold">{item.title}</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {room ? room.name : item.location || 'Outside location'}
                </Text>
              </View>
              {item.priority !== 'normal' ? (
                <Badge
                  label={item.priority === 'urgent' ? 'Urgent' : 'Important'}
                  status={item.priority === 'urgent' ? 'rejected' : 'pending'}
                  size="sm"
                  dot={false}
                />
              ) : null}
            </View>
            <View style={styles.metaList}>
              <MetaRow icon="time-outline"
                text={`${fmtDate(item.startTime)} · ${fmtTime(item.startTime)} → ${fmtTime(item.endTime)}`} />
              <MetaRow icon="person-outline" text={`Organiser: ${organiser?.name || '--'}`} />
              {item.participantIds?.length ? (
                <MetaRow icon="people-outline" text={`${item.participantIds.length} staff invited`} />
              ) : null}
              {item.externalGuests?.length ? (
                <MetaRow icon="person-add-outline"
                  text={`Guests: ${item.externalGuests.map((g) => g.name).filter(Boolean).join(', ')}`} />
              ) : null}
              {item.responses?.length ? (
                <MetaRow icon="checkmark-done-outline" text={responseSummary(item.responses)} />
              ) : null}
            </View>
            {item.organiserId === user?.employeeId && item.participantIds?.length
              && new Date(item.endTime).getTime() < Date.now() ? (
              <Button
                label="Mark attendance"
                variant="secondary"
                icon="checkmark-circle-outline"
                onPress={() => setAttendanceForId(item.id)}
              />
            ) : null}
          </Card>
        );
      }}
    />
    <MarkAttendanceModal
      visible={!!attendanceForId}
      booking={attendanceBooking}
      onClose={() => setAttendanceForId(null)}
      onToggle={onToggleAbsent}
    />
    </>
  );
}

interface MarkAttendanceModalProps {
  visible: boolean;
  booking: RoomBooking | null;
  onClose: () => void;
  onToggle: (employeeId: string, absent: boolean) => void;
}

// Lets the organiser mark who actually showed up, after the meeting --
// independent of whether that person acknowledged or declined
// beforehand (acknowledging an invite doesn't guarantee attendance).
// Only invited staff have a response row to toggle; external guests
// aren't tracked here.
function MarkAttendanceModal({ visible, booking, onClose, onToggle }: MarkAttendanceModalProps) {
  const { colors } = useTheme();
  const { employeeById } = useData();

  if (!booking) return null;

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <View style={rejectStyles.wrap}>
        <View style={[rejectStyles.card, { backgroundColor: colors.surface }]}>
          <Text variant="h3">Mark attendance</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            {booking.title}
          </Text>
          <ScrollView style={{ maxHeight: 320 }}>
            {booking.participantIds.map((id) => {
              const employee = employeeById(id);
              const response = booking.responses.find((r) => r.employeeId === id);
              const absent = response?.absent || false;
              return (
                <View key={id} style={[attendanceStyles.row, { borderBottomColor: colors.border }]}>
                  <Text variant="bodySemibold" style={{ flex: 1 }}>{employee?.name || 'Unknown'}</Text>
                  <Pressable
                    onPress={() => onToggle(id, !absent)}
                    style={[
                      attendanceStyles.pill,
                      { backgroundColor: absent ? colors.status.rejected.solid : colors.brand },
                    ]}
                  >
                    <Text variant="caption" color={colors.textInverse}>
                      {absent ? 'Absent' : 'Present'}
                    </Text>
                  </Pressable>
                </View>
              );
            })}
          </ScrollView>
          <Button label="Done" variant="secondary" onPress={onClose} style={{ marginTop: spacing.md }} />
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  subHead: { paddingHorizontal: spacing.md },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  headRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.sm },
  metaList: { gap: 6, marginBottom: spacing.sm },
  metaRow: { flexDirection: 'row', alignItems: 'center' },
  actionRow: { flexDirection: 'row', marginTop: spacing.xs },
  roomIcon: {
    width: 44, height: 44, borderRadius: 12,
    alignItems: 'center', justifyContent: 'center',
  },
  sectionLabel: { marginBottom: spacing.sm, marginTop: spacing.xs },
});

const rejectStyles = StyleSheet.create({
  wrap: {
    flex: 1, backgroundColor: 'rgba(10,42,29,0.55)',
    alignItems: 'center', justifyContent: 'center', padding: spacing.lg,
  },
  card: {
    width: '100%', maxWidth: 360,
    borderRadius: radius.lg,
    padding: spacing.lg,
  },
  input: {
    borderWidth: 1, borderRadius: radius.md,
    paddingHorizontal: spacing.sm, paddingVertical: 10, minHeight: 44,
    fontFamily: fonts.regular, fontSize: 14,
  },
  rescheduleLink: { flexDirection: 'row', alignItems: 'center', marginTop: spacing.sm },
  row: { flexDirection: 'row', marginTop: spacing.md, gap: spacing.sm },
  btn: { flex: 1, height: 44, borderRadius: radius.md, alignItems: 'center', justifyContent: 'center' },
});

const attendanceStyles = StyleSheet.create({
  row: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingVertical: spacing.sm, borderBottomWidth: 1,
  },
  pill: {
    paddingHorizontal: spacing.sm, paddingVertical: 6, borderRadius: radius.md,
  },
});
'@)

# --- src\screens\HistoryScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\HistoryScreen.tsx', @'
import React, { useMemo, useState } from 'react';
import { View, SectionList, StyleSheet, RefreshControl } from 'react-native';
import {
  Screen, Header, Text, Card, Badge, EmptyState, Avatar, Segmented,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtDate, fmtTime, fmtRelative, splitRecentOlder } from '../data/format';
import type { RootStackScreenProps } from '../types/navigation';
import type { Appointment, RoomBooking, ClockRecord, StatusKey } from '../types';

type HistoryTab = 'appointments' | 'meetings' | 'clock';

// HistoryScreen -- a single place to look back at everything that's
// already happened, split into Recent (last 7 days) and Older like the
// Visitors log. The live/actionable views of each of these already
// exist elsewhere (Appointments/Meetings tab, Attendance screen) --
// this is purely the read-only "what happened" record.
export default function HistoryScreen({ route, navigation }: RootStackScreenProps<'History'>) {
  const [tab, setTab] = useState<HistoryTab>(route.params?.tab || 'appointments');

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="History"
          subtitle="Past appointments, meetings & clock records"
          onBackPress={() => navigation.goBack()}
        />
        <Segmented
          value={tab}
          onChange={setTab}
          options={[
            { label: 'Appointments', value: 'appointments' },
            { label: 'Meetings', value: 'meetings' },
            { label: 'Clock-ins', value: 'clock' },
          ]}
          style={{ marginBottom: spacing.sm }}
        />
      </View>

      {tab === 'appointments' ? (
        <AppointmentsHistory />
      ) : tab === 'meetings' ? (
        <MeetingsHistory />
      ) : (
        <ClockHistory />
      )}
    </Screen>
  );
}

function AppointmentsHistory() {
  const { colors } = useTheme();
  const { appointments, employeeById, refreshAll } = useData();
  const [refreshing, setRefreshing] = useState(false);
  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshAll();
    } finally {
      setRefreshing(false);
    }
  };

  // Only resolved appointments belong in history -- pending ones are
  // still "live" and live on the Appointments tab.
  const past = useMemo(
    () => appointments
      .filter((a) => a.status !== 'pending')
      .sort((a, b) => new Date(b.scheduledAt).getTime() - new Date(a.scheduledAt).getTime()),
    [appointments]
  );
  const sections = useMemo(() => splitRecentOlder(past, (a) => a.scheduledAt), [past]);

  return (
    <SectionList
      sections={sections}
      keyExtractor={(a) => a.id}
      contentContainerStyle={styles.list}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
      renderSectionHeader={({ section }) => (
        <Text variant="eyebrow" color={colors.textMuted} style={[styles.sectionHeader, { backgroundColor: colors.background }]}>
          {section.title}
        </Text>
      )}
      ListEmptyComponent={
        <EmptyState
          icon="calendar-outline"
          title="No history yet"
          message="Admitted and rejected appointments will show up here."
        />
      }
      renderItem={({ item }) => (
        <AppointmentHistoryRow appointment={item} hostName={employeeById(item.hostId)?.name} />
      )}
    />
  );
}

function AppointmentHistoryRow({ appointment, hostName }: { appointment: Appointment; hostName?: string }) {
  const { colors } = useTheme();
  const badgeStatus: StatusKey = appointment.status === 'admitted' ? 'success' : 'rejected';
  return (
    <Card padded={false} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <Avatar name={appointment.visitorName} size={44} />
        <View style={styles.middle}>
          <View style={styles.titleRow}>
            <Text variant="bodySemibold" numberOfLines={1}>{appointment.visitorName}</Text>
            <Badge label={appointment.status} status={badgeStatus} size="sm" />
          </View>
          <Text variant="caption" color={colors.textSecondary} numberOfLines={1}>
            {appointment.purpose} - {hostName || 'No host'}
          </Text>
          <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
            {fmtDate(appointment.scheduledAt)} - {fmtTime(appointment.scheduledAt)}
          </Text>
          {appointment.rejectReason ? (
            <Text variant="caption" color={colors.textMuted} numberOfLines={1}>
              Reason: {appointment.rejectReason}
            </Text>
          ) : null}
        </View>
      </View>
    </Card>
  );
}

function MeetingsHistory() {
  const { colors } = useTheme();
  const { roomBookings, employeeById, roomById, refreshRoomBookings } = useData();
  const [refreshing, setRefreshing] = useState(false);
  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshRoomBookings();
    } finally {
      setRefreshing(false);
    }
  };

  const past = useMemo(
    () => roomBookings
      .filter((b) => new Date(b.endTime).getTime() < Date.now())
      .sort((a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime()),
    [roomBookings]
  );
  const sections = useMemo(() => splitRecentOlder(past, (b) => b.startTime), [past]);

  return (
    <SectionList
      sections={sections}
      keyExtractor={(b) => b.id}
      contentContainerStyle={styles.list}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
      renderSectionHeader={({ section }) => (
        <Text variant="eyebrow" color={colors.textMuted} style={[styles.sectionHeader, { backgroundColor: colors.background }]}>
          {section.title}
        </Text>
      )}
      ListEmptyComponent={
        <EmptyState
          icon="business-outline"
          title="No past meetings"
          message="Meetings show up here once they've ended."
        />
      }
      renderItem={({ item }) => (
        <MeetingHistoryRow
          booking={item}
          organiserName={employeeById(item.organiserId)?.name}
          roomName={item.roomId ? roomById(item.roomId)?.name : undefined}
        />
      )}
    />
  );
}

function MeetingHistoryRow({
  booking, organiserName, roomName,
}: { booking: RoomBooking; organiserName?: string; roomName?: string }) {
  const { colors } = useTheme();
  const absentCount = booking.responses?.filter((r) => r.absent).length || 0;
  return (
    <Card style={{ marginHorizontal: spacing.md }}>
      <Text variant="bodySemibold">{booking.title}</Text>
      <Text variant="caption" color={colors.textSecondary}>
        {roomName || booking.location || 'Outside location'}
      </Text>
      <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
        {fmtDate(booking.startTime)} - {fmtTime(booking.startTime)} to {fmtTime(booking.endTime)}
      </Text>
      <Text variant="caption" color={colors.textMuted}>
        Organiser: {organiserName || '--'}
      </Text>
      {booking.participantIds?.length ? (
        <Text variant="caption" color={colors.textMuted}>
          {absentCount > 0
            ? `${absentCount} of ${booking.participantIds.length} absent`
            : `${booking.participantIds.length} staff invited`}
        </Text>
      ) : null}
    </Card>
  );
}

function ClockHistory() {
  const { colors } = useTheme();
  const { clockRecords, employeeById, refreshClockRecords } = useData();
  const [refreshing, setRefreshing] = useState(false);
  const onRefresh = async () => {
    setRefreshing(true);
    try {
      await refreshClockRecords();
    } finally {
      setRefreshing(false);
    }
  };

  const sorted = useMemo(
    () => [...clockRecords].sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()),
    [clockRecords]
  );
  const sections = useMemo(() => splitRecentOlder(sorted, (t) => t.timestamp), [sorted]);

  return (
    <SectionList
      sections={sections}
      keyExtractor={(t) => t.id}
      contentContainerStyle={styles.list}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      ItemSeparatorComponent={() => <View style={{ height: spacing.xs }} />}
      renderSectionHeader={({ section }) => (
        <Text variant="eyebrow" color={colors.textMuted} style={[styles.sectionHeader, { backgroundColor: colors.background }]}>
          {section.title}
        </Text>
      )}
      ListEmptyComponent={
        <EmptyState
          icon="card-outline"
          title="No clock records yet"
          message="Clock-in/out activity will appear here as it happens."
        />
      }
      renderItem={({ item }) => (
        <ClockHistoryRow record={item} employeeName={employeeById(item.employeeId)?.name} />
      )}
    />
  );
}

function ClockHistoryRow({ record, employeeName }: { record: ClockRecord; employeeName?: string }) {
  const { colors } = useTheme();
  const isIn = record.type === 'in';
  return (
    <Card padded={false} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <Avatar name={employeeName || record.employeeName || 'Unknown'} size={40} />
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold" numberOfLines={1}>
            {employeeName || record.employeeName || 'Unknown employee'}
          </Text>
          <Text variant="caption" color={colors.textMuted}>
            {fmtDate(record.timestamp)} - {fmtTime(record.timestamp)} - {fmtRelative(record.timestamp)}
          </Text>
        </View>
        <Badge label={isIn ? 'Tap in' : 'Tap out'} status={isIn ? 'success' : 'neutral'} size="sm" />
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  sectionHeader: { paddingVertical: spacing.xs },
  row: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  middle: { flex: 1, marginLeft: spacing.sm },
  titleRow: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: 8,
  },
});
'@)

# --- src\screens\MeetingRoomsScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\MeetingRoomsScreen.tsx', @'
import React, { useState } from 'react';
import { View, Image, FlatList, StyleSheet, Alert, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import {
  Screen, Header, Text, Card, Button, Input, EmptyState, CsvImportModal,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type { MeetingRoom, MeetingRoomInput } from '../types';

interface MeetingRoomsScreenProps {
  navigation: RootStackNavigation;
}

// Same idea as DirectoryScreen's mapCsvRow -- a real spreadsheet export
// rarely matches a fixed schema, so this accepts a range of common
// header spellings instead of only the exact literal ones.
function mapCsvRow(record: Record<string, string>): MeetingRoomInput {
  return {
    name: record['name'] || record['room name'] || record['roomname'] || record['room'] || '',
    capacity: record['capacity'] || record['seats'] || record['size'] || '',
    floor: record['floor'] || record['level'] || '',
    photoUrl: null,
    description: record['description'] || record['directions'] || record['notes'] || '',
  };
}

// MeetingRoomsScreen -- Company Setup > meeting rooms (manager only).
// The rooms managed here are exactly what BookMeetingForm and
// AppointmentsScreen's "Meeting Rooms" tab draw from.
export default function MeetingRoomsScreen({ navigation }: MeetingRoomsScreenProps) {
  const { colors } = useTheme();
  const { meetingRooms, addMeetingRoom, bulkImportMeetingRooms, removeMeetingRoom } = useData();

  const [name, setName] = useState('');
  const [capacity, setCapacity] = useState('');
  const [floor, setFloor] = useState('');
  const [description, setDescription] = useState('');
  const [photoUrl, setPhotoUrl] = useState('');
  const [pickingPhoto, setPickingPhoto] = useState(false);
  const [adding, setAdding] = useState(false);
  const [importVisible, setImportVisible] = useState(false);

  const onPickPhoto = async () => {
    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) {
      Alert.alert('Permission needed', 'Allow photo library access to add a room photo.');
      return;
    }
    setPickingPhoto(true);
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ['images'],
        allowsEditing: true,
        aspect: [4, 3],
        quality: 0.6,
        base64: true,
      });
      if (result.canceled) return;
      const asset = result.assets[0];
      if (!asset.base64) {
        Alert.alert('Could not read image', 'Please try a different photo.');
        return;
      }
      setPhotoUrl(`data:${asset.mimeType || 'image/jpeg'};base64,${asset.base64}`);
    } finally {
      setPickingPhoto(false);
    }
  };

  const onAdd = async () => {
    if (!name.trim()) {
      Alert.alert('Almost there', 'Give the room a name.');
      return;
    }
    setAdding(true);
    try {
      await addMeetingRoom({
        name: name.trim(), capacity, floor: floor.trim(),
        photoUrl: photoUrl || null, description: description.trim() || null,
      });
      setName(''); setCapacity(''); setFloor(''); setPhotoUrl(''); setDescription('');
    } catch (err) {
      Alert.alert('Could not add room', err instanceof ApiError ? err.message : 'Something went wrong.');
    } finally {
      setAdding(false);
    }
  };

  const onRemove = (room: MeetingRoom) => {
    Alert.alert('Remove room?', `${room.name} will no longer be bookable.`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Remove',
        style: 'destructive',
        onPress: () => removeMeetingRoom(room.id).catch(
          (err) => Alert.alert('Could not remove room', err instanceof ApiError ? err.message : 'Something went wrong.')
        ),
      },
    ]);
  };

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Meeting rooms"
          subtitle="Bookable spaces across the office"
          rightActions={[
            { icon: 'document-attach-outline', onPress: () => setImportVisible(true) },
            { icon: 'close', onPress: () => navigation.goBack() },
          ]}
        />
        <Card>
          <Input label="Room name" value={name} onChangeText={setName}
            placeholder="e.g. Boardroom A" icon="business-outline" />
          <View style={styles.row}>
            <View style={{ flex: 1 }}>
              <Input label="Capacity" value={capacity} onChangeText={setCapacity}
                placeholder="e.g. 12" icon="people-outline" keyboardType="number-pad" />
            </View>
            <View style={{ width: spacing.sm }} />
            <View style={{ flex: 1 }}>
              <Input label="Floor" value={floor} onChangeText={setFloor}
                placeholder="e.g. 3rd Floor" icon="layers-outline" />
            </View>
          </View>
          <Input label="Description / directions (optional)" value={description} onChangeText={setDescription}
            placeholder="e.g. Past the kitchen, second door on the left" icon="map-outline" multiline />
          <Pressable onPress={onPickPhoto} disabled={pickingPhoto} style={styles.photoRow}>
            <View style={[styles.photoPreview, { borderColor: colors.border, backgroundColor: colors.surfaceAlt }]}>
              {photoUrl ? (
                <Image source={{ uri: photoUrl }} style={styles.photoImage} resizeMode="cover" />
              ) : (
                <Ionicons name="camera-outline" size={20} color={colors.textMuted} />
              )}
            </View>
            <Text variant="bodySemibold" color={colors.brand} style={{ marginLeft: spacing.sm }}>
              {pickingPhoto ? 'Opening photos...' : photoUrl ? 'Change photo' : 'Add a room photo (optional)'}
            </Text>
          </Pressable>
          <Button label={adding ? 'Adding...' : 'Add room'} onPress={onAdd} disabled={adding} />
        </Card>
      </View>

      <FlatList
        data={meetingRooms}
        keyExtractor={(r) => r.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState icon="business-outline" title="No rooms yet" message="Add your first meeting room above." />
        }
        renderItem={({ item }) => (
          <Card style={{ marginHorizontal: spacing.md }}>
            <View style={styles.roomRow}>
              <View style={[styles.roomIcon, { backgroundColor: colors.primarySurface }]}>
                {item.photoUrl ? (
                  <Image source={{ uri: item.photoUrl }} style={styles.roomIconImage} resizeMode="cover" />
                ) : (
                  <Ionicons name="business" size={20} color={colors.primary} />
                )}
              </View>
              <View style={{ flex: 1, marginLeft: spacing.sm }}>
                <Text variant="bodySemibold">{item.name}</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {item.floor || 'No floor set'}{item.capacity ? ` · Capacity ${item.capacity}` : ''}
                </Text>
                {item.description ? (
                  <Text variant="caption" color={colors.textMuted} numberOfLines={2} style={{ marginTop: 2 }}>
                    {item.description}
                  </Text>
                ) : null}
              </View>
              <Pressable onPress={() => onRemove(item)} hitSlop={8}>
                <Ionicons name="trash-outline" size={20} color={colors.status.rejected.solid} />
              </Pressable>
            </View>
          </Card>
        )}
      />

      <CsvImportModal
        visible={importVisible}
        onClose={() => setImportVisible(false)}
        title="Import rooms"
        columnsHint="Columns: name, capacity, floor, description"
        mapRow={mapCsvRow}
        onImport={bulkImportMeetingRooms}
      />
    </Screen>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  row: { flexDirection: 'row' },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  roomRow: { flexDirection: 'row', alignItems: 'center' },
  roomIcon: {
    width: 44, height: 44, borderRadius: 12,
    alignItems: 'center', justifyContent: 'center',
    overflow: 'hidden',
  },
  roomIconImage: { width: '100%', height: '100%' },
  photoRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.md },
  photoPreview: {
    width: 44, height: 44, borderRadius: radius.md,
    borderWidth: 1, alignItems: 'center', justifyContent: 'center',
    overflow: 'hidden',
  },
  photoImage: { width: '100%', height: '100%' },
});
'@)

# --- src\screens\CallLogScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\CallLogScreen.tsx', @'
import React, { useMemo, useState } from 'react';
import { View, SectionList, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, Input, Segmented, EmptyState,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtDateTime, splitRecentOlder } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';
import type { Call, StatusKey } from '../types';

interface CallLogScreenProps {
  navigation: RootStackNavigation;
}

type CallFilter = 'all' | 'incoming' | 'outgoing' | 'missed';

// CallLogScreen -- every incoming / outgoing / missed call.
// Fields per the User Guide: date+time, caller name+phone, host, duration, purpose.
export default function CallLogScreen({ navigation }: CallLogScreenProps) {
  const { colors } = useTheme();
  const { calls, employeeById } = useData();
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState<CallFilter>('all');

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return calls
      .filter((c) => {
        if (filter !== 'all' && c.callType.toLowerCase() !== filter) return false;
        if (!q) return true;
        const host = employeeById(c.hostId);
        return (
          c.callerName.toLowerCase().includes(q) ||
          c.callerPhone.includes(q) ||
          (host?.name || '').toLowerCase().includes(q)
        );
      })
      .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
  }, [calls, query, filter, employeeById]);

  const sections = useMemo(
    () => splitRecentOlder(filtered, (c) => c.timestamp),
    [filtered]
  );

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Call log"
          subtitle={`${calls.length} calls recorded`}
          rightIcon="add"
          onRightPress={() => navigation.navigate('LogCall')}
        />
        <Input
          placeholder="Search caller, phone or host"
          value={query}
          onChangeText={setQuery}
          icon="search"
        />
        <Segmented
          value={filter}
          onChange={setFilter}
          options={[
            { label: 'All', value: 'all' },
            { label: 'Incoming', value: 'incoming' },
            { label: 'Outgoing', value: 'outgoing' },
            { label: 'Missed', value: 'missed' },
          ]}
        />
      </View>

      <SectionList
        sections={sections}
        keyExtractor={(c) => c.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        renderSectionHeader={({ section }) => (
          <Text variant="eyebrow" color={colors.textMuted} style={[styles.sectionHeader, { backgroundColor: colors.background }]}>
            {section.title}
          </Text>
        )}
        ListEmptyComponent={
          <EmptyState
            icon="call-outline"
            title="No calls match"
            message="Try a different search, or log a new call from the + button."
            actionLabel="Log a call"
            onAction={() => navigation.navigate('LogCall')}
          />
        }
        renderItem={({ item }) => <CallRow call={item} />}
      />
    </Screen>
  );
}

function CallRow({ call }: { call: Call }) {
  const { colors } = useTheme();
  const { employeeById } = useData();
  const host = employeeById(call.hostId);
  const icon: 'call' | 'call-outline' | 'call-sharp' =
    call.callType === 'Incoming' ? 'call' :
    call.callType === 'Outgoing' ? 'call-outline' :
    'call-sharp';
  const badgeStatus: StatusKey =
    call.callType === 'Missed' ? 'rejected' :
    call.callType === 'Incoming' ? 'success' :
    'info';

  return (
    <Card padded={false} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <View style={[styles.iconWrap, { backgroundColor: colors.status[badgeStatus].bg }]}>
          <Ionicons
            name={icon}
            size={18}
            color={colors.status[badgeStatus].solid}
          />
        </View>
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <View style={styles.rowTop}>
            <Text variant="bodySemibold" numberOfLines={1}>{call.callerName}</Text>
            <Badge label={call.callType} status={badgeStatus} size="sm" dot={false} />
          </View>
          <Text variant="caption" color={colors.textSecondary} numberOfLines={1}>
            {call.callerPhone} - Host: {host?.name || 'Unassigned'}
          </Text>
          <Text variant="caption" color={colors.textMuted}>
            {fmtDateTime(call.timestamp)} - {call.durationMinutes}m - {call.purpose}
          </Text>
          {call.notes ? (
            <Text variant="caption" color={colors.textSecondary} style={{ marginTop: 2 }} numberOfLines={2}>
              "{call.notes}"
            </Text>
          ) : null}
        </View>
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  sectionHeader: { paddingVertical: spacing.xs },
  row: { flexDirection: 'row', alignItems: 'flex-start', padding: spacing.md },
  iconWrap: {
    width: 40, height: 40, borderRadius: 12,
    alignItems: 'center', justifyContent: 'center',
  },
  rowTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: 8 },
});
'@)

# --- src\screens\NFCLookupScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\NFCLookupScreen.tsx', @'
import React, { useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Button, Input, Badge, Avatar,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useData } from '../context/DataContext';
import { fmtDateTime } from '../data/format';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type { Appointment, IoniconName } from '../types';

interface NFCLookupScreenProps {
  navigation: RootStackNavigation;
}

// Receptionist enters a visitor's NFC code, sees their full booking.
export default function NFCLookupScreen({ navigation }: NFCLookupScreenProps) {
  const { colors } = useTheme();
  const { findAppointmentByCode, admitAppointment, employeeById } = useData();
  const [code, setCode] = useState('');
  const [found, setFound] = useState<Appointment | null>(null);

  const lookup = async () => {
    const a = await findAppointmentByCode(code);
    if (!a) {
      Alert.alert('Not found', `No booking matches code "${code}".`);
      setFound(null);
      return;
    }
    setFound(a);
  };

  return (
    <Screen>
      <Header
        title="NFC lookup"
        subtitle="Enter the visitor's code to view their booking"
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      <Card>
        <Input
          label="Visitor NFC code"
          value={code}
          onChangeText={setCode}
          placeholder="VC-XXXX-XXXX"
          icon="card-outline"
          autoCapitalize="characters"
        />
        <Button label="Look up" icon="search" onPress={lookup} />
      </Card>

      {found && (
        <Card accent="success" style={{ marginTop: spacing.md }}>
          <View style={styles.head}>
            <Avatar name={found.visitorName} size={48} />
            <View style={{ flex: 1, marginLeft: spacing.sm }}>
              <Text variant="h3">{found.visitorName}</Text>
              <Text variant="caption" color={colors.textSecondary}>
                {found.visitorCompany || 'Visitor'}
              </Text>
            </View>
            <Badge label={found.status} status="success" size="sm" />
          </View>

          <Row icon="card-outline" label="NFC code" value={found.nfcCode || 'Not yet issued'} />
          <Row icon="call-outline" label="Phone" value={found.visitorPhone} />
          <Row icon="briefcase-outline" label="Purpose" value={found.purpose} />
          <Row icon="people-outline" label="Host"
            value={employeeById(found.hostId)?.name || '--'} />
          <Row icon="time-outline" label="Scheduled"
            value={fmtDateTime(found.scheduledAt)} />

          {found.status === 'pending' && (
            <Button label="Admit & check in"
              icon="checkmark-circle-outline"
              onPress={async () => {
                try {
                  const v = await admitAppointment(found);
                  Alert.alert('Admitted', `${v.fullName} (${v.badgeId}) is on-site.`);
                  setFound(null); setCode('');
                } catch (err) {
                  Alert.alert('Could not admit visitor', err instanceof ApiError ? err.message : 'Something went wrong.');
                }
              }}
              style={{ marginTop: spacing.sm }}
            />
          )}
        </Card>
      )}
    </Screen>
  );
}

function Row({ icon, label, value }: { icon: IoniconName; label: string; value: string }) {
  const { colors } = useTheme();
  return (
    <View style={styles.row}>
      <Ionicons name={icon} size={16} color={colors.brand} style={{ width: 24 }} />
      <Text variant="caption" color={colors.textSecondary} style={{ width: 80 }}>
        {label}
      </Text>
      <Text variant="bodySemibold" style={{ flex: 1 }}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  head: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.sm },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: 6 },
});
'@)

# --- src\screens\VisitorVisitsScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\VisitorVisitsScreen.tsx', @'
import React, { useMemo, useState } from 'react';
import { View, StyleSheet, FlatList } from 'react-native';
import {
  Screen, Header, Text, Card, Badge, Button, EmptyState, RescheduleModal,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtDate, fmtTime } from '../data/format';
import type { Appointment, AppointmentStatus, StatusKey } from '../types';

// VisitorVisitsScreen -- every booking this visitor has made, past and
// pending (VisitorHomeScreen only ever showed the single latest one).
// Visitors can also reschedule a pending visit, with a reason, same as
// Employees can on their own Appointments tab.
export default function VisitorVisitsScreen() {
  const { colors } = useTheme();
  const { user } = useAuth();
  const { appointments, employeeById } = useData();
  const [rescheduling, setRescheduling] = useState<Appointment | null>(null);

  const mine = useMemo(
    () => appointments
      .filter((a) => a.bookedByEmail === user!.email)
      .sort((a, b) => new Date(b.scheduledAt).getTime() - new Date(a.scheduledAt).getTime()),
    [appointments, user]
  );

  const badgeStatus = (status: AppointmentStatus): StatusKey => (
    status === 'admitted' ? 'success' : status === 'rejected' ? 'rejected' : 'pending'
  );

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header title="Your visits" subtitle="Past & pending appointments" />
      </View>

      <FlatList
        data={mine}
        keyExtractor={(a) => a.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="calendar-outline"
            title="No visits yet"
            message="Book an appointment from the Book tab to see it here."
          />
        }
        renderItem={({ item }) => {
          const host = employeeById(item.hostId);
          return (
            <Card style={{ marginHorizontal: spacing.md }}>
              <View style={styles.rowTop}>
                <Text variant="bodySemibold">{fmtDate(item.scheduledAt)}</Text>
                <Badge label={item.status} status={badgeStatus(item.status)} size="sm" />
              </View>
              <Text variant="caption" color={colors.textSecondary}>
                {item.purpose} · Host: {host?.name || 'Unassigned'}
              </Text>
              <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
                {fmtTime(item.scheduledAt)} · Code {item.nfcCode || 'pending approval'}
              </Text>
              {item.rescheduleReason ? (
                <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
                  Rescheduled: {item.rescheduleReason}
                </Text>
              ) : null}
              {item.rejectReason ? (
                <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
                  Reason: {item.rejectReason}
                </Text>
              ) : null}
              {item.status === 'pending' && (
                <Button
                  label="Reschedule"
                  variant="secondary"
                  icon="calendar-outline"
                  onPress={() => setRescheduling(item)}
                  style={{ marginTop: spacing.sm }}
                />
              )}
            </Card>
          );
        }}
      />

      <RescheduleModal
        appointment={rescheduling}
        visible={!!rescheduling}
        onClose={() => setRescheduling(null)}
      />
    </Screen>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  rowTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
});
'@)

# --- src\screens\VisitorBookScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\VisitorBookScreen.tsx', @'
import React, { useRef, useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Button, Input, Select, DateChips, TimeChips,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { visitPurposes } from '../data/mockData';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';

interface VisitorBookScreenProps {
  navigation: RootStackNavigation;
}

// VisitorBookScreen -- the visitor's own "Book" tab. Same fields as the
// form that used to live on VisitorHomeScreen, given a more formal,
// sectioned treatment (distinct headers per group) since it's now a
// dedicated screen rather than embedded on the dashboard.
export default function VisitorBookScreen({ navigation }: VisitorBookScreenProps) {
  const { colors } = useTheme();
  const { user } = useAuth();
  const { employees, bookVisit } = useData();

  const [name, setName] = useState(user!.name || '');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState(user!.email || '');
  const [company, setCompany] = useState('');
  const [purpose, setPurpose] = useState('Official Business');
  const [otherPurpose, setOtherPurpose] = useState('');
  const [hostId, setHostId] = useState<string | null>(null);
  const [date, setDate] = useState(formatDate(new Date()));
  const [time, setTime] = useState('10:00');
  const [submitting, setSubmitting] = useState(false);
  const submittingRef = useRef(false);

  const onSubmit = async () => {
    if (submittingRef.current) {
      Alert.alert('Already booking', 'Your booking is already being submitted.');
      return;
    }
    if (!name.trim() || !phone.trim() || !hostId) {
      Alert.alert('Almost there', 'Name, phone and host are required.');
      return;
    }
    if (purpose === 'Other' && !otherPurpose.trim()) {
      Alert.alert('Almost there', 'Please describe the purpose of your visit.');
      return;
    }
    if (!date.trim() || !time.trim()) {
      Alert.alert('Almost there', 'Pick a date and time for your visit.');
      return;
    }
    submittingRef.current = true;
    setSubmitting(true);
    try {
      await bookVisit({
        visitorName: name, visitorPhone: phone, visitorEmail: email, visitorCompany: company,
        purpose: purpose === 'Other' ? otherPurpose.trim() : purpose, hostId,
        scheduledAt: toInstant(date, time),
      });
      Alert.alert(
        'Booked',
        "Your visit request has been sent. You'll get a notification with your pass code once your host approves it.",
        [{ text: 'Done', onPress: () => navigation.navigate('Home') }]
      );
    } catch (err) {
      Alert.alert('Could not book visit', err instanceof ApiError ? err.message : 'Something went wrong.');
    } finally {
      submittingRef.current = false;
      setSubmitting(false);
    }
  };

  return (
    <Screen>
      <Header
        eyebrow="Pre-registration"
        title="Book a visit"
        subtitle="Complete each section below to request an appointment"
      />

      <Text variant="label" color={colors.brand} style={styles.sectionLabel}>
        1 · Your details
      </Text>
      <Card>
        <Input label="Full name" value={name} onChangeText={setName} icon="person-outline" />
        <Input label="Phone" value={phone} onChangeText={setPhone}
          icon="call-outline" keyboardType="phone-pad" />
        <Input label="Email (optional)" value={email} onChangeText={setEmail}
          icon="mail-outline" autoCapitalize="none" keyboardType="email-address" />
        <Input label="Company (optional)" value={company} onChangeText={setCompany}
          icon="business-outline" />
      </Card>

      <Text variant="label" color={colors.brand} style={styles.sectionLabel}>
        2 · Visit details
      </Text>
      <Card>
        <Select label="Purpose" value={purpose} onChange={setPurpose}
          icon="briefcase-outline"
          options={visitPurposes.map((p) => ({ label: p, value: p }))} />
        {purpose === 'Other' ? (
          <Input label="Please specify" value={otherPurpose} onChangeText={setOtherPurpose}
            placeholder="What's the purpose of your visit?" icon="create-outline" />
        ) : null}
        <Select label="Who are you visiting?" value={hostId} onChange={setHostId}
          icon="people-outline" placeholder="Pick a host..."
          options={employees.map((e) => ({
            label: e.name, value: e.id,
            sublabel: e.department,
          }))} />
      </Card>

      <Text variant="label" color={colors.brand} style={styles.sectionLabel}>
        3 · When
      </Text>
      <Card>
        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>Date</Text>
        <DateChips value={date} onChange={setDate} />
        <Text variant="label" color={colors.textSecondary} style={styles.chipsLabel}>Time</Text>
        <TimeChips value={time} onChange={setTime} />
      </Card>

      <View style={[styles.notice, { backgroundColor: colors.primarySurface }]}>
        <Ionicons name="information-circle" size={18} color={colors.primary} />
        <Text variant="caption" color={colors.brand} style={{ marginLeft: 8, flex: 1 }}>
          You'll receive an NFC pass code once submitted -- show it at reception on arrival.
        </Text>
      </View>

      <Button label="Submit booking" icon="checkmark-circle-outline"
        onPress={onSubmit} loading={submitting} style={{ marginTop: spacing.sm }} />
    </Screen>
  );
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

// The backend expects a full ISO instant (with seconds + timezone);
// "YYYY-MM-DDTHH:MM" alone isn't parseable as one.
function toInstant(dateStr: string, timeStr: string): string {
  return new Date(`${dateStr}T${timeStr}:00`).toISOString();
}

const styles = StyleSheet.create({
  sectionLabel: { marginTop: spacing.lg, marginBottom: spacing.xs, textTransform: 'uppercase' },
  chipsLabel: { marginBottom: spacing.xs },
  notice: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    borderRadius: radius.md,
    padding: spacing.sm,
    marginTop: spacing.md,
  },
});
'@)

# --- src\screens\DirectoryScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\DirectoryScreen.tsx', @'
import React, { useMemo, useState } from 'react';
import { View, FlatList, StyleSheet, Pressable, Linking } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Input, Text, Card, EmptyState, Avatar, CsvImportModal,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import type { RootStackNavigation } from '../types/navigation';
import type { Employee, EmployeeInput, Role } from '../types';

interface DirectoryScreenProps {
  navigation: RootStackNavigation;
}

// Accepts a wide range of header spellings so a real HR export (which
// almost never matches a fixed schema) doesn't need renaming first --
// "code"/"employee code"/"employeeid"/"staff id" all work for the id
// column, and FirstName+LastName combine into one name if there's no
// single "name" column at all.
function mapCsvRow(record: Record<string, string>): EmployeeInput {
  const firstName = record['firstname'] || record['first name'] || '';
  const lastName = record['lastname'] || record['last name'] || '';
  const combinedName = [firstName, lastName].filter(Boolean).join(' ');

  return {
    employeeId: record['code'] || record['employee code'] || record['employeecode']
      || record['employeeid'] || record['employee id'] || record['staff id'] || record['id'] || '',
    name: record['name'] || record['full name'] || record['fullname'] || combinedName || '',
    department: record['department'] || '',
    phone: record['phone'] || record['phone number'] || record['phonenumber'] || record['mobile'] || '',
    email: record['email'] || record['email address'] || record['emailaddress'] || '',
    role: (record['role'] || 'employee').toLowerCase() as Role,
  };
}

// DirectoryScreen -- the Phone Book.
// Lists every staff member; tap a row to open their detail page; tap
// the phone icon to dial straight from the device.
export default function DirectoryScreen({ navigation }: DirectoryScreenProps) {
  const { employees, bulkImportEmployees } = useData();
  const [query, setQuery] = useState('');
  const [importVisible, setImportVisible] = useState(false);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return employees;
    return employees.filter(
      (e) =>
        e.name.toLowerCase().includes(q) ||
        e.department.toLowerCase().includes(q) ||
        e.phone.includes(q)
    );
  }, [employees, query]);

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Directory"
          subtitle={`${employees.length} employees`}
          onBackPress={() => navigation.goBack()}
          rightActions={[
            { icon: 'document-attach-outline', onPress: () => setImportVisible(true) },
            { icon: 'person-add-outline', onPress: () => navigation.navigate('AddEmployee') },
          ]}
        />
        <Input
          placeholder="Search name or department"
          value={query}
          onChangeText={setQuery}
          icon="search"
        />
      </View>

      <FlatList
        data={filtered}
        keyExtractor={(e) => e.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.xs }} />}
        ListEmptyComponent={
          <EmptyState
            icon="people-outline"
            title="No matches"
            message="Try a different name or department."
          />
        }
        renderItem={({ item }) => (
          <DirectoryRow
            employee={item}
            onPress={() => navigation.navigate('EmployeeDetail', { employeeId: item.id })}
            onCall={() => Linking.openURL(`tel:${item.phone}`)}
          />
        )}
      />

      <CsvImportModal
        visible={importVisible}
        onClose={() => setImportVisible(false)}
        title="Import staff"
        columnsHint="Columns: code, name, department, phone, email, role (employee/receptionist/manager)"
        mapRow={mapCsvRow}
        onImport={bulkImportEmployees}
      />
    </Screen>
  );
}

function DirectoryRow({
  employee, onPress, onCall,
}: { employee: Employee; onPress: () => void; onCall: () => void }) {
  const { colors } = useTheme();
  return (
    <Card padded={false} onPress={onPress} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <Avatar name={employee.name} size={44} />
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold" numberOfLines={1}>{employee.name}</Text>
          <Text variant="caption" color={colors.textSecondary} numberOfLines={1}>
            {employee.department}
          </Text>
        </View>
        <Pressable onPress={onCall} hitSlop={8} style={[styles.callBtn, { backgroundColor: colors.primarySurface }]}>
          <Ionicons name="call" size={18} color={colors.primary} />
        </Pressable>
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  row: { flexDirection: 'row', alignItems: 'center', padding: spacing.sm },
  callBtn: {
    width: 40, height: 40, borderRadius: 20,
    alignItems: 'center', justifyContent: 'center',
  },
});
'@)

# --- src\screens\VisitorBookingScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\VisitorBookingScreen.tsx', @'
import React, { useRef, useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Button, Input, Select, Segmented, BookMeetingForm,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { visitPurposes } from '../data/mockData';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';

interface VisitorBookingScreenProps {
  navigation: RootStackNavigation;
}

type BookingMode = 'visitor' | 'internal';

// VisitorBookingScreen -- the receptionist's "Book" tab. Defaults to
// the online visitor pre-registration form (booking on behalf of a
// visitor who called or walked up), with a toggle to switch over to
// booking an internal meeting -- reception needs to reserve rooms too,
// not just register outside visitors.
//
// Submitting the visitor form creates a new appointment in 'pending'
// status, mirroring the real visitor-side flow.
export default function VisitorBookingScreen({ navigation }: VisitorBookingScreenProps) {
  const { colors } = useTheme();
  const { employees, bookVisit } = useData();
  const [mode, setMode] = useState<BookingMode>('visitor');

  const [visitorName, setVisitorName] = useState('');
  const [visitorPhone, setVisitorPhone] = useState('');
  const [visitorEmail, setVisitorEmail] = useState('');
  const [visitorCompany, setVisitorCompany] = useState('');
  const [purpose, setPurpose] = useState('Official Business');
  const [otherPurpose, setOtherPurpose] = useState('');
  const [hostId, setHostId] = useState<string | null>(null);
  const [date, setDate] = useState(formatDate(new Date()));
  const [time, setTime] = useState('10:00');
  const [submitting, setSubmitting] = useState(false);
  const submittingRef = useRef(false);

  const onSubmit = async () => {
    if (submittingRef.current) {
      Alert.alert('Already booking', 'This appointment is already being submitted.');
      return;
    }
    if (!visitorName.trim() || !visitorPhone.trim() || !hostId) {
      Alert.alert('Almost there', 'Name, phone and host are required.');
      return;
    }
    if (purpose === 'Other' && !otherPurpose.trim()) {
      Alert.alert('Almost there', 'Please describe the purpose of the visit.');
      return;
    }
    submittingRef.current = true;
    setSubmitting(true);
    try {
      await bookVisit({
        visitorName: visitorName.trim(),
        visitorPhone: visitorPhone.trim(),
        visitorEmail: visitorEmail.trim(),
        visitorCompany: visitorCompany.trim(),
        purpose: purpose === 'Other' ? otherPurpose.trim() : purpose,
        hostId,
        scheduledAt: toInstant(date, time),
      });
      Alert.alert(
        'Appointment requested',
        `${visitorName} is now in the pending queue. The host will be notified to approve the visit.`,
        [{ text: 'Done', onPress: () => navigation.navigate('Home') }]
      );
    } catch (err) {
      Alert.alert('Could not request appointment', err instanceof ApiError ? err.message : 'Something went wrong.');
    } finally {
      submittingRef.current = false;
      setSubmitting(false);
    }
  };

  return (
    <Screen>
      <Header
        eyebrow={mode === 'visitor' ? 'Pre-registration' : 'Self-service'}
        title={mode === 'visitor' ? 'Book a visit' : 'Book a meeting'}
        subtitle={mode === 'visitor'
          ? 'Face-to-face bookings taken over the phone or in person'
          : 'Reserve a room (or an outside spot) for an internal meeting'}
      />

      <Segmented
        value={mode}
        onChange={setMode}
        options={[
          { label: 'Visitor booking', value: 'visitor' },
          { label: 'Internal meeting', value: 'internal' },
        ]}
        style={{ marginBottom: spacing.md }}
      />

      {mode === 'internal' ? (
        <BookMeetingForm onDone={() => navigation.navigate('Home')} />
      ) : (
      <>
      <Card>
        <View style={[styles.notice, { backgroundColor: colors.primarySurface }]}>
          <Ionicons name="information-circle" size={18} color={colors.primary} />
          <Text variant="caption" color={colors.brand} style={{ marginLeft: 8, flex: 1 }}>
            Pre-booking speeds up reception. You will receive a QR code & badge ID after approval.
          </Text>
        </View>

        <Input
          label="Full name"
          value={visitorName}
          onChangeText={setVisitorName}
          placeholder="e.g. Selasi Akoto"
          icon="person-outline"
        />

        <Input
          label="Phone number"
          value={visitorPhone}
          onChangeText={setVisitorPhone}
          placeholder="+233 ..."
          icon="call-outline"
          keyboardType="phone-pad"
        />

        <Input
          label="Email (optional)"
          value={visitorEmail}
          onChangeText={setVisitorEmail}
          placeholder="name@example.com"
          icon="mail-outline"
          autoCapitalize="none"
          keyboardType="email-address"
        />

        <Input
          label="Company (optional)"
          value={visitorCompany}
          onChangeText={setVisitorCompany}
          placeholder="Your organisation"
          icon="business-outline"
        />

        <Select
          label="Purpose"
          value={purpose}
          onChange={setPurpose}
          icon="briefcase-outline"
          options={visitPurposes.map((p) => ({ label: p, value: p }))}
        />

        {purpose === 'Other' ? (
          <Input
            label="Please specify"
            value={otherPurpose}
            onChangeText={setOtherPurpose}
            placeholder="What's the purpose of the visit?"
            icon="create-outline"
          />
        ) : null}

        <Select
          label="Who are you visiting?"
          placeholder="Pick a host..."
          value={hostId}
          onChange={setHostId}
          icon="people-outline"
          options={employees.map((e) => ({
            label: e.name,
            value: e.id,
            sublabel: e.department,
          }))}
        />

        <View style={styles.dateRow}>
          <View style={{ flex: 1 }}>
            <Input
              label="Date"
              value={date}
              onChangeText={setDate}
              placeholder="YYYY-MM-DD"
              icon="calendar-outline"
            />
          </View>
          <View style={{ width: spacing.sm }} />
          <View style={{ flex: 1 }}>
            <Input
              label="Time"
              value={time}
              onChangeText={setTime}
              placeholder="HH:MM"
              icon="time-outline"
            />
          </View>
        </View>
      </Card>

      <Button
        label="Request appointment"
        icon="checkmark-circle-outline"
        onPress={onSubmit}
        loading={submitting}
        style={{ marginTop: spacing.md }}
      />
      </>
      )}
    </Screen>
  );
}

function formatDate(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

// The backend expects a full ISO instant (with seconds + timezone);
// "YYYY-MM-DDTHH:MM" alone isn't parseable as one and was silently
// failing every appointment request with a generic error.
function toInstant(dateStr: string, timeStr: string): string {
  return new Date(`${dateStr}T${timeStr}:00`).toISOString();
}

const styles = StyleSheet.create({
  notice: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    borderRadius: radius.md,
    padding: spacing.sm,
    marginBottom: spacing.md,
  },
  dateRow: { flexDirection: 'row' },
});
'@)

# --- src\screens\ManagerClockInsScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\ManagerClockInsScreen.tsx', @'
import React, { useCallback, useMemo } from 'react';
import { View, StyleSheet, FlatList } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import {
  Screen, Header, Text, Card, Badge, EmptyState, Avatar, StatTile,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtTime, fmtDate } from '../data/format';

// ManagerClockInsScreen -- every clock-in/out record, for record
// keeping. Sourced from DataContext's shared `clockRecords` ledger --
// the same one the Employee/Receptionist "on the clock" cards write
// to. That ledger is only loaded once at login though, so it won't
// pick up a *different* signed-in session's clock-ins on its own (no
// websockets/polling in this build) -- refetch on focus so re-opening
// this tab always shows what everyone else has actually done.
export default function ManagerClockInsScreen() {
  const { colors } = useTheme();
  const { clockRecords, refreshClockRecords } = useData();

  useFocusEffect(
    useCallback(() => {
      refreshClockRecords().catch(() => {});
    }, [])
  );

  const sorted = useMemo(
    () => [...clockRecords].sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()),
    [clockRecords]
  );

  const onsiteCount = useMemo(() => {
    const seen = new Set<string>();
    let count = 0;
    sorted.forEach((r) => {
      if (seen.has(r.employeeId)) return;
      seen.add(r.employeeId);
      if (r.type === 'in') count += 1;
    });
    return count;
  }, [sorted]);

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header title="Clock ins" subtitle="Attendance record for every role" />
        <StatTile icon="people" tint="primary" label="Currently on the clock" value={onsiteCount} />
      </View>

      <FlatList
        data={sorted}
        keyExtractor={(r) => r.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.xs }} />}
        ListEmptyComponent={
          <EmptyState
            icon="time-outline"
            title="No clock records yet"
            message="Clock-in/out activity from Employee and Receptionist home screens will appear here."
          />
        }
        renderItem={({ item }) => (
          <Card padded={false} style={{ marginHorizontal: spacing.md }}>
            <View style={styles.row}>
              <Avatar name={item.employeeName || 'Unknown'} size={40} />
              <View style={{ flex: 1, marginLeft: spacing.sm }}>
                <Text variant="bodySemibold" numberOfLines={1}>{item.employeeName || 'Unknown'}</Text>
                <Text variant="caption" color={colors.textSecondary}>{fmtDate(item.timestamp)}</Text>
              </View>
              <View style={{ alignItems: 'flex-end' }}>
                <Badge
                  label={item.type === 'in' ? 'Clocked in' : 'Clocked out'}
                  status={item.type === 'in' ? 'success' : 'neutral'}
                  size="sm"
                />
                <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
                  {fmtTime(item.timestamp)}
                </Text>
              </View>
            </View>
          </Card>
        )}
      />
    </Screen>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: spacing.sm, gap: spacing.sm },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  row: { flexDirection: 'row', alignItems: 'center', padding: spacing.sm },
});
'@)

# --- src\screens\BillingScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\BillingScreen.tsx', @'
import React from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, Button,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { fmtDate } from '../data/format';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type { BillingStatus, IoniconName, Plan, StatusKey } from '../types';

interface BillingScreenProps {
  navigation: RootStackNavigation;
}

const STATUS_META: Record<BillingStatus, { label: string; badge: StatusKey }> = {
  active: { label: 'Active', badge: 'success' },
  trial: { label: 'Trial', badge: 'pending' },
  past_due: { label: 'Past due', badge: 'rejected' },
};

// BillingScreen -- Manager/Administrator only, reachable from
// Settings > Organisation > "Billing & subscription". Stands in for
// the Stripe-backed subscription flow: a company signs in with their
// org's own plan/status/seat count and can switch tiers here (a real
// build would hit Stripe Checkout/Billing Portal instead of the demo
// confirm-alert below).
export default function BillingScreen({ navigation }: BillingScreenProps) {
  const { colors } = useTheme();
  const { user } = useAuth();
  const { plans, billing, invoices, changePlan } = useData();

  const currentPlan = plans.find((p) => p.id === billing?.planId);
  const statusMeta = STATUS_META[billing?.status ?? 'active'] || STATUS_META.active;

  // Switches immediately rather than gating behind a confirm dialog --
  // a real build would hand off to Stripe Checkout here instead.
  const onSwitchPlan = async (plan: Plan) => {
    if (plan.id === currentPlan?.id) return;
    try {
      await changePlan(plan.id);
      Alert.alert('Plan updated', `You're now on the ${plan.name} plan (GHS ${plan.price} / 2 years).`);
    } catch (err) {
      Alert.alert('Could not switch plan', err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  return (
    <Screen>
      <Header
        eyebrow={user!.organizationName}
        title="Billing & subscription"
        subtitle="Manage your organisation's plan and payment details"
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      {/* Current plan summary */}
      <Card accent={statusMeta.badge}>
        <View style={styles.planHead}>
          <View style={{ flex: 1 }}>
            <Text variant="caption" color={colors.textSecondary}>Current plan</Text>
            <Text variant="h2">{currentPlan?.name || '--'}</Text>
          </View>
          <Badge label={statusMeta.label} status={statusMeta.badge} />
        </View>

        <Text style={[styles.price, { color: colors.brand }]}>
          GHS {currentPlan?.price}
          <Text variant="body" color={colors.textSecondary}> / 2 years</Text>
        </Text>

        <View style={styles.metaRow}>
          <MetaCell icon="people-outline" label="Seats used"
            value={`${billing?.seatsUsed ?? 0} / ${currentPlan?.seatLimit ?? '--'}`} />
          <MetaCell icon="calendar-outline" label="Renews"
            value={fmtDate(billing?.renewalDate)} />
        </View>
      </Card>

      {/* Plan comparison */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Choose a plan
      </Text>
      {plans.map((plan) => {
        const isCurrent = plan.id === currentPlan?.id;
        return (
          <Card key={plan.id} style={{ marginBottom: spacing.sm }}>
            <View style={styles.planHead}>
              <View style={{ flex: 1 }}>
                <Text variant="h3">{plan.name}</Text>
                <Text variant="bodySemibold" style={{ color: colors.brand }}>
                  GHS {plan.price}<Text variant="caption" color={colors.textSecondary}> / 2yr</Text>
                </Text>
              </View>
              {isCurrent ? <Badge label="Current plan" status="info" size="sm" dot={false} /> : null}
            </View>

            {plan.features.map((f) => (
              <View key={f} style={styles.featureRow}>
                <Ionicons name="checkmark-circle" size={16} color={colors.primary} />
                <Text variant="bodyMd" color={colors.textSecondary} style={{ marginLeft: 6, flex: 1 }}>
                  {f}
                </Text>
              </View>
            ))}

            {!isCurrent ? (
              <Button
                label={`Switch to ${plan.name}`}
                variant="secondary"
                onPress={() => onSwitchPlan(plan)}
                style={{ marginTop: spacing.sm }}
              />
            ) : null}
          </Card>
        );
      })}

      {/* Payment method */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Payment method
      </Text>
      <Card>
        <View style={styles.cardRow}>
          <View style={[styles.cardIcon, { backgroundColor: colors.primarySurface }]}>
            <Ionicons name="card-outline" size={20} color={colors.brand} />
          </View>
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="bodySemibold">Card ending in {billing?.paymentLast4 || '••••'}</Text>
            <Text variant="caption" color={colors.textSecondary}>Billed once every 2 years</Text>
          </View>
          <Button
            label="Update"
            variant="ghost"
            size="sm"
            fullWidth={false}
            onPress={() => Alert.alert('Demo only', 'Updating a card wires up to Stripe Billing Portal in production.')}
          />
        </View>
      </Card>

      {/* Invoice history */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Billing history
      </Text>
      <Card padded={false}>
        {invoices.length === 0 ? (
          <Text variant="body" color={colors.textSecondary} style={{ padding: spacing.md }}>
            No invoices yet.
          </Text>
        ) : (
          invoices.map((inv, i) => (
            <View key={inv.id}>
              <View style={styles.invoiceRow}>
                <View style={{ flex: 1 }}>
                  <Text variant="bodySemibold">{fmtDate(inv.date)}</Text>
                  <Text variant="caption" color={colors.textSecondary}>
                    2-year subscription
                  </Text>
                </View>
                <Text variant="bodySemibold" style={{ marginRight: spacing.sm }}>
                  GHS {inv.amount}
                </Text>
                <Badge
                  label={inv.status === 'paid' ? 'Paid' : 'Failed'}
                  status={inv.status === 'paid' ? 'success' : 'rejected'}
                  size="sm"
                  dot={false}
                />
              </View>
              {i < invoices.length - 1 ? <View style={[styles.divider, { backgroundColor: colors.border }]} /> : null}
            </View>
          ))
        )}
      </Card>
    </Screen>
  );
}

function MetaCell({ icon, label, value }: { icon: IoniconName; label: string; value: string }) {
  const { colors } = useTheme();
  return (
    <View style={styles.metaCell}>
      <Ionicons name={icon} size={16} color={colors.primary} style={{ marginRight: 6 }} />
      <View>
        <Text variant="caption" color={colors.textSecondary}>{label}</Text>
        <Text variant="bodySemibold">{value}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  planHead: { flexDirection: 'row', alignItems: 'flex-start', marginBottom: spacing.xs },
  price: { fontFamily: fonts.displayExtra, fontSize: 30, marginBottom: spacing.sm },
  metaRow: { flexDirection: 'row', gap: spacing.lg, marginTop: spacing.xs },
  metaCell: { flexDirection: 'row', alignItems: 'center' },
  featureRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 3 },
  cardRow: { flexDirection: 'row', alignItems: 'center' },
  cardIcon: {
    width: 40, height: 40, borderRadius: 12,
    alignItems: 'center', justifyContent: 'center',
  },
  invoiceRow: {
    flexDirection: 'row', alignItems: 'center',
    padding: spacing.md,
  },
  divider: { height: 1, marginLeft: spacing.md },
});
'@)

# --- src\screens\NFCCardsScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\NFCCardsScreen.tsx', @'
import React, { useMemo, useState } from 'react';
import { View, StyleSheet, FlatList, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, Segmented, EmptyState, Avatar, Button,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useData } from '../context/DataContext';
import { fmtDate } from '../data/format';
import type { RootStackNavigation } from '../types/navigation';
import type { NfcCard as NfcCardType } from '../types';

interface NFCCardsScreenProps {
  navigation: RootStackNavigation;
}

type NfcCardFilter = 'active' | 'revoked' | 'all';

// NFCCardsScreen -- list of virtual NFC cards.
// Per the VisiLog 2.0 spec: each card has a holder, an issuance date,
// an expiry, and a status ('active' | 'revoked'). Receptionists can
// revoke (or in this demo, "rotate") a card.
export default function NFCCardsScreen({ navigation }: NFCCardsScreenProps) {
  const { nfcCards, employeeById } = useData();
  const [filter, setFilter] = useState<NfcCardFilter>('active');

  const list = useMemo(() => {
    return nfcCards
      .filter((c) => filter === 'all' || c.status === filter)
      .map((c) => {
        let holder;
        if (c.holderType === 'employee') holder = employeeById(c.holderId)?.name || 'Unknown';
        else holder = `Visitor ${c.holderId}`;
        return { ...c, holderName: holder };
      });
  }, [nfcCards, filter, employeeById]);

  const onRevoke = (card: NfcCardType) => {
    Alert.alert(
      'Revoke NFC card?',
      `Card ${card.tokenHash} will no longer grant access.`,
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Revoke', style: 'destructive', onPress: () => {
          Alert.alert('Demo only', 'Card revocation hits the NFC service in production.');
        }},
      ]
    );
  };

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="NFC Cards"
          subtitle="Issued credentials & access tokens"
          rightIcon="add"
          onRightPress={() => Alert.alert('Issue card', 'Card issuance is a demo placeholder.')}
        />
        <Segmented
          value={filter}
          onChange={setFilter}
          options={[
            { label: 'Active', value: 'active' },
            { label: 'Revoked', value: 'revoked' },
            { label: 'All', value: 'all' },
          ]}
        />
      </View>

      <FlatList
        data={list}
        keyExtractor={(c) => c.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        ListEmptyComponent={
          <EmptyState
            icon="card-outline"
            title="No cards here"
            message="Issued NFC cards will appear in this list."
          />
        }
        renderItem={({ item }) => (
          <NfcCard card={item} onRevoke={() => onRevoke(item)} />
        )}
      />
    </Screen>
  );
}

function NfcCard({
  card, onRevoke,
}: { card: NfcCardType & { holderName: string }; onRevoke: () => void }) {
  const { colors } = useTheme();
  const isActive = card.status === 'active';
  return (
    <Card
      accent={isActive ? 'onsite' : 'rejected'}
      style={{ marginHorizontal: spacing.md }}
    >
      <View style={styles.cardHead}>
        <View style={[styles.chip, { backgroundColor: isActive ? colors.primarySurface : colors.status.rejected.bg }]}>
          <Ionicons
            name="card"
            size={20}
            color={isActive ? colors.primary : colors.status.rejected.solid}
          />
        </View>
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold">{card.holderName}</Text>
          <Text variant="caption" color={colors.textSecondary}>
            {card.holderType === 'employee' ? 'Employee credential' : 'Visitor pass'}
          </Text>
        </View>
        <Badge label={card.status} status={isActive ? 'success' : 'rejected'} size="sm" />
      </View>

      <View style={[styles.tokenRow, { backgroundColor: colors.surfaceAlt }]}>
        <Text variant="caption" color={colors.textMuted}>Token</Text>
        <Text style={[styles.token, { color: colors.brand }]}>{card.tokenHash}</Text>
      </View>

      <View style={styles.dateRow}>
        <View style={{ flex: 1 }}>
          <Text variant="caption" color={colors.textMuted}>Issued</Text>
          <Text variant="bodyMd">{fmtDate(card.issuedAt)}</Text>
        </View>
        <View style={{ flex: 1 }}>
          <Text variant="caption" color={colors.textMuted}>Expires</Text>
          <Text variant="bodyMd">{fmtDate(card.expiresAt)}</Text>
        </View>
      </View>

      {isActive && (
        <Button
          label="Revoke card"
          variant="secondary"
          icon="ban-outline"
          onPress={onRevoke}
          style={{ marginTop: spacing.sm }}
        />
      )}
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  cardHead: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.sm },
  chip: {
    width: 44, height: 44, borderRadius: 12,
    alignItems: 'center', justifyContent: 'center',
  },
  tokenRow: {
    borderRadius: radius.sm,
    padding: spacing.sm,
    marginBottom: spacing.sm,
  },
  token: { fontFamily: fonts.semibold, fontSize: 16, letterSpacing: 1 },
  dateRow: { flexDirection: 'row', gap: spacing.md },
});
'@)

# --- src\screens\ReportsScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\ReportsScreen.tsx', @'
import React, { useMemo, useState } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Button, Segmented, StatTile, Badge,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useData } from '../context/DataContext';
import type { RootStackNavigation } from '../types/navigation';

interface ReportsScreenProps {
  navigation: RootStackNavigation;
}

type ReportRange = '24h' | '7d' | '30d';

// ReportsScreen -- date-range filtered visit summary with simple charts
// drawn in plain React Native (no chart library required).
// Per spec: date range, export PDF/CSV, "chart visualisations".
export default function ReportsScreen({ navigation }: ReportsScreenProps) {
  const { colors } = useTheme();
  const { visitors, calls, employeeById } = useData();
  const [range, setRange] = useState<ReportRange>('7d');

  const days = range === '24h' ? 1 : range === '7d' ? 7 : 30;

  // Slice data to the selected window.
  const { windowVisitors, windowCalls } = useMemo(() => {
    const cutoff = Date.now() - days * 24 * 60 * 60 * 1000;
    return {
      windowVisitors: visitors.filter((v) => new Date(v.checkInAt).getTime() >= cutoff),
      windowCalls: calls.filter((c) => new Date(c.timestamp).getTime() >= cutoff),
    };
  }, [visitors, calls, days]);

  // Bucket visitors per day for the bar chart. Always render `days` bars
  // (even when zero) so the axis is consistent.
  const dailyBars = useMemo(() => {
    const buckets = Array.from({ length: days }, (_, i) => ({
      label: dayLabel(days - 1 - i),
      count: 0,
    }));
    windowVisitors.forEach((v) => {
      const ago = Math.floor((Date.now() - new Date(v.checkInAt).getTime()) / 86400000);
      const idx = days - 1 - ago;
      if (idx >= 0 && idx < days) buckets[idx].count += 1;
    });
    return buckets;
  }, [windowVisitors, days]);

  const maxCount = Math.max(1, ...dailyBars.map((b) => b.count));

  // Top hosts by visitor count in the window.
  const topHosts = useMemo(() => {
    const counts: Record<string, number> = {};
    windowVisitors.forEach((v) => {
      counts[v.hostId] = (counts[v.hostId] || 0) + 1;
    });
    return Object.entries(counts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([id, count]) => ({ employee: employeeById(id), count }));
  }, [windowVisitors, employeeById]);

  const avgDuration = useMemo(() => {
    const completed = windowVisitors.filter((v) => v.checkOutAt);
    if (!completed.length) return '--';
    const totalMin = completed.reduce((sum, v) => {
      return sum + (new Date(v.checkOutAt as string).getTime() - new Date(v.checkInAt).getTime()) / 60000;
    }, 0);
    const avg = Math.round(totalMin / completed.length);
    const h = Math.floor(avg / 60);
    const m = avg % 60;
    return h ? `${h}h ${m}m` : `${m}m`;
  }, [windowVisitors]);

  return (
    <Screen>
      <Header
        title="Reports"
        subtitle="Visit summaries & exports"
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      <Segmented
        value={range}
        onChange={setRange}
        options={[
          { label: 'Last 24h', value: '24h' },
          { label: 'Last 7 days', value: '7d' },
          { label: 'Last 30 days', value: '30d' },
        ]}
      />

      {/* Headline numbers */}
      <View style={[styles.statRow, { marginTop: spacing.md }]}>
        <StatTile icon="people" label="Total visitors" value={windowVisitors.length} tint="primary" />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="time" label="Avg. duration" value={avgDuration} tint="info" />
      </View>
      <View style={[styles.statRow, { marginTop: spacing.sm }]}>
        <StatTile icon="call" label="Calls handled" value={windowCalls.length} tint="success" />
        <View style={{ width: spacing.sm }} />
        <StatTile icon="checkmark-done" label="Completed" value={windowVisitors.filter((v) => v.status === 'completed').length} tint="pending" />
      </View>

      {/* Daily bar chart - drawn as a row of flexed Views */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Visitors per day
      </Text>
      <Card>
        <View style={styles.chart}>
          {dailyBars.map((b, i) => {
            const h = (b.count / maxCount) * 120;
            return (
              <View key={i} style={styles.barCol}>
                <View style={styles.barTrack}>
                  <View style={[styles.bar, { height: Math.max(2, h), backgroundColor: colors.primary }]} />
                </View>
                <Text variant="caption" color={colors.textSecondary} style={styles.barLabel}>
                  {b.label}
                </Text>
                <Text style={[styles.barValue, { color: colors.textPrimary }]}>{b.count}</Text>
              </View>
            );
          })}
        </View>
      </Card>

      {/* Top hosts */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Top hosts
      </Text>
      <Card>
        {topHosts.length === 0 ? (
          <Text variant="body" color={colors.textSecondary}>
            No host data in this range yet.
          </Text>
        ) : (
          topHosts.map((h, i) => (
            <View key={h.employee?.id || i} style={styles.hostRow}>
              <View style={[styles.rank, { backgroundColor: colors.primarySurface }]}>
                <Text style={[styles.rankNum, { color: colors.primary }]}>{i + 1}</Text>
              </View>
              <View style={{ flex: 1, marginLeft: spacing.sm }}>
                <Text variant="bodySemibold">{h.employee?.name || 'Unknown'}</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {h.employee?.department || ''}
                </Text>
              </View>
              <Badge label={`${h.count} visits`} status="info" size="sm" dot={false} />
            </View>
          ))
        )}
      </Card>

      {/* Exports - non-functional in the demo (would call jsPDF / ExcelJS) */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Export
      </Text>
      <Button
        label="Export as PDF"
        variant="secondary"
        icon="document-outline"
        onPress={() => Alert.alert('Demo export', 'PDF export wires up to jsPDF in production.')}
      />
      <Button
        label="Export as CSV"
        variant="secondary"
        icon="grid-outline"
        onPress={() => Alert.alert('Demo export', 'CSV export wires up to ExcelJS in production.')}
        style={{ marginTop: spacing.xs }}
      />
    </Screen>
  );
}

// "Mon", "Tue" etc. for the bar chart axis.
function dayLabel(daysAgo: number): string {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][d.getDay()];
}

const styles = StyleSheet.create({
  statRow: { flexDirection: 'row' },
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },

  chart: { flexDirection: 'row', alignItems: 'flex-end', height: 160, gap: 4 },
  barCol: { flex: 1, alignItems: 'center' },
  barTrack: { width: '100%', height: 120, justifyContent: 'flex-end' },
  bar: {
    width: '70%', alignSelf: 'center',
    borderTopLeftRadius: 4, borderTopRightRadius: 4,
  },
  barLabel: { marginTop: 4 },
  barValue: { fontFamily: fonts.semibold, fontSize: 11 },

  hostRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 6 },
  rank: {
    width: 28, height: 28, borderRadius: 14,
    alignItems: 'center', justifyContent: 'center',
  },
  rankNum: { fontFamily: fonts.displayBold, fontSize: 13 },
});
'@)

# --- src\screens\RegisterVisitorScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\RegisterVisitorScreen.tsx', @'
import React, { useRef, useState } from 'react';
import { View, StyleSheet, Pressable, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Button, Input, Select, Badge,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { visitPurposes, nextBadgeId } from '../data/mockData';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';

interface RegisterVisitorScreenProps {
  navigation: RootStackNavigation;
}

interface RegisterVisitorErrors {
  firstName?: string;
  lastName?: string;
  phone?: string;
  hostId?: string;
  consent?: string;
  otherPurpose?: string;
}

// RegisterVisitorScreen -- modal opened from the visitors tab + dashboard.
// Implements the Check-In form from VisiLog spec + User Guide:
//   - First/Last name, phone, company, purpose (dropdown), host (dropdown)
//   - Badge number auto-generated and shown read-only
//   - Optional photo placeholder
//   - Optional consent / signature toggle
// Submitting registers AND checks the visitor in (single click flow).
export default function RegisterVisitorScreen({ navigation }: RegisterVisitorScreenProps) {
  const { colors } = useTheme();
  const { employees, visitors, registerAndCheckIn } = useData();

  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [company, setCompany] = useState('');
  const [purpose, setPurpose] = useState('Official Business');
  const [otherPurpose, setOtherPurpose] = useState('');
  const [hostId, setHostId] = useState<string | null>(null);
  const [consent, setConsent] = useState(true);
  const [photoAdded, setPhotoAdded] = useState(false);

  const [errors, setErrors] = useState<RegisterVisitorErrors>({});
  const [submitting, setSubmitting] = useState(false);
  // useState's `submitting` only updates on the next render, so two taps
  // in the same event-loop tick (a fast double-tap) can both read it as
  // false and both fire. A ref updates synchronously, so it actually
  // blocks the second tap.
  const submittingRef = useRef(false);

  // Preview of the badge ID that will be assigned. Recomputed every render
  // so it stays accurate if the visitor list changes underneath.
  const previewBadge = nextBadgeId(visitors);

  const onSubmit = async () => {
    if (submittingRef.current) return;
    const nextErrors: RegisterVisitorErrors = {};
    if (!firstName.trim()) nextErrors.firstName = 'Enter the visitor\u2019s first name.';
    if (!lastName.trim()) nextErrors.lastName = 'Enter the visitor\u2019s last name.';
    if (!phone.trim()) nextErrors.phone = 'A phone number is required.';
    if (!hostId) nextErrors.hostId = 'Pick a host employee.';
    if (!consent) nextErrors.consent = 'Visitor consent is required to check in.';
    if (purpose === 'Other' && !otherPurpose.trim()) {
      nextErrors.otherPurpose = 'Describe the purpose of the visit.';
    }
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) return;

    submittingRef.current = true;
    setSubmitting(true);
    try {
      const visitor = await registerAndCheckIn({
        firstName, lastName, phone, email, company,
        purpose: purpose === 'Other' ? otherPurpose.trim() : purpose,
        hostId: hostId as string,
      });
      Alert.alert(
        'Checked in',
        `${visitor.fullName} (${visitor.badgeId}) is now on-site.`,
        [{ text: 'Done', onPress: () => navigation.goBack() }]
      );
    } catch (err) {
      Alert.alert('Could not check in visitor', err instanceof ApiError ? err.message : 'Something went wrong.');
    } finally {
      submittingRef.current = false;
      setSubmitting(false);
    }
  };

  return (
    <Screen>
      <Header
        eyebrow="New visitor entry"
        title="Register & check in"
        subtitle="Capture visitor details, then admit to the building."
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      <Card>
        {/* Photo placeholder -- tappable square that toggles a "photo added"
            state. A real build would launch expo-image-picker here. */}
        <Pressable
          onPress={() => setPhotoAdded((p) => !p)}
          style={[
            styles.photo,
            { borderColor: colors.border, backgroundColor: colors.surfaceAlt },
            photoAdded && { borderStyle: 'solid', borderColor: colors.status.success.solid, backgroundColor: colors.status.success.bg },
          ]}
        >
          <Ionicons
            name={photoAdded ? 'checkmark-circle' : 'camera-outline'}
            size={26}
            color={photoAdded ? colors.status.success.solid : colors.textMuted}
          />
          <Text variant="caption" color={colors.textSecondary} style={{ marginTop: 4 }}>
            {photoAdded ? 'Photo captured' : 'Tap to add photo (optional)'}
          </Text>
        </Pressable>

        <View style={styles.nameRow}>
          <View style={{ flex: 1 }}>
            <Input
              label="First name"
              value={firstName}
              onChangeText={setFirstName}
              placeholder="e.g. Aseye"
              error={errors.firstName}
            />
          </View>
          <View style={{ width: spacing.sm }} />
          <View style={{ flex: 1 }}>
            <Input
              label="Last name"
              value={lastName}
              onChangeText={setLastName}
              placeholder="e.g. Abugri"
              error={errors.lastName}
            />
          </View>
        </View>

        <Input
          label="Phone number"
          value={phone}
          onChangeText={setPhone}
          placeholder="+233 ..."
          icon="call-outline"
          keyboardType="phone-pad"
          error={errors.phone}
        />

        <Input
          label="Email (optional)"
          value={email}
          onChangeText={setEmail}
          placeholder="name@example.com"
          icon="mail-outline"
          autoCapitalize="none"
          keyboardType="email-address"
        />

        <Input
          label="Company (optional)"
          value={company}
          onChangeText={setCompany}
          placeholder="e.g. Adansi Logistics"
          icon="business-outline"
        />

        <Select
          label="Purpose of visit"
          value={purpose}
          onChange={setPurpose}
          icon="briefcase-outline"
          options={visitPurposes.map((p) => ({ label: p, value: p }))}
        />

        {purpose === 'Other' ? (
          <Input
            label="Please specify"
            value={otherPurpose}
            onChangeText={setOtherPurpose}
            placeholder="What's the purpose of the visit?"
            icon="create-outline"
            error={errors.otherPurpose}
          />
        ) : null}

        <Select
          label="Host employee"
          placeholder="Search staff directory..."
          value={hostId}
          onChange={setHostId}
          icon="people-outline"
          error={errors.hostId}
          options={employees.map((e) => ({
            label: e.name,
            value: e.id,
            sublabel: e.department,
          }))}
        />

        {/* Badge number (auto-generated, read-only preview) */}
        <View style={[styles.badgePreview, { backgroundColor: colors.primarySurface }]}>
          <Ionicons name="card-outline" size={18} color={colors.brand} />
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="caption" color={colors.textSecondary}>
              Badge number (auto-generated)
            </Text>
            <Text variant="bodySemibold">{previewBadge}</Text>
          </View>
          <Badge label="Auto" status="info" size="sm" />
        </View>

        {/* Consent / digital signature */}
        <Pressable
          onPress={() => setConsent((c) => !c)}
          style={styles.consent}
        >
          <View style={[styles.checkbox, { borderColor: colors.borderStrong }, consent && { backgroundColor: colors.primary, borderColor: colors.primary }]}>
            {consent ? <Ionicons name="checkmark" size={14} color="#FFF" /> : null}
          </View>
          <View style={{ flex: 1, marginLeft: spacing.xs }}>
            <Text variant="bodyMd">Visitor agrees to site rules & data policy</Text>
            <Text variant="caption" color={colors.textSecondary}>
              Acts as the digital signature for this visit.
            </Text>
          </View>
        </Pressable>
        {errors.consent ? (
          <Text variant="caption" color={colors.status.error.solid} style={{ marginTop: -8, marginBottom: 8 }}>
            {errors.consent}
          </Text>
        ) : null}
      </Card>

      <Button
        label="Check in visitor"
        icon="checkmark-circle-outline"
        onPress={onSubmit}
        loading={submitting}
        style={{ marginTop: spacing.md }}
      />
      <Button
        label="Cancel"
        variant="ghost"
        onPress={() => navigation.goBack()}
        style={{ marginTop: spacing.xs }}
      />
    </Screen>
  );
}

const styles = StyleSheet.create({
  photo: {
    height: 88,
    borderWidth: 1,
    borderStyle: 'dashed',
    borderRadius: radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.md,
  },
  nameRow: { flexDirection: 'row' },
  badgePreview: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: radius.md,
    padding: spacing.sm,
    marginBottom: spacing.md,
  },
  consent: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing.xs,
  },
  checkbox: {
    width: 20, height: 20, borderRadius: 6,
    borderWidth: 1.5,
    alignItems: 'center', justifyContent: 'center',
  },
});
'@)

# --- src\screens\EmployeeDetailScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\EmployeeDetailScreen.tsx', @'
import React from 'react';
import { View, StyleSheet, Pressable, Linking, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Avatar, Button } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { ApiError } from '../api/client';
import type { RootStackScreenProps } from '../types/navigation';
import type { IoniconName } from '../types';

// EmployeeDetailScreen -- single staff member's profile.
export default function EmployeeDetailScreen({ route, navigation }: RootStackScreenProps<'EmployeeDetail'>) {
  const { colors } = useTheme();
  const { employeeId } = route.params;
  const { employees, removeEmployee } = useData();
  const employee = employees.find((e) => e.id === employeeId);

  if (!employee) {
    return (
      <Screen>
        <Header title="Not found" rightIcon="close" onRightPress={() => navigation.goBack()} />
      </Screen>
    );
  }

  const onRemove = () => {
    Alert.alert(
      'Remove employee?',
      `${employee.name} will be removed from the directory.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove', style: 'destructive',
          onPress: async () => {
            try {
              await removeEmployee(employee.id);
              navigation.goBack();
            } catch (err) {
              Alert.alert('Could not remove employee', err instanceof ApiError ? err.message : 'Something went wrong.');
            }
          },
        },
      ]
    );
  };

  return (
    <Screen>
      <Header
        title="Staff profile"
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      <Card>
        <View style={styles.headerRow}>
          <Avatar name={employee.name} size={64} />
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="h2">{employee.name}</Text>
            <Text variant="caption" color={colors.textSecondary}>
              {employee.department}
            </Text>
          </View>
        </View>

        <View style={styles.actionRow}>
          <ActionPill icon="call" label="Call"
            onPress={() => Linking.openURL(`tel:${employee.phone}`)} />
          <ActionPill icon="mail" label="Email"
            onPress={() => Linking.openURL(`mailto:${employee.email}`)} />
          <ActionPill icon="chatbubble-ellipses" label="Message"
            onPress={() => Linking.openURL(`sms:${employee.phone}`)} />
        </View>
      </Card>

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>Contact</Text>
      <Card>
        <Row icon="call-outline" label="Personal phone" value={employee.phone} />
        <Divider />
        <Row icon="mail-outline" label="Email" value={employee.email} />
        <Divider />
        <Row icon="briefcase-outline" label="Department" value={employee.department} />
      </Card>

      <Button
        label="Remove from directory"
        variant="secondary"
        icon="trash-outline"
        onPress={onRemove}
        style={{ marginTop: spacing.xl }}
      />
    </Screen>
  );
}

function Row({ icon, label, value }: { icon: IoniconName; label: string; value: string }) {
  const { colors } = useTheme();
  return (
    <View style={styles.row}>
      <View style={[styles.icon, { backgroundColor: colors.surfaceAlt }]}>
        <Ionicons name={icon} size={18} color={colors.brand} />
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="caption" color={colors.textSecondary}>{label}</Text>
        <Text variant="bodySemibold">{value}</Text>
      </View>
    </View>
  );
}

function Divider() {
  const { colors } = useTheme();
  return <View style={[styles.divider, { backgroundColor: colors.border }]} />;
}

function ActionPill({
  icon, label, onPress,
}: { icon: IoniconName; label: string; onPress: () => void }) {
  const { colors } = useTheme();
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.pill, { backgroundColor: colors.primarySurface }, pressed && { opacity: 0.85 }]}>
      <Ionicons name={icon} size={18} color={colors.primary} />
      <Text variant="caption" color={colors.brand} style={{ marginTop: 2 }}>
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  headerRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.md },
  actionRow: { flexDirection: 'row', gap: spacing.xs },
  pill: {
    flex: 1, alignItems: 'center', paddingVertical: spacing.sm,
    borderRadius: radius.md,
  },
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: spacing.xs },
  icon: {
    width: 32, height: 32, borderRadius: 10,
    alignItems: 'center', justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, marginVertical: spacing.xs, marginLeft: 32 + spacing.sm },
});
'@)

# --- src\screens\VisitorDetailScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\VisitorDetailScreen.tsx', @'
import React, { useState } from 'react';
import { View, StyleSheet, Alert, Pressable, Linking } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, Button, Input, Avatar,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtTime, fmtDate, fmtDuration } from '../data/format';
import { ApiError } from '../api/client';
import type { RootStackScreenProps } from '../types/navigation';
import type { IoniconName } from '../types';

// VisitorDetailScreen -- the full record for one visitor.
// Reachable by tapping any row in the Visitors list. Shows:
//   - Identity block (avatar, name, badge ID, status)
//   - Visit details (host, purpose, company, phone)
//   - Timing (check-in, check-out, duration)
//   - Notes (editable)
//   - Check-out action (when on-site)
export default function VisitorDetailScreen({ route, navigation }: RootStackScreenProps<'VisitorDetail'>) {
  const { colors } = useTheme();
  const { visitorId } = route.params;
  const { visitors, checkOutVisitor, employeeById } = useData();
  const visitor = visitors.find((v) => v.id === visitorId);

  const [note, setNote] = useState('');

  if (!visitor) {
    return (
      <Screen>
        <Header title="Visitor not found" rightIcon="close" onRightPress={() => navigation.goBack()} />
        <Text variant="body" color={colors.textSecondary}>
          This record may have been removed. Go back and try again.
        </Text>
      </Screen>
    );
  }

  const host = employeeById(visitor.hostId);
  const isOnsite = visitor.status === 'onsite';

  const onCheckOut = () => {
    Alert.alert(
      'Check out visitor?',
      `${visitor.fullName} will be marked as departed.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Check out',
          style: 'destructive',
          onPress: async () => {
            try {
              await checkOutVisitor(visitor.id, note);
              navigation.goBack();
            } catch (err) {
              Alert.alert('Could not check out', err instanceof ApiError ? err.message : 'Something went wrong.');
            }
          },
        },
      ]
    );
  };

  return (
    <Screen>
      <Header
        title="Visit details"
        subtitle={visitor.badgeId}
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      {/* Identity card */}
      <Card accent={isOnsite ? 'onsite' : 'neutral'}>
        <View style={styles.identityRow}>
          <Avatar name={visitor.fullName} size={56} />
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="h2" numberOfLines={1}>{visitor.fullName}</Text>
            <Text variant="caption" color={colors.textSecondary}>
              {visitor.company || 'No company on file'}
            </Text>
          </View>
          <Badge
            label={isOnsite ? 'On-site' : 'Completed'}
            status={isOnsite ? 'onsite' : 'neutral'}
          />
        </View>
      </Card>

      {/* Quick contact actions */}
      <View style={styles.actionsRow}>
        <ActionPill icon="call" label="Call"
          onPress={() => Linking.openURL(`tel:${visitor.phone}`)} />
        <ActionPill icon="chatbubble-ellipses" label="Message"
          onPress={() => Linking.openURL(`sms:${visitor.phone}`)} />
        <ActionPill icon="mail" label="Email"
          onPress={() => Alert.alert('No email on file', 'This visitor record has no email address.')} />
      </View>

      {/* Visit details */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>Visit details</Text>
      <Card>
        <DetailRow icon="people-outline" label="Host" value={host?.name || 'Not assigned'}
          sub={host ? host.department : undefined} />
        <Divider />
        <DetailRow icon="briefcase-outline" label="Purpose" value={visitor.purpose} />
        <Divider />
        <DetailRow icon="call-outline" label="Phone" value={visitor.phone} />
        <Divider />
        <DetailRow icon="card-outline" label="Badge ID" value={visitor.badgeId} />
      </Card>

      {/* Timing */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>Timing</Text>
      <Card>
        <DetailRow icon="log-in-outline" label="Checked in"
          value={fmtTime(visitor.checkInAt)} sub={fmtDate(visitor.checkInAt)} />
        <Divider />
        <DetailRow icon="log-out-outline" label="Checked out"
          value={visitor.checkOutAt ? fmtTime(visitor.checkOutAt) : 'Still on-site'}
          sub={visitor.checkOutAt ? fmtDate(visitor.checkOutAt) : undefined} />
        <Divider />
        <DetailRow icon="hourglass-outline" label="Duration"
          value={fmtDuration(visitor.checkInAt, visitor.checkOutAt)} />
      </Card>

      {/* Notes */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>Notes</Text>
      {isOnsite ? (
        <Input
          placeholder="Check-out note (optional)"
          value={note}
          onChangeText={setNote}
          multiline
        />
      ) : (
        <Card>
          <Text variant="body" color={visitor.notes ? colors.textPrimary : colors.textMuted}>
            {visitor.notes || 'No notes were recorded for this visit.'}
          </Text>
        </Card>
      )}

      {isOnsite ? (
        <Button
          label="Check out visitor"
          icon="log-out-outline"
          variant="primary"
          onPress={onCheckOut}
          style={{ marginTop: spacing.md }}
        />
      ) : null}
    </Screen>
  );
}

// Small internal helpers

function DetailRow({
  icon, label, value, sub,
}: { icon: IoniconName; label: string; value: string; sub?: string }) {
  const { colors } = useTheme();
  return (
    <View style={styles.detailRow}>
      <View style={[styles.detailIcon, { backgroundColor: colors.surfaceAlt }]}>
        <Ionicons name={icon} size={18} color={colors.brand} />
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="caption" color={colors.textSecondary}>{label}</Text>
        <Text variant="bodySemibold">{value}</Text>
        {sub ? (
          <Text variant="caption" color={colors.textMuted}>{sub}</Text>
        ) : null}
      </View>
    </View>
  );
}

function Divider() {
  const { colors } = useTheme();
  return <View style={[styles.divider, { backgroundColor: colors.border }]} />;
}

function ActionPill({
  icon, label, onPress,
}: { icon: IoniconName; label: string; onPress: () => void }) {
  const { colors } = useTheme();
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.pill, { backgroundColor: colors.surface, borderColor: colors.border }, pressed && { opacity: 0.85 }]}>
      <Ionicons name={icon} size={18} color={colors.primary} />
      <Text variant="bodyMd" color={colors.brand} style={{ marginLeft: 6 }}>
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  identityRow: { flexDirection: 'row', alignItems: 'center' },
  actionsRow: { flexDirection: 'row', gap: spacing.xs, marginTop: spacing.sm },
  pill: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing.sm,
    borderRadius: radius.pill,
    borderWidth: 1,
  },
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  detailRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: spacing.xs },
  detailIcon: {
    width: 32, height: 32, borderRadius: 10,
    alignItems: 'center', justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, marginVertical: spacing.xs, marginLeft: 32 + spacing.sm },
});
'@)

# --- src\screens\LegalAgreementScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\LegalAgreementScreen.tsx', @'
import React, { useState } from 'react';
import { View, StyleSheet, Pressable, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Button } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import type { RootStackScreenProps } from '../types/navigation';

// LegalAgreementScreen has two modes, driven by whether `pending` (the
// not-yet-submitted company registration form) was passed in:
//
//   - Registration flow: RegisterCompanyScreen collects the form, then
//     pushes here with `pending` set. A company can't use VisiLog until
//     this screen's subscription is agreed to and "paid" for -- there's
//     no real payment processor in this build, so this is a placeholder
//     checkout step, but registerCompany() (the call that actually
//     creates the org and hands back a company code) only fires from
//     the button on *this* screen, never from the form screen itself.
//   - Review flow: reachable anytime afterwards from Company Setup (the
//     paying manager's own screen), with no `pending` data -- read-only,
//     no checkbox or payment section, just the terms.
// Every self-serve signup lands on the Starter plan (see
// AuthService.registerCompany) -- match its real price so this isn't a
// disconnected placeholder figure. Administrators can switch plans
// afterwards from Billing & subscription.
const STARTER_PRICE = 400;
const TERM_YEARS = 2;
const CURRENCY = 'GHS';

const TERMS_TEXT = `VisiLog Subscription Agreement

1. Term & Renewal
VisiLog is licensed on a minimum two-year subscription term. Your subscription begins on the date of activation and automatically covers your organization for the full term shown below. You will be notified before renewal.

2. What's included
Your subscription covers unlimited visitor check-ins, staff roster management, meeting room booking, NFC badge issuance, and all Company Setup administration tools for your organization, billed at the plan tier your Administrator selects afterwards.

3. Data & Privacy
Visitor and staff data you enter is stored for your organization only and is never shared with other tenants. You are responsible for obtaining any consent required by your local data protection laws before collecting visitor information.

4. Administrator responsibility
The person completing this agreement is designated the organization's initial Administrator (Manager role) and is responsible for configuring the staff roster, office location, and branding in Company Setup, and for managing who else on their team has administrative access.

5. Cancellation
You may cancel future renewals at any time from Billing & Subscription in Settings. Cancelling does not refund the current term.

By continuing, you confirm you have the authority to enter into this agreement on behalf of your organization.`;

export default function LegalAgreementScreen({ navigation, route }: RootStackScreenProps<'LegalAgreement'>) {
  const { colors } = useTheme();
  const { registerCompany } = useAuth();
  const pending = route?.params?.pending || null;
  const viewOnly = !pending;

  const [agreed, setAgreed] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  const onConfirm = async () => {
    if (!agreed || submitting || !pending) return;
    setSubmitting(true);
    const result = await registerCompany(
      pending.companyName, pending.adminName, pending.adminEmail, pending.password
    );
    setSubmitting(false);
    if (!result.ok) {
      Alert.alert('Could not register your company', result.error);
      return;
    }
    Alert.alert(
      "You're all set",
      `${result.organization!.name} is registered and active for the next ${TERM_YEARS} years. Your company code is ${result.organization!.code} -- share it with your staff and visitors so they can sign up. You can find it again anytime in Company Setup.`,
      [{
        text: 'Continue',
        onPress: () => {
          // The root navigator swaps to the signed-in stack once `user` is
          // set, but "LegalAgreement" is a valid screen name in *both*
          // stacks (it's also reachable from Company Setup post-login), so
          // React Navigation has no reason to redirect on its own -- it just
          // keeps rendering the same screen name across the swap. Reset
          // explicitly to the new stack's actual landing screen instead of
          // relying on that swap to also navigate.
          navigation.reset({ index: 0, routes: [{ name: 'ManagerTabs' }] });
        },
      }]
    );
  };

  return (
    <Screen>
      <Header
        eyebrow={viewOnly ? 'Company Setup' : 'Before you activate'}
        title="Legal agreement"
        subtitle={viewOnly
          ? 'The terms your organization agreed to when it registered.'
          : "Read and agree to continue -- you're a couple of taps from a company code."}
        onBackPress={() => navigation.goBack()}
      />

      <Card>
        <Text variant="bodyMd" color={colors.textPrimary} style={styles.terms}>
          {TERMS_TEXT}
        </Text>
      </Card>

      {!viewOnly ? (
        <>
          <Card style={{ marginTop: spacing.sm }}>
            <View style={styles.planRow}>
              <View>
                <Text variant="bodySemibold">VisiLog subscription</Text>
                <Text variant="caption" color={colors.textSecondary}>
                  {TERM_YEARS}-year term · billed once
                </Text>
              </View>
              <Text variant="h2" color={colors.brand}>
                {CURRENCY} {STARTER_PRICE}
              </Text>
            </View>
            <Text variant="caption" color={colors.textMuted} style={{ marginTop: spacing.xs }}>
              This is a demo build -- no real payment is processed and no card details are collected. Agreeing below activates your subscription immediately.
            </Text>
          </Card>

          <Pressable onPress={() => setAgreed((a) => !a)} style={styles.agreeRow}>
            <View style={[
              styles.checkbox,
              { borderColor: colors.borderStrong },
              agreed && { backgroundColor: colors.primary, borderColor: colors.primary },
            ]}>
              {agreed ? <Ionicons name="checkmark" size={14} color="#FFF" /> : null}
            </View>
            <Text variant="bodyMd" style={{ flex: 1, marginLeft: spacing.xs }}>
              I have read and agree to the VisiLog Subscription Agreement above.
            </Text>
          </Pressable>

          <Button
            label={submitting ? 'Activating...' : `Agree & activate (${TERM_YEARS}-year term)`}
            icon="shield-checkmark-outline"
            onPress={onConfirm}
            disabled={!agreed || submitting}
            style={{ marginTop: spacing.md }}
          />
        </>
      ) : null}
    </Screen>
  );
}

const styles = StyleSheet.create({
  terms: { lineHeight: 20 },
  planRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  agreeRow: {
    flexDirection: 'row', alignItems: 'center',
    marginTop: spacing.md, paddingVertical: spacing.xs,
  },
  checkbox: {
    width: 20, height: 20, borderRadius: 6,
    borderWidth: 1.5,
    alignItems: 'center', justifyContent: 'center',
  },
});
'@)

# --- src\screens\VisitorsScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\VisitorsScreen.tsx', @'
import React, { useMemo, useState } from 'react';
import { View, SectionList, StyleSheet, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, Input, Segmented, EmptyState, Avatar, ExportModal,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtTime, fmtDateTime, fmtDuration, splitRecentOlder } from '../data/format';
import { toCsv, toHtmlTable, exportCsvFile, exportPdfFile, type ExportColumn } from '../data/export';
import type { RootStackNavigation } from '../types/navigation';
import type { Visitor } from '../types';

interface VisitorsScreenProps {
  navigation: RootStackNavigation;
}

type StatusFilter = 'all' | 'onsite' | 'completed';

// VisitorsScreen -- the live visitor log.
// Implements the "Visitor Logs" page from the User Guide:
//   - search by name, badge number, or host
//   - status filter: All / On-site / Completed
//   - badge IDs are auto-generated (VIS-YYYY-NNN)
//   - each row links into a detail page where check-out happens
// A floating "Register" button opens the registration modal.
export default function VisitorsScreen({ navigation }: VisitorsScreenProps) {
  const { colors } = useTheme();
  const { visitors, employeeById } = useData();
  const [query, setQuery] = useState('');
  const [status, setStatus] = useState<StatusFilter>('all');
  const [exporting, setExporting] = useState(false);

  // Filter pipeline: text search across name/badge/host, then status.
  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return visitors
      .filter((v) => {
        if (status !== 'all' && v.status !== status) return false;
        if (!q) return true;
        const host = employeeById(v.hostId);
        return (
          v.fullName.toLowerCase().includes(q) ||
          v.badgeId.toLowerCase().includes(q) ||
          (host?.name || '').toLowerCase().includes(q)
        );
      })
      .sort((a, b) => new Date(b.checkInAt).getTime() - new Date(a.checkInAt).getTime());
  }, [visitors, query, status]);

  const sections = useMemo(
    () => splitRecentOlder(filtered, (v) => v.checkInAt),
    [filtered]
  );

  // Exports whatever the search/status filters currently show, so
  // "export" always matches what's on screen rather than the whole log.
  const exportColumns: ExportColumn<Visitor>[] = [
    { header: 'Name', get: (v) => v.fullName },
    { header: 'Badge', get: (v) => v.badgeId },
    { header: 'Status', get: (v) => (v.status === 'onsite' ? 'On-site' : 'Completed') },
    { header: 'Purpose', get: (v) => v.purpose },
    { header: 'Host', get: (v) => employeeById(v.hostId)?.name || '' },
    { header: 'Company', get: (v) => v.company },
    { header: 'Check-in', get: (v) => fmtDateTime(v.checkInAt) },
    { header: 'Check-out', get: (v) => (v.checkOutAt ? fmtDateTime(v.checkOutAt) : '') },
  ];
  const onExportCsv = () => exportCsvFile(`visitors-${Date.now()}.csv`, toCsv(filtered, exportColumns));
  const onExportPdf = () => exportPdfFile(`visitors-${Date.now()}.pdf`, toHtmlTable('Visitor log', filtered, exportColumns));

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Visitors"
          subtitle="Live visitor log & check-in"
          onBackPress={() => navigation.goBack()}
          rightActions={[
            { icon: 'download-outline', onPress: () => setExporting(true) },
            { icon: 'person-add', onPress: () => navigation.navigate('RegisterVisitor') },
          ]}
        />

        <Input
          placeholder="Search name, badge or host"
          value={query}
          onChangeText={setQuery}
          icon="search"
        />

        <Segmented
          value={status}
          onChange={setStatus}
          options={[
            { label: 'All', value: 'all' },
            { label: 'On-site', value: 'onsite' },
            { label: 'Completed', value: 'completed' },
          ]}
        />
      </View>

      <SectionList
        sections={sections}
        keyExtractor={(v) => v.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.sm }} />}
        renderSectionHeader={({ section }) => (
          <Text variant="eyebrow" color={colors.textMuted} style={[styles.sectionHeader, { backgroundColor: colors.background }]}>
            {section.title}
          </Text>
        )}
        ListEmptyComponent={
          <EmptyState
            icon="people-outline"
            title="No visitors match"
            message={
              status === 'onsite'
                ? 'No one is currently on-site. Tap the + button to register a walk-in.'
                : 'Try a different search or status filter.'
            }
            actionLabel="Register visitor"
            onAction={() => navigation.navigate('RegisterVisitor')}
          />
        }
        renderItem={({ item }) => {
          const host = employeeById(item.hostId);
          return (
            <VisitorRow
              visitor={item}
              hostName={host?.name}
              onPress={() => navigation.navigate('VisitorDetail', { visitorId: item.id })}
            />
          );
        }}
      />

      <ExportModal
        visible={exporting}
        title="Export visitor log"
        onClose={() => setExporting(false)}
        onExportCsv={onExportCsv}
        onExportPdf={onExportPdf}
      />
    </Screen>
  );
}

// Single row inside the visitor list. Status drives the card's accent
// stripe (on the leading edge) AND a pill badge on the right.
function VisitorRow({
  visitor, hostName, onPress,
}: { visitor: Visitor; hostName?: string; onPress: () => void }) {
  const { colors } = useTheme();
  const isOnsite = visitor.status === 'onsite';
  const accent = isOnsite ? 'onsite' : 'neutral';
  return (
    <Card accent={accent} padded={false} onPress={onPress} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <Avatar name={visitor.fullName} size={44} />
        <View style={styles.middle}>
          <View style={styles.titleRow}>
            <Text variant="bodySemibold" numberOfLines={1}>{visitor.fullName}</Text>
            <Badge
              label={isOnsite ? 'On-site' : 'Completed'}
              status={isOnsite ? 'onsite' : 'neutral'}
              size="sm"
            />
          </View>
          <Text variant="caption" color={colors.textSecondary} numberOfLines={1}>
            {visitor.purpose} - {hostName || 'No host'}
          </Text>
          <View style={styles.metaRow}>
            <Ionicons name="card-outline" size={12} color={colors.textMuted} />
            <Text variant="caption" color={colors.textMuted} style={{ marginLeft: 4 }}>
              {visitor.badgeId}
            </Text>
            <View style={[styles.dot, { backgroundColor: colors.textMuted }]} />
            <Ionicons name="time-outline" size={12} color={colors.textMuted} />
            <Text variant="caption" color={colors.textMuted} style={{ marginLeft: 4 }}>
              {isOnsite
                ? `In - ${fmtTime(visitor.checkInAt)} - ${fmtDuration(visitor.checkInAt)}`
                : `${fmtTime(visitor.checkInAt)} → ${fmtTime(visitor.checkOutAt)}`}
            </Text>
          </View>
        </View>
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.sm, paddingBottom: spacing.huge },
  sectionHeader: { paddingVertical: spacing.xs },
  row: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  middle: { flex: 1, marginLeft: spacing.sm },
  titleRow: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', gap: 8,
  },
  metaRow: { flexDirection: 'row', alignItems: 'center', marginTop: 4 },
  dot: {
    width: 3, height: 3, borderRadius: 2,
    marginHorizontal: 8,
  },
});
'@)

# --- src\screens\AttendanceScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\AttendanceScreen.tsx', @'
import React, { useState } from 'react';
import { View, StyleSheet, FlatList } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Badge, EmptyState, Avatar, StatTile, ExportModal,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { fmtTime, fmtDateTime, fmtRelative } from '../data/format';
import { toCsv, toHtmlTable, exportCsvFile, exportPdfFile, type ExportColumn } from '../data/export';
import type { RootStackNavigation } from '../types/navigation';
import type { ClockRecord, ClockType, Employee } from '../types';

interface AttendanceScreenProps {
  navigation: RootStackNavigation;
}

// AttendanceScreen -- the clock-in/out ledger, presented as a tap log.
// (There's no separate NFC-tap-log concept in the real backend -- this
// reads the same shared clockRecords ledger as the Employee/Receptionist
// "on the clock" cards and ManagerClockInsScreen.)
export default function AttendanceScreen({ navigation }: AttendanceScreenProps) {
  const { clockRecords, employeeById } = useData();
  const [exporting, setExporting] = useState(false);

  const sorted = [...clockRecords].sort(
    (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
  );

  const exportColumns: ExportColumn<ClockRecord>[] = [
    { header: 'Employee', get: (t) => employeeById(t.employeeId)?.name || 'Unknown' },
    { header: 'Department', get: (t) => employeeById(t.employeeId)?.department || '' },
    { header: 'Type', get: (t) => (t.type === 'in' ? 'Tap in' : 'Tap out') },
    { header: 'Time', get: (t) => fmtDateTime(t.timestamp) },
  ];
  const onExportCsv = () => exportCsvFile(`attendance-${Date.now()}.csv`, toCsv(sorted, exportColumns));
  const onExportPdf = () => exportPdfFile(`attendance-${Date.now()}.pdf`, toHtmlTable('Attendance log', sorted, exportColumns));

  // Stat: how many distinct employees are currently signed in (based on
  // their last record of the day being 'in').
  const onsiteCount = (() => {
    const last: Record<string, ClockType> = {};
    sorted.forEach((t) => {
      if (!last[t.employeeId]) last[t.employeeId] = t.type;
    });
    return Object.values(last).filter((t) => t === 'in').length;
  })();

  const lateCount = sorted.filter((t) => {
    if (t.type !== 'in') return false;
    const d = new Date(t.timestamp);
    return d.getHours() > 8 || (d.getHours() === 8 && d.getMinutes() > 30);
  }).length;

  return (
    <Screen scroll={false} padded={false}>
      <View style={styles.head}>
        <Header
          title="Attendance"
          subtitle="Clock-in/out log & punctuality"
          rightActions={[
            { icon: 'download-outline', onPress: () => setExporting(true) },
            { icon: 'time-outline', onPress: () => navigation.navigate('History', { tab: 'clock' }) },
            { icon: 'close', onPress: () => navigation.goBack() },
          ]}
        />
        <View style={{ flexDirection: 'row' }}>
          <StatTile icon="people" tint="primary"
            label="Employees on-site" value={onsiteCount} />
          <View style={{ width: spacing.sm }} />
          <StatTile icon="alarm" tint="pending"
            label="Late arrivals" value={lateCount} />
        </View>
      </View>

      <FlatList
        data={sorted}
        keyExtractor={(t) => t.id}
        contentContainerStyle={styles.list}
        ItemSeparatorComponent={() => <View style={{ height: spacing.xs }} />}
        ListEmptyComponent={
          <EmptyState
            icon="card-outline"
            title="No clock records yet"
            message="Clock-in/out activity will appear here as it happens."
          />
        }
        renderItem={({ item }) => (
          <TapRow tap={item} employee={employeeById(item.employeeId)} />
        )}
      />

      <ExportModal
        visible={exporting}
        title="Export attendance log"
        onClose={() => setExporting(false)}
        onExportCsv={onExportCsv}
        onExportPdf={onExportPdf}
      />
    </Screen>
  );
}

function TapRow({ tap, employee }: { tap: ClockRecord; employee?: Employee }) {
  const { colors } = useTheme();
  const isIn = tap.type === 'in';
  return (
    <Card padded={false} style={{ marginHorizontal: spacing.md }}>
      <View style={styles.row}>
        <Avatar name={employee?.name || 'Unknown'} size={40} />
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Text variant="bodySemibold" numberOfLines={1}>
            {employee?.name || 'Unknown employee'}
          </Text>
          <Text variant="caption" color={colors.textSecondary}>
            {employee?.department || ''}
          </Text>
        </View>
        <View style={{ alignItems: 'flex-end' }}>
          <Badge label={isIn ? 'Tap in' : 'Tap out'} status={isIn ? 'success' : 'neutral'} size="sm" />
          <Text variant="caption" color={colors.textMuted} style={{ marginTop: 4 }}>
            {fmtTime(tap.timestamp)} - {fmtRelative(tap.timestamp)}
          </Text>
        </View>
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  head: { padding: spacing.md, paddingBottom: 0 },
  list: { padding: spacing.md, paddingTop: spacing.md, paddingBottom: spacing.huge },
  row: { flexDirection: 'row', alignItems: 'center', padding: spacing.sm },
});
'@)

# --- src\screens\CompanySetupScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\CompanySetupScreen.tsx', @'
import React, { useState } from 'react';
import { View, Image, StyleSheet, Alert, Pressable, Share } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import * as Location from 'expo-location';
import {
  Screen, Header, Text, Card, Button, Input,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import type { RootStackNavigation } from '../types/navigation';
import type { BrandTheme, IoniconName } from '../types';

interface CompanySetupScreenProps {
  navigation: RootStackNavigation;
}

// A handful of ready-made brand palettes, so a manager can restyle the
// app without needing a full color-picker UI.
const THEME_PRESETS: { id: string; label: string; theme: BrandTheme }[] = [
  { id: 'emerald', label: 'Emerald & gold', theme: {
    brand: '#0F3D2A', brandDark: '#0A2A1D', brandTint: '#155636',
    primary: '#C9A227', primaryPressed: '#D4AF37', primarySurface: '#FBF3DE', primarySurfaceStrong: '#F5E6BC',
  } },
  { id: 'navy', label: 'Navy & sky', theme: {
    brand: '#1B2A4A', brandDark: '#101A30', brandTint: '#25396B',
    primary: '#4F8EF7', primaryPressed: '#3B76DD', primarySurface: '#EAF1FE', primarySurfaceStrong: '#D3E3FD',
  } },
  { id: 'wine', label: 'Wine & gold', theme: {
    brand: '#5C1A1A', brandDark: '#3D1010', brandTint: '#7A2626',
    primary: '#E0A62B', primaryPressed: '#C48F20', primarySurface: '#FDF3DF', primarySurfaceStrong: '#F8E4B8',
  } },
  { id: 'plum', label: 'Plum & rose', theme: {
    brand: '#3B1D4A', brandDark: '#28132F', brandTint: '#512A66',
    primary: '#E0679F', primaryPressed: '#C74F86', primarySurface: '#FCEAF3', primarySurfaceStrong: '#F7D2E5',
  } },
];

// CompanySetupScreen -- Manager/Administrator only, reachable from
// Settings > Organisation > "Company branding". Covers everything the
// self-serve onboarding story needs after registration: sharing the
// company code, branding, and the office location that backs the
// clock-in geofence check. Staff roster (Directory) and meeting rooms
// each have their own dedicated screens, linked from here.
export default function CompanySetupScreen({ navigation }: CompanySetupScreenProps) {
  const { colors } = useTheme();
  const { organization, updateOrganization, updateOfficeLocation } = useAuth();

  const [name, setName] = useState(organization?.name || '');
  const [logoUrl, setLogoUrl] = useState(organization?.logoUrl || '');
  const [wifiNetworkName, setWifiNetworkName] = useState(organization?.wifiNetworkName || '');
  const [savingBrand, setSavingBrand] = useState(false);
  const [pickingLogo, setPickingLogo] = useState(false);

  const onPickLogo = async () => {
    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) {
      Alert.alert('Permission needed', 'Allow photo library access to upload a logo.');
      return;
    }
    setPickingLogo(true);
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ['images'],
        allowsEditing: true,
        aspect: [1, 1],
        quality: 0.6,
        base64: true,
      });
      if (result.canceled) return;
      const asset = result.assets[0];
      if (!asset.base64) {
        Alert.alert('Could not read image', 'Please try a different photo.');
        return;
      }
      setLogoUrl(`data:${asset.mimeType || 'image/jpeg'};base64,${asset.base64}`);
    } finally {
      setPickingLogo(false);
    }
  };

  const [latitude, setLatitude] = useState(String(organization?.officeLocation?.latitude ?? ''));
  const [longitude, setLongitude] = useState(String(organization?.officeLocation?.longitude ?? ''));
  const [radiusMeters, setRadiusMeters] = useState(String(organization?.officeLocation?.radiusMeters ?? '500'));
  const [savingLocation, setSavingLocation] = useState(false);
  const [locating, setLocating] = useState(false);

  // Fills lat/lng from the phone's own GPS instead of making someone
  // look up coordinates manually -- stand at the office and tap this.
  const onUseCurrentLocation = async () => {
    setLocating(true);
    try {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission needed', 'Allow location access to use your current position.');
        return;
      }
      const position = await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced });
      setLatitude(String(position.coords.latitude));
      setLongitude(String(position.coords.longitude));
    } catch {
      Alert.alert('Could not get location', 'Enable location services and try again.');
    } finally {
      setLocating(false);
    }
  };

  const onShareCode = () => {
    Share.share({
      message: `Join ${organization?.name} on VisiLog. Company code: ${organization?.code}`,
    }).catch(() => {});
  };

  const onSaveBrand = async () => {
    if (!name.trim()) {
      Alert.alert('Almost there', 'Give your company a name.');
      return;
    }
    setSavingBrand(true);
    const result = await updateOrganization({
      name: name.trim(), logoUrl: logoUrl.trim() || null, wifiNetworkName: wifiNetworkName.trim() || null,
    });
    setSavingBrand(false);
    if (!result.ok) Alert.alert('Could not save', result.error);
  };

  const onPickPreset = async (preset: typeof THEME_PRESETS[number]) => {
    setSavingBrand(true);
    const result = await updateOrganization({ theme: preset.theme });
    setSavingBrand(false);
    if (!result.ok) Alert.alert('Could not save', result.error);
  };

  const locationIsSet = latitude.trim() !== '' && longitude.trim() !== '';

  const onSaveLocation = async () => {
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const radius = parseInt(radiusMeters, 10) || 500;
    if (Number.isNaN(lat) || Number.isNaN(lng)) {
      Alert.alert('Almost there', 'Tap "Use my current location" while standing at the office first.');
      return;
    }
    setSavingLocation(true);
    const result = await updateOfficeLocation(lat, lng, radius);
    setSavingLocation(false);
    if (!result.ok) Alert.alert('Could not save', result.error);
    else Alert.alert('Saved', 'Staff will need to be within range of this location to clock in.');
  };

  return (
    <Screen>
      <Header
        title="Company Setup"
        subtitle="Branding, office location, staff & rooms"
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      {/* Company code */}
      <Card accent="info">
        <Text variant="caption" color={colors.textSecondary}>Company code</Text>
        <View style={styles.codeRow}>
          <Text style={[styles.code, { color: colors.brand }]}>{organization?.code}</Text>
          <Pressable onPress={onShareCode} style={[styles.shareBtn, { backgroundColor: colors.primarySurface }]}>
            <Ionicons name="share-outline" size={16} color={colors.primary} />
            <Text variant="caption" color={colors.brand} style={{ marginLeft: 4 }}>Share</Text>
          </Pressable>
        </View>
        <Text variant="caption" color={colors.textMuted}>
          Give this to your staff and post it wherever you invite visitors -- they enter it when they sign up.
        </Text>
      </Card>

      {/* Branding */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>Branding</Text>
      <Card>
        <Input label="Company name" value={name} onChangeText={setName} icon="business-outline" />

        <Text variant="label" color={colors.textSecondary} style={styles.logoLabel}>Logo</Text>
        <Pressable onPress={onPickLogo} disabled={pickingLogo} style={styles.logoRow}>
          <View style={[styles.logoPreview, { borderColor: colors.border, backgroundColor: colors.surfaceAlt }]}>
            {logoUrl ? (
              <Image source={{ uri: logoUrl }} style={styles.logoImage} resizeMode="cover" />
            ) : (
              <Ionicons name="image-outline" size={22} color={colors.textMuted} />
            )}
          </View>
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="bodySemibold" color={colors.brand}>
              {pickingLogo ? 'Opening photos...' : logoUrl ? 'Change logo' : 'Upload a logo'}
            </Text>
            <Text variant="caption" color={colors.textMuted}>From your device's photo library</Text>
          </View>
        </Pressable>

        <Input label="...or paste a logo URL" value={logoUrl} onChangeText={setLogoUrl}
          placeholder="https://..." icon="link-outline" autoCapitalize="none" />
        <Input label="WiFi network name" value={wifiNetworkName} onChangeText={setWifiNetworkName}
          placeholder="e.g. Office-WiFi" icon="wifi-outline" />
        <Text variant="caption" color={colors.textMuted} style={{ marginTop: -6, marginBottom: spacing.sm }}>
          Shown to staff as a reminder of which network to join before clocking in.
        </Text>
        <Button label={savingBrand ? 'Saving...' : 'Save'} onPress={onSaveBrand} disabled={savingBrand} />
      </Card>

      <Card style={{ marginTop: spacing.sm }}>
        <Text variant="bodySemibold" style={{ marginBottom: spacing.sm }}>Color theme</Text>
        <View style={styles.presetGrid}>
          {THEME_PRESETS.map((p) => (
            <Pressable key={p.id} onPress={() => onPickPreset(p)} style={styles.presetItem}>
              <View style={styles.presetSwatches}>
                <View style={[styles.swatch, { backgroundColor: p.theme.brand }]} />
                <View style={[styles.swatch, { backgroundColor: p.theme.primary }]} />
              </View>
              <Text variant="caption" color={colors.textSecondary}>{p.label}</Text>
            </Pressable>
          ))}
        </View>
      </Card>

      {/* Office location */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Office location
      </Text>
      <Card>
        <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.sm }}>
          Staff must be within this radius to clock in. Leave blank to skip the location check.
        </Text>
        <Button
          label={locating ? 'Getting your location...' : 'Use my current location'}
          icon="locate"
          variant="secondary"
          onPress={onUseCurrentLocation}
          disabled={locating}
          style={{ marginBottom: spacing.md }}
        />
        <View style={[styles.locationStatus, { backgroundColor: colors.surfaceAlt }]}>
          <Ionicons
            name={locationIsSet ? 'checkmark-circle' : 'alert-circle-outline'}
            size={18}
            color={locationIsSet ? colors.primary : colors.textMuted}
          />
          <Text variant="bodyMd" color={colors.textSecondary} style={{ marginLeft: 8 }}>
            {locationIsSet ? 'Location set' : 'No location set yet'}
          </Text>
        </View>
        <Input label="Radius (meters)" value={radiusMeters} onChangeText={setRadiusMeters}
          placeholder="e.g. 500" icon="radio-outline" keyboardType="number-pad" />
        <Button label={savingLocation ? 'Saving...' : 'Save location'} onPress={onSaveLocation} disabled={savingLocation} />
      </Card>

      {/* Staff & rooms */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Staff & rooms
      </Text>
      <Card padded={false}>
        <LinkRow icon="people-outline" title="Staff roster" sub="Add employees & set their roles"
          onPress={() => navigation.navigate('Directory')} />
        <View style={[styles.divider, { backgroundColor: colors.border }]} />
        <LinkRow icon="business-outline" title="Meeting rooms" sub="Add or remove bookable rooms"
          onPress={() => navigation.navigate('MeetingRooms')} />
        <View style={[styles.divider, { backgroundColor: colors.border }]} />
        <LinkRow icon="document-text-outline" title="Legal agreement" sub="The subscription terms your company agreed to"
          onPress={() => navigation.navigate('LegalAgreement')} />
      </Card>
    </Screen>
  );
}

function LinkRow({
  icon, title, sub, onPress,
}: { icon: IoniconName; title: string; sub: string; onPress: () => void }) {
  const { colors } = useTheme();
  return (
    <Pressable style={styles.linkRow} onPress={onPress}>
      <View style={[styles.linkIcon, { backgroundColor: colors.surfaceAlt }]}>
        <Ionicons name={icon} size={18} color={colors.brand} />
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="bodySemibold">{title}</Text>
        <Text variant="caption" color={colors.textSecondary}>{sub}</Text>
      </View>
      <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  logoLabel: { marginBottom: 6 },
  logoRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.md },
  logoPreview: {
    width: 56, height: 56, borderRadius: radius.md,
    borderWidth: 1, alignItems: 'center', justifyContent: 'center',
    overflow: 'hidden',
  },
  logoImage: { width: '100%', height: '100%' },
  codeRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginVertical: 4 },
  code: { fontSize: 22, fontWeight: '700', letterSpacing: 1 },
  shareBtn: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: spacing.sm, paddingVertical: 6, borderRadius: radius.pill },
  presetGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.md },
  presetItem: { alignItems: 'center', width: 70 },
  presetSwatches: { flexDirection: 'row', marginBottom: 4 },
  swatch: { width: 22, height: 22, borderRadius: 11, marginHorizontal: -4, borderWidth: 2, borderColor: '#fff' },
  linkRow: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  linkIcon: {
    width: 32, height: 32, borderRadius: 10,
    alignItems: 'center', justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, marginLeft: spacing.md + 32 + spacing.sm },
  locationStatus: {
    flexDirection: 'row', alignItems: 'center',
    borderRadius: radius.md, padding: spacing.sm, marginBottom: spacing.sm,
  },
});
'@)

# --- src\screens\SettingsScreen.tsx ---
[System.IO.File]::WriteAllText('src\screens\SettingsScreen.tsx', @'
import React, { useState } from 'react';
import { View, StyleSheet, Switch, Alert, Pressable } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import {
  Screen, Header, Text, Card, Button, Input, Avatar, Badge,
} from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import type { RootStackNavigation } from '../types/navigation';
import type { IoniconName } from '../types';

interface SettingsScreenProps {
  navigation: RootStackNavigation;
}

// SettingsScreen
// Per the VisiLog spec: profile info, password change, notification
// preferences, organisation branding, sign-out.
export default function SettingsScreen({ navigation }: SettingsScreenProps) {
  const { colors, dark, setOrgTheme, setDarkOverride } = useTheme();
  const { user, logout } = useAuth();

  const [notifyAppts, setNotifyAppts] = useState(true);
  const [notifyCalls, setNotifyCalls] = useState(true);
  const [notifyNfc, setNotifyNfc] = useState(false);

  const [editingPassword, setEditingPassword] = useState(false);
  const [currentPw, setCurrentPw] = useState('');
  const [newPw, setNewPw] = useState('');
  const [confirmPw, setConfirmPw] = useState('');

  const onSavePassword = () => {
    if (!currentPw || !newPw || !confirmPw) {
      Alert.alert('Missing fields', 'Fill in all three password fields.');
      return;
    }
    if (newPw.length < 8) {
      Alert.alert('Too short', 'New password must be at least 8 characters.');
      return;
    }
    if (newPw !== confirmPw) {
      Alert.alert('Mismatch', "New passwords don't match.");
      return;
    }
    Alert.alert('Password updated', 'Your password has been changed.');
    setCurrentPw(''); setNewPw(''); setConfirmPw('');
    setEditingPassword(false);
  };

  const onLogout = () => {
    Alert.alert('Sign out?', "You'll need to sign in again to access VisiLog.", [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Sign out', style: 'destructive', onPress: () => { logout(); setOrgTheme(null); } },
    ]);
  };

  return (
    <Screen>
      <Header
        title="Settings"
        subtitle="Profile, preferences & administration"
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      {/* Profile */}
      <Card>
        <View style={styles.profileRow}>
          <Avatar name={user?.name || 'You'} size={56} />
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="h3">{user?.name || 'Receptionist'}</Text>
            <Text variant="caption" color={colors.textSecondary}>
              {user?.email || ''}
            </Text>
            <View style={{ flexDirection: 'row', marginTop: 4 }}>
              <Badge label={user?.role || 'Receptionist'} status="info" size="sm" dot={false} />
            </View>
          </View>
        </View>
      </Card>

      {/* Password */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Security
      </Text>
      <Card>
        {editingPassword ? (
          <>
            <Input label="Current password" value={currentPw} onChangeText={setCurrentPw}
              placeholder="Current password" icon="lock-closed-outline" secureTextEntry />
            <Input label="New password" value={newPw} onChangeText={setNewPw}
              placeholder="New password" icon="key-outline" secureTextEntry
              hint="Must be at least 8 characters." />
            <Input label="Confirm new password" value={confirmPw} onChangeText={setConfirmPw}
              placeholder="Repeat new password" icon="shield-checkmark-outline" secureTextEntry />
            <View style={{ flexDirection: 'row' }}>
              <Button label="Cancel" variant="ghost" onPress={() => setEditingPassword(false)}
                style={{ flex: 1, marginRight: spacing.xs }} />
              <Button label="Save" onPress={onSavePassword}
                style={{ flex: 1, marginLeft: spacing.xs }} />
            </View>
          </>
        ) : (
          <Pressable onPress={() => setEditingPassword(true)} style={styles.linkRow}>
            <View style={[styles.linkIcon, { backgroundColor: colors.surfaceAlt }]}>
              <Ionicons name="key-outline" size={18} color={colors.brand} />
            </View>
            <View style={{ flex: 1 }}>
              <Text variant="bodySemibold">Change password</Text>
              <Text variant="caption" color={colors.textSecondary}>
                Update the password used to sign in.
              </Text>
            </View>
            <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
          </Pressable>
        )}
      </Card>

      {/* Appearance */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Appearance
      </Text>
      <Card padded={false}>
        <ToggleRow
          label="Dark mode"
          sub="Use a dark color scheme throughout the app."
          value={dark} onChange={setDarkOverride}
        />
      </Card>

      {/* Notifications -- these toggles are about staff workflow (someone
          else pre-booking, missing a call, a card being tapped), which
          means nothing to a visitor account, so this whole section is
          staff-only. */}
      {user?.role !== 'visitor' ? (
        <>
          <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
            Notifications
          </Text>
          <Card padded={false}>
            <ToggleRow
              label="New appointment alerts"
              sub="Notify me when a visitor pre-books."
              value={notifyAppts} onChange={setNotifyAppts}
            />
            <Divider />
            <ToggleRow
              label="Missed call alerts"
              sub="Push a reminder for unreturned calls."
              value={notifyCalls} onChange={setNotifyCalls}
            />
            <Divider />
            <ToggleRow
              label="NFC access events"
              sub="Notify on revoked or denied card taps."
              value={notifyNfc} onChange={setNotifyNfc}
            />
          </Card>
        </>
      ) : null}

      {/* Organisation -- administration for the whole tenant, so only the
          Manager/Administrator who owns that org sees it. Everyone else's
          settings are about their own account, not the company's. */}
      {user?.role === 'manager' ? (
        <>
          <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
            Organisation
          </Text>
          <Card padded={false}>
            <LinkRow icon="card-outline" title="Billing & subscription"
              sub={`${user.organizationName} · manage plan & invoices`}
              onPress={() => navigation.navigate('Billing')} />
            <Divider />
            <LinkRow icon="business-outline" title="Company Setup"
              sub="Branding, office location, staff & rooms"
              onPress={() => navigation.navigate('CompanySetup')} />
            <Divider />
            <LinkRow icon="globe-outline" title="Languages"
              sub="English (default)" />
          </Card>
        </>
      ) : null}

      {/* About */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        About
      </Text>
      <Card padded={false}>
        <LinkRow icon="information-circle-outline" title="VisiLog"
          sub="Build 1.0.0 - Reception + NFC"
          onPress={() => Alert.alert(
            'VisiLog',
            'Build 1.0.0 -- Reception + NFC\n\nVisitor management, staff attendance, and meeting-room booking for ' +
            (user?.organizationName || 'your organization') + '.'
          )} />
        <Divider />
        <LinkRow icon="help-circle-outline" title="Help & support"
          sub={user?.role === 'manager' ? 'Contact the VisiLog help desk' : 'Contact your VisiLog administrator'}
          onPress={() => Alert.alert(
            'Help & support',
            user?.role === 'manager'
              ? "As the Administrator, reach the VisiLog help desk directly for anything you can't resolve in Company Setup:\n\nPhone: 0509343709\nEmail: voldyabbey@gmail.com"
              : "For access issues, incorrect roster entries, or anything else you need changed, contact your organization's Administrator -- they manage your staff roster and company settings in Company Setup."
          )} />
        <Divider />
        <LinkRow icon="document-text-outline" title="Privacy policy"
          sub="How visitor data is collected & stored"
          onPress={() => Alert.alert(
            'Privacy policy',
            'Visitor and staff data you enter (name, phone, purpose of visit, badge/NFC activity) is stored for ' +
            (user?.organizationName || 'your organization') + ' only, and is never shared with other companies using VisiLog. ' +
            "It's used solely to run reception, attendance, and meeting-room booking for your organization."
          )} />
      </Card>

      <Button
        label="Sign out"
        variant="secondary"
        icon="log-out-outline"
        onPress={onLogout}
        style={{ marginTop: spacing.xl }}
      />
    </Screen>
  );
}

function ToggleRow({
  label, sub, value, onChange,
}: { label: string; sub: string; value: boolean; onChange: (value: boolean) => void }) {
  const { colors } = useTheme();
  return (
    <View style={styles.toggleRow}>
      <View style={{ flex: 1, marginRight: spacing.sm }}>
        <Text variant="bodySemibold">{label}</Text>
        <Text variant="caption" color={colors.textSecondary}>{sub}</Text>
      </View>
      <Switch
        value={value}
        onValueChange={onChange}
        trackColor={{ false: colors.borderStrong, true: colors.primary }}
        thumbColor="#FFFFFF"
      />
    </View>
  );
}

function LinkRow({
  icon, title, sub, onPress,
}: { icon: IoniconName; title: string; sub?: string; onPress?: () => void }) {
  const { colors } = useTheme();
  return (
    <Pressable style={styles.linkRow} onPress={onPress}>
      <View style={[styles.linkIcon, { backgroundColor: colors.surfaceAlt }]}>
        <Ionicons name={icon} size={18} color={colors.brand} />
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="bodySemibold">{title}</Text>
        {sub ? <Text variant="caption" color={colors.textSecondary}>{sub}</Text> : null}
      </View>
      <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
    </Pressable>
  );
}

function Divider() {
  const { colors } = useTheme();
  return <View style={[styles.divider, { backgroundColor: colors.border }]} />;
}

const styles = StyleSheet.create({
  profileRow: { flexDirection: 'row', alignItems: 'center' },
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  toggleRow: {
    flexDirection: 'row', alignItems: 'center',
    padding: spacing.md,
  },
  linkRow: {
    flexDirection: 'row', alignItems: 'center',
    padding: spacing.md,
  },
  linkIcon: {
    width: 32, height: 32, borderRadius: 10,
    alignItems: 'center', justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, marginLeft: spacing.md + 32 + spacing.sm },
});
'@)

Write-Host '--- Files written, verifying ---'
if (Test-Path "App.tsx") { Write-Host "OK   App.tsx" } else { Write-Host "MISSING App.tsx" -ForegroundColor Red }
if (Test-Path "src\theme\colors.ts") { Write-Host "OK   src\theme\colors.ts" } else { Write-Host "MISSING src\theme\colors.ts" -ForegroundColor Red }
if (Test-Path "src\theme\ThemeContext.tsx") { Write-Host "OK   src\theme\ThemeContext.tsx" } else { Write-Host "MISSING src\theme\ThemeContext.tsx" -ForegroundColor Red }
if (Test-Path "src\api\themePreference.ts") { Write-Host "OK   src\api\themePreference.ts" } else { Write-Host "MISSING src\api\themePreference.ts" -ForegroundColor Red }
if (Test-Path "src\components\Text.tsx") { Write-Host "OK   src\components\Text.tsx" } else { Write-Host "MISSING src\components\Text.tsx" -ForegroundColor Red }
if (Test-Path "src\components\Card.tsx") { Write-Host "OK   src\components\Card.tsx" } else { Write-Host "MISSING src\components\Card.tsx" -ForegroundColor Red }
if (Test-Path "src\components\Badge.tsx") { Write-Host "OK   src\components\Badge.tsx" } else { Write-Host "MISSING src\components\Badge.tsx" -ForegroundColor Red }
if (Test-Path "src\components\Avatar.tsx") { Write-Host "OK   src\components\Avatar.tsx" } else { Write-Host "MISSING src\components\Avatar.tsx" -ForegroundColor Red }
if (Test-Path "src\components\Input.tsx") { Write-Host "OK   src\components\Input.tsx" } else { Write-Host "MISSING src\components\Input.tsx" -ForegroundColor Red }
if (Test-Path "src\components\Header.tsx") { Write-Host "OK   src\components\Header.tsx" } else { Write-Host "MISSING src\components\Header.tsx" -ForegroundColor Red }
if (Test-Path "src\components\ListItem.tsx") { Write-Host "OK   src\components\ListItem.tsx" } else { Write-Host "MISSING src\components\ListItem.tsx" -ForegroundColor Red }
if (Test-Path "src\components\Segmented.tsx") { Write-Host "OK   src\components\Segmented.tsx" } else { Write-Host "MISSING src\components\Segmented.tsx" -ForegroundColor Red }
if (Test-Path "src\components\StatTile.tsx") { Write-Host "OK   src\components\StatTile.tsx" } else { Write-Host "MISSING src\components\StatTile.tsx" -ForegroundColor Red }
if (Test-Path "src\components\Select.tsx") { Write-Host "OK   src\components\Select.tsx" } else { Write-Host "MISSING src\components\Select.tsx" -ForegroundColor Red }
if (Test-Path "src\components\MultiSelect.tsx") { Write-Host "OK   src\components\MultiSelect.tsx" } else { Write-Host "MISSING src\components\MultiSelect.tsx" -ForegroundColor Red }
if (Test-Path "src\components\RescheduleModal.tsx") { Write-Host "OK   src\components\RescheduleModal.tsx" } else { Write-Host "MISSING src\components\RescheduleModal.tsx" -ForegroundColor Red }
if (Test-Path "src\components\CompanyMapSection.tsx") { Write-Host "OK   src\components\CompanyMapSection.tsx" } else { Write-Host "MISSING src\components\CompanyMapSection.tsx" -ForegroundColor Red }
if (Test-Path "src\components\QuickDateTime.tsx") { Write-Host "OK   src\components\QuickDateTime.tsx" } else { Write-Host "MISSING src\components\QuickDateTime.tsx" -ForegroundColor Red }
if (Test-Path "src\components\ClockCard.tsx") { Write-Host "OK   src\components\ClockCard.tsx" } else { Write-Host "MISSING src\components\ClockCard.tsx" -ForegroundColor Red }
if (Test-Path "src\components\Screen.tsx") { Write-Host "OK   src\components\Screen.tsx" } else { Write-Host "MISSING src\components\Screen.tsx" -ForegroundColor Red }
if (Test-Path "src\components\CsvImportModal.tsx") { Write-Host "OK   src\components\CsvImportModal.tsx" } else { Write-Host "MISSING src\components\CsvImportModal.tsx" -ForegroundColor Red }
if (Test-Path "src\components\ExportModal.tsx") { Write-Host "OK   src\components\ExportModal.tsx" } else { Write-Host "MISSING src\components\ExportModal.tsx" -ForegroundColor Red }
if (Test-Path "src\components\BookMeetingForm.tsx") { Write-Host "OK   src\components\BookMeetingForm.tsx" } else { Write-Host "MISSING src\components\BookMeetingForm.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\DashboardScreen.tsx") { Write-Host "OK   src\screens\DashboardScreen.tsx" } else { Write-Host "MISSING src\screens\DashboardScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\ManagerHomeScreen.tsx") { Write-Host "OK   src\screens\ManagerHomeScreen.tsx" } else { Write-Host "MISSING src\screens\ManagerHomeScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\EmployeeHomeScreen.tsx") { Write-Host "OK   src\screens\EmployeeHomeScreen.tsx" } else { Write-Host "MISSING src\screens\EmployeeHomeScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\VisitorHomeScreen.tsx") { Write-Host "OK   src\screens\VisitorHomeScreen.tsx" } else { Write-Host "MISSING src\screens\VisitorHomeScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\NotificationsScreen.tsx") { Write-Host "OK   src\screens\NotificationsScreen.tsx" } else { Write-Host "MISSING src\screens\NotificationsScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\AppointmentsScreen.tsx") { Write-Host "OK   src\screens\AppointmentsScreen.tsx" } else { Write-Host "MISSING src\screens\AppointmentsScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\HistoryScreen.tsx") { Write-Host "OK   src\screens\HistoryScreen.tsx" } else { Write-Host "MISSING src\screens\HistoryScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\MeetingRoomsScreen.tsx") { Write-Host "OK   src\screens\MeetingRoomsScreen.tsx" } else { Write-Host "MISSING src\screens\MeetingRoomsScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\CallLogScreen.tsx") { Write-Host "OK   src\screens\CallLogScreen.tsx" } else { Write-Host "MISSING src\screens\CallLogScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\NFCLookupScreen.tsx") { Write-Host "OK   src\screens\NFCLookupScreen.tsx" } else { Write-Host "MISSING src\screens\NFCLookupScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\VisitorVisitsScreen.tsx") { Write-Host "OK   src\screens\VisitorVisitsScreen.tsx" } else { Write-Host "MISSING src\screens\VisitorVisitsScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\VisitorBookScreen.tsx") { Write-Host "OK   src\screens\VisitorBookScreen.tsx" } else { Write-Host "MISSING src\screens\VisitorBookScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\DirectoryScreen.tsx") { Write-Host "OK   src\screens\DirectoryScreen.tsx" } else { Write-Host "MISSING src\screens\DirectoryScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\VisitorBookingScreen.tsx") { Write-Host "OK   src\screens\VisitorBookingScreen.tsx" } else { Write-Host "MISSING src\screens\VisitorBookingScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\ManagerClockInsScreen.tsx") { Write-Host "OK   src\screens\ManagerClockInsScreen.tsx" } else { Write-Host "MISSING src\screens\ManagerClockInsScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\BillingScreen.tsx") { Write-Host "OK   src\screens\BillingScreen.tsx" } else { Write-Host "MISSING src\screens\BillingScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\NFCCardsScreen.tsx") { Write-Host "OK   src\screens\NFCCardsScreen.tsx" } else { Write-Host "MISSING src\screens\NFCCardsScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\ReportsScreen.tsx") { Write-Host "OK   src\screens\ReportsScreen.tsx" } else { Write-Host "MISSING src\screens\ReportsScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\RegisterVisitorScreen.tsx") { Write-Host "OK   src\screens\RegisterVisitorScreen.tsx" } else { Write-Host "MISSING src\screens\RegisterVisitorScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\EmployeeDetailScreen.tsx") { Write-Host "OK   src\screens\EmployeeDetailScreen.tsx" } else { Write-Host "MISSING src\screens\EmployeeDetailScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\VisitorDetailScreen.tsx") { Write-Host "OK   src\screens\VisitorDetailScreen.tsx" } else { Write-Host "MISSING src\screens\VisitorDetailScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\LegalAgreementScreen.tsx") { Write-Host "OK   src\screens\LegalAgreementScreen.tsx" } else { Write-Host "MISSING src\screens\LegalAgreementScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\VisitorsScreen.tsx") { Write-Host "OK   src\screens\VisitorsScreen.tsx" } else { Write-Host "MISSING src\screens\VisitorsScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\AttendanceScreen.tsx") { Write-Host "OK   src\screens\AttendanceScreen.tsx" } else { Write-Host "MISSING src\screens\AttendanceScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\CompanySetupScreen.tsx") { Write-Host "OK   src\screens\CompanySetupScreen.tsx" } else { Write-Host "MISSING src\screens\CompanySetupScreen.tsx" -ForegroundColor Red }
if (Test-Path "src\screens\SettingsScreen.tsx") { Write-Host "OK   src\screens\SettingsScreen.tsx" } else { Write-Host "MISSING src\screens\SettingsScreen.tsx" -ForegroundColor Red }

Stop-Transcript
Write-Host ''
Write-Host 'Done. Now run: npx tsc --noEmit' -ForegroundColor Green