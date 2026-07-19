import React, { type ReactNode } from 'react';
import {
  View, ScrollView, StyleSheet, KeyboardAvoidingView, type StyleProp, type ViewStyle,
} from 'react-native';
import { SafeAreaView, type Edge } from 'react-native-safe-area-context';
import { colors } from '../theme/colors';
import { spacing } from '../theme/spacing';

interface ScreenProps {
  children?: ReactNode;
  scroll?: boolean;
  padded?: boolean;
  style?: StyleProp<ViewStyle>;
  contentStyle?: StyleProp<ViewStyle>;
  edges?: Edge[];
}

// Standard page shell: respects the notch/home-indicator, paints the app
// background, and gives you a scroll view by default. Set scroll={false}
// for screens that manage their own list or need vertical centring.
//
// Wrapped in KeyboardAvoidingView so forms (Register visitor, Add
// employee, Book a visit, etc.) don't get their lower fields hidden
// behind the on-screen keyboard — every screen built on Screen gets
// this for free instead of each one having to wire it up itself.
export default function Screen({
  children,
  scroll = true,
  padded = true,
  style,
  contentStyle,
  edges = ['top'],
}: ScreenProps) {
  if (scroll) {
    return (
      <SafeAreaView style={[styles.safe, style]} edges={edges}>
        <KeyboardAvoidingView
          style={styles.flex}
          behavior="padding"
        >
          <ScrollView
            contentContainerStyle={[padded && styles.padded, contentStyle]}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
          >
            {children}
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    );
  }
  return (
    <SafeAreaView style={[styles.safe, style]} edges={edges}>
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
});
