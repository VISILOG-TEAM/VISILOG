import React, { type ReactNode } from 'react';
import {
  View,
  Image,
  ScrollView,
  StyleSheet,
  KeyboardAvoidingView,
  RefreshControl,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import { SafeAreaView, type Edge } from 'react-native-safe-area-context';
import { spacing } from '../theme/spacing';
import { useTheme } from '../theme/ThemeContext';
import { useAuth } from '../context/AuthContext';
import { useRefreshState } from './usePullToRefresh';

interface ScreenProps {
  children?: ReactNode;
  scroll?: boolean;
  padded?: boolean;
  style?: StyleProp<ViewStyle>;
  contentStyle?: StyleProp<ViewStyle>;
  edges?: Edge[];
  // Pull-to-refresh. Optional: leave both out and the screen still
  // pulls to refresh, reloading everything from the API (see below).
  // Pass them to take over -- a screen that has its own local state to
  // reset alongside the reload needs to drive it itself.
  //
  // Only applies to the scroll={true} (default) variant; scroll={false}
  // screens render their own FlatList and pass usePullToRefresh() into
  // its refreshControl prop directly.
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
        source={
          organization?.logoUrl ? { uri: organization.logoUrl } : require('../../assets/logo.png')
        }
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
  // Every scrolling screen gets pull-to-refresh for free. Doing it here
  // rather than per screen is the only way "every screen" stays true --
  // wiring it up individually meant 7 of 29 screens had it and the rest
  // silently didn't, with no way to tell which was which from the UI.
  const fallback = useRefreshState();
  const handleRefresh = onRefresh ?? fallback.onRefresh;
  const isRefreshing = onRefresh ? !!refreshing : fallback.refreshing;
  if (scroll) {
    return (
      <SafeAreaView
        style={[styles.safe, { backgroundColor: themeColors.background }, style]}
        edges={edges}
      >
        <Watermark />
        <KeyboardAvoidingView style={styles.flex} behavior="padding">
          <ScrollView
            contentContainerStyle={[padded && styles.padded, contentStyle]}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
            refreshControl={
              <RefreshControl
                refreshing={isRefreshing}
                onRefresh={handleRefresh}
                tintColor={themeColors.primary}
              />
            }
          >
            {children}
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    );
  }
  return (
    <SafeAreaView
      style={[styles.safe, { backgroundColor: themeColors.background }, style]}
      edges={edges}
    >
      <Watermark />
      <KeyboardAvoidingView style={styles.flex} behavior="padding">
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
