import React from 'react';
import { View, Image, StyleSheet } from 'react-native';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';

// Shows the signed-in org's uploaded logo at the top of a Home
// screen — renders nothing until a logo is actually set (Company
// Setup > Branding), so screens don't need their own null-checks.
export default function OrgLogo() {
  const { organization } = useAuth();
  const { colors } = useTheme();

  if (!organization?.logoUrl) return null;

  return (
    <View style={styles.wrap}>
      <View style={[styles.frame, { borderColor: colors.border, backgroundColor: colors.surface }]}>
        <Image source={{ uri: organization.logoUrl }} style={styles.image} resizeMode="cover" />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { alignItems: 'center', marginBottom: spacing.sm },
  frame: {
    width: 64, height: 64, borderRadius: radius.xl,
    borderWidth: 1, overflow: 'hidden',
  },
  image: { width: '100%', height: '100%' },
});
