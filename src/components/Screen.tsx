import React, { type ReactNode } from 'react';
import {
  View, Image, ScrollView, StyleSheet, KeyboardAvoidingView, RefreshControl,
  type StyleProp, type ViewStyle,
} from 'react-native';
import { SafeAreaView, type Edge } from 'react-native-safe-area-context';
import { colors } from '../theme/colors';
import { spacing } from '../theme/spacing';
import { useTheme } from '../theme/ThemeContext';

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
// taps), the same on every role since it's the app's own brand, not
// an org's. Sits under the ScrollView/View as an absolutely
// positioned sibling so it never scrolls with the content.
function Watermark() {
  return (
    <View style={styles.watermarkWrap} pointerEvents="none">
      <Image
        source={require('../../assets/logo.png')}
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
      <SafeAreaView style={[styles.safe, style]} edges={edges}>
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
    <SafeAreaView style={[styles.safe, style]} edges={edges}>
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
  safe: { flex: 1, backgroundColor: colors.background },
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