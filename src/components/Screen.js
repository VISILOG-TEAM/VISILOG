import React from 'react';
import { View, ScrollView, StyleSheet } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { colors } from '../theme/colors';
import { spacing } from '../theme/spacing';

// Standard page shell: respects the notch/home-indicator, paints the app
// background, and gives you a scroll view by default. Set scroll={false}
// for screens that manage their own list or need vertical centring.
export default function Screen({
  children,
  scroll = true,
  padded = true,
  style,
  contentStyle,
  edges = ['top'],
}) {
  if (scroll) {
    return (
      <SafeAreaView style={[styles.safe, style]} edges={edges}>
        <ScrollView
          contentContainerStyle={[padded && styles.padded, contentStyle]}
          showsVerticalScrollIndicator={false}
          keyboardShouldPersistTaps="handled"
        >
          {children}
        </ScrollView>
      </SafeAreaView>
    );
  }
  return (
    <SafeAreaView style={[styles.safe, style]} edges={edges}>
      <View style={[styles.flex, padded && styles.padded, contentStyle]}>{children}</View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: colors.background },
  flex: { flex: 1 },
  padded: { padding: spacing.md, paddingBottom: spacing.xxxl },
});
