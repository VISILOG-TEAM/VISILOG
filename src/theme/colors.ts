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

export type StatusKey =
  | 'onsite'
  | 'success'
  | 'pending'
  | 'rejected'
  | 'error'
  | 'info'
  | 'neutral';

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
  green600: '#16A34A',
  green100: '#DCFCE7',
  greenDarkBg: '#123322',
  greenDarkFg: '#4ADE80',
  amber600: '#D97706',
  amber100: '#FEF3C7',
  amberDarkBg: '#3A2A0C',
  amberDarkFg: '#FBBF24',
  red600: '#DC2626',
  red100: '#FEE2E2',
  redDarkBg: '#3A1414',
  redDarkFg: '#F87171',
  blue600: '#2563EB',
  blue100: '#DBEAFE',
  blueDarkBg: '#122A4A',
  blueDarkFg: '#60A5FA',

  // Deep, near-black neutrals (dark mode). Deliberately neutral slate,
  // NOT brand-tinted: an earlier green-tinted set made the whole app
  // read as "dark green UI" rather than a dark theme. Brand identity in
  // dark mode comes from the gold/primary accents on buttons, chips and
  // highlights -- the surfaces underneath stay neutral so those accents
  // actually pop instead of blending into a green wash.
  ink900: '#0F1214', // background
  ink800: '#171B1F', // surface
  ink700: '#20262B', // surfaceAlt
  ink600: '#2C333A', // border
  ink500: '#3D454E', // borderStrong
  mist100: '#F2F4F6', // textPrimary
  mist300: '#AEB6BF', // textSecondary
  mist500: '#7C858F', // textMuted
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
    return Math.round(av * weight + bv * (1 - weight))
      .toString(16)
      .padStart(2, '0');
  };
  return `#${blend(1)}${blend(2)}${blend(3)}`;
};

// Rough relative luminance, 0 (black) to 1 (white). Good enough to
// answer "would this read as text on a near-black surface".
const luminance = (hex: string): number => {
  const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!m) return 1;
  const [r, g, bl] = [1, 2, 3].map((i) => parseInt(m[i], 16) / 255);
  return 0.2126 * r + 0.7152 * g + 0.0722 * bl;
};

// Lifts a brand colour until it reads against the dark surfaces.
//
// An org's brand shades are authored for a WHITE background -- the
// default brand is #0F3D2A, a near-black green. Used unchanged in dark
// mode (which is what happened before) it lands almost exactly on the
// #171B1F surface behind it, so anything drawn in the brand colour --
// secondary button labels, header icons, the "Change display name"
// button -- became invisible. Rather than asking every org to supply a
// second dark palette, the colour is blended toward the light neutral
// until it clears a legibility threshold. A brand that's already light
// enough passes through untouched.
const liftForDark = (hex: string): string => {
  let out = hex;
  for (let i = 0; i < 8 && luminance(out) < 0.42; i++) {
    out = mix(palette.mist100, out, 0.2);
  }
  return out;
};

export const buildColors = (brandTheme?: BrandTheme | null, dark = false): Colors => {
  const b = brandTheme || DEFAULT_BRAND_THEME;
  return {
    // Brand shades are used as FOREGROUNDS (labels, icons) far more
    // than as fills, so in dark mode they get lifted to stay legible.
    brand: dark ? liftForDark(b.brand) : b.brand,
    brandDark: dark ? liftForDark(b.brandDark) : b.brandDark,
    brandTint: dark ? liftForDark(b.brandTint) : b.brandTint,
    // primary is the opposite: it's mostly a button FILL with white
    // text on top, so lifting it would wreck that contrast instead of
    // helping. Left as the org chose it.
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
