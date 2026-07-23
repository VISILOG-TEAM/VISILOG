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