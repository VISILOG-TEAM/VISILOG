import React, { useMemo, useRef, useState } from 'react';
import { View, StyleSheet, PanResponder, LayoutChangeEvent } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Text from './Text';
import Input from './Input';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import type { BrandTheme } from '../types';

// Hex <-> HSV. No color library dependency -- this is the whole of what
// the picker below needs, and pulling in a package for it would be a
// heavier addition than just writing the math.
function hexToHsv(hex: string): { h: number; s: number; v: number } {
  const clean = hex.replace('#', '').padEnd(6, '0');
  const r = parseInt(clean.substring(0, 2), 16) / 255;
  const g = parseInt(clean.substring(2, 4), 16) / 255;
  const b = parseInt(clean.substring(4, 6), 16) / 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const d = max - min;
  let h = 0;
  if (d !== 0) {
    if (max === r) h = (((g - b) / d) % 6) * 60;
    else if (max === g) h = ((b - r) / d + 2) * 60;
    else h = ((r - g) / d + 4) * 60;
    if (h < 0) h += 360;
  }
  const s = max === 0 ? 0 : d / max;
  return { h, s, v: max };
}

function hsvToHex(h: number, s: number, v: number): string {
  const c = v * s;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  const m = v - c;
  let r = 0;
  let g = 0;
  let b = 0;
  if (h < 60) [r, g, b] = [c, x, 0];
  else if (h < 120) [r, g, b] = [x, c, 0];
  else if (h < 180) [r, g, b] = [0, c, x];
  else if (h < 240) [r, g, b] = [0, x, c];
  else if (h < 300) [r, g, b] = [x, 0, c];
  else [r, g, b] = [c, 0, x];
  const toHex = (n: number) =>
    Math.max(0, Math.min(255, Math.round((n + m) * 255)))
      .toString(16)
      .padStart(2, '0');
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`.toUpperCase();
}

// Turns one picked accent color into the app's full 7-slot theme, the
// same slots CompanySetupScreen's hand-made presets fill in directly --
// this derives them algorithmically instead, by varying value/saturation
// at a fixed hue rather than requiring 7 separate choices.
export function themeFromHex(hex: string): BrandTheme {
  const { h, s, v } = hexToHsv(hex);
  const cap = (n: number) => Math.min(1, n);
  return {
    primary: hsvToHex(h, s, v),
    primaryPressed: hsvToHex(h, cap(s * 1.05), v * 0.82),
    primarySurface: hsvToHex(h, cap(s * 0.15), 1),
    primarySurfaceStrong: hsvToHex(h, cap(s * 0.28), 0.97),
    brand: hsvToHex(h, cap(s * 0.9), 0.22),
    brandDark: hsvToHex(h, cap(s * 0.9), 0.14),
    brandTint: hsvToHex(h, cap(s * 0.9), 0.3),
  };
}

const HUE_GRADIENT = [
  '#FF0000', '#FFFF00', '#00FF00', '#00FFFF', '#0000FF', '#FF00FF', '#FF0000',
] as const;

interface ColorPickerProps {
  value: string;
  onChange: (hex: string) => void;
}

// Full hue + saturation/brightness picker, built from expo-linear-gradient
// layers and PanResponder (both already in the dependency tree -- no new
// native module to install) rather than a drop-in color-picker package,
// so it always matches the app's own theming instead of its own styling.
export default function ColorPicker({ value, onChange }: ColorPickerProps) {
  const { colors } = useTheme();
  const initial = useMemo(() => hexToHsv(value || '#4F8EF7'), []); // eslint-disable-line react-hooks/exhaustive-deps
  const [hue, setHue] = useState(initial.h);
  const [sat, setSat] = useState(initial.s);
  const [val, setVal] = useState(initial.v || 1);
  const [hexInput, setHexInput] = useState(value || '');

  const [squareSize, setSquareSize] = useState({ width: 260, height: 180 });
  const [hueBarWidth, setHueBarWidth] = useState(260);

  // PanResponder callbacks are captured once (see the useRef lazy-init
  // below) and never rebuilt, so they can't close over per-render `const`
  // values like `hue`/`sat`/`squareSize` directly -- that would freeze
  // them at whatever those were on mount. Everything the handlers need
  // is read through this ref instead, kept fresh on every render.
  const liveRef = useRef({ hue, sat, val, squareSize, hueBarWidth, onChange });
  liveRef.current = { hue, sat, val, squareSize, hueBarWidth, onChange };

  const commit = (h: number, s: number, v: number) => {
    setHue(h);
    setSat(s);
    setVal(v);
    const hex = hsvToHex(h, s, v);
    setHexInput(hex);
    liveRef.current.onChange(hex);
  };

  const handleSquareTouch = (x: number, y: number) => {
    const { width, height } = liveRef.current.squareSize;
    const s = Math.max(0, Math.min(1, x / width));
    const v = Math.max(0, Math.min(1, 1 - y / height));
    commit(liveRef.current.hue, s, v);
  };

  const handleHueTouch = (x: number) => {
    const h = Math.max(0, Math.min(360, (x / liveRef.current.hueBarWidth) * 360));
    commit(h, liveRef.current.sat, liveRef.current.val);
  };

  const panResponders = useRef<{ square: ReturnType<typeof PanResponder.create>; hueBar: ReturnType<typeof PanResponder.create> } | null>(
    null,
  );
  if (!panResponders.current) {
    panResponders.current = {
      square: PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponder: () => true,
        onPanResponderGrant: (evt) => handleSquareTouch(evt.nativeEvent.locationX, evt.nativeEvent.locationY),
        onPanResponderMove: (evt) => handleSquareTouch(evt.nativeEvent.locationX, evt.nativeEvent.locationY),
      }),
      hueBar: PanResponder.create({
        onStartShouldSetPanResponder: () => true,
        onMoveShouldSetPanResponder: () => true,
        onPanResponderGrant: (evt) => handleHueTouch(evt.nativeEvent.locationX),
        onPanResponderMove: (evt) => handleHueTouch(evt.nativeEvent.locationX),
      }),
    };
  }
  const squarePanResponder = panResponders.current.square;
  const hueBarPanResponder = panResponders.current.hueBar;

  const onSquareLayout = (e: LayoutChangeEvent) => {
    setSquareSize({ width: e.nativeEvent.layout.width, height: e.nativeEvent.layout.height });
  };
  const onHueBarLayout = (e: LayoutChangeEvent) => {
    setHueBarWidth(e.nativeEvent.layout.width);
  };

  const onHexSubmit = (text: string) => {
    setHexInput(text);
    const clean = text.trim();
    if (/^#?[0-9a-fA-F]{6}$/.test(clean)) {
      const withHash = clean.startsWith('#') ? clean : `#${clean}`;
      const parsed = hexToHsv(withHash);
      setHue(parsed.h);
      setSat(parsed.s);
      setVal(parsed.v);
      onChange(withHash.toUpperCase());
    }
  };

  const thumbColor = hsvToHex(hue, sat, val);
  const theme = useMemo(() => themeFromHex(thumbColor), [thumbColor]);

  return (
    <View>
      <View
        style={[styles.square, { borderColor: colors.border }]}
        onLayout={onSquareLayout}
        {...squarePanResponder.panHandlers}
      >
        <View style={[StyleSheet.absoluteFill, { backgroundColor: hsvToHex(hue, 1, 1) }]} />
        <LinearGradient
          colors={['#FFFFFF', 'rgba(255,255,255,0)']}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 0 }}
          style={StyleSheet.absoluteFill}
        />
        <LinearGradient
          colors={['rgba(0,0,0,0)', '#000000']}
          start={{ x: 0, y: 0 }}
          end={{ x: 0, y: 1 }}
          style={StyleSheet.absoluteFill}
        />
        <View
          pointerEvents="none"
          style={[
            styles.thumb,
            {
              left: sat * squareSize.width - 9,
              top: (1 - val) * squareSize.height - 9,
              backgroundColor: thumbColor,
            },
          ]}
        />
      </View>

      <View
        style={styles.hueBar}
        onLayout={onHueBarLayout}
        {...hueBarPanResponder.panHandlers}
      >
        <LinearGradient
          colors={HUE_GRADIENT}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 0 }}
          style={StyleSheet.absoluteFill}
        />
        <View pointerEvents="none" style={[styles.hueThumb, { left: (hue / 360) * hueBarWidth - 3 }]} />
      </View>

      <View style={styles.hexRow}>
        <View style={[styles.hexPreview, { backgroundColor: thumbColor, borderColor: colors.border }]} />
        <View style={{ flex: 1, marginLeft: spacing.sm }}>
          <Input
            label="Hex"
            value={hexInput}
            onChangeText={onHexSubmit}
            placeholder="#4F8EF7"
            autoCapitalize="characters"
          />
        </View>
      </View>

      <Text variant="caption" color={colors.textMuted} style={{ marginTop: -6, marginBottom: spacing.sm }}>
        Preview
      </Text>
      <View style={styles.previewRow}>
        {[theme.brand, theme.brandDark, theme.brandTint, theme.primary, theme.primaryPressed, theme.primarySurfaceStrong].map(
          (c, i) => (
            <View key={i} style={[styles.previewSwatch, { backgroundColor: c }]} />
          ),
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  square: {
    width: '100%',
    height: 180,
    borderRadius: radius.md,
    borderWidth: 1,
    overflow: 'hidden',
  },
  thumb: {
    position: 'absolute',
    width: 18,
    height: 18,
    borderRadius: 9,
    borderWidth: 2,
    borderColor: '#FFFFFF',
  },
  hueBar: {
    width: '100%',
    height: 20,
    borderRadius: radius.pill,
    overflow: 'hidden',
    marginTop: spacing.sm,
  },
  hueThumb: {
    position: 'absolute',
    top: -2,
    width: 6,
    height: 24,
    borderRadius: 3,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#00000040',
  },
  hexRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing.md,
  },
  hexPreview: {
    width: 44,
    height: 44,
    borderRadius: radius.sm,
    borderWidth: 1,
  },
  previewRow: {
    flexDirection: 'row',
  },
  previewSwatch: {
    flex: 1,
    height: 28,
    marginRight: 4,
    borderRadius: radius.sm,
  },
});
