// VisiLog color system
// -------------------------------------------------------------
// Brand identity: a deep institutional emerald green paired with a
// gold accent (the "access-granted / tap" colour) — VRA's default.
// Functional status colours stay conventional (green / amber / red)
// so a receptionist can never misread a visitor's state at a glance
// — kept distinct from any brand colour so the two don't get confused.
//
// buildColors(brandTheme) makes this multi-tenant: each Organization
// in mockData.js carries its own {brand, primary, ...} shades, and
// ThemeContext calls this factory with the signed-in user's org to
// produce that org's full colors object. Neutrals/surfaces/status
// colors don't vary per org, only brand + primary do.

const palette = {
  // Brand emerald green (VRA default)
  emerald900: '#0A2A1D', // deepest — primary text on light surfaces
  emerald800: '#0F3D2A', // brand ink — nav bars, dark surfaces, logo
  emerald700: '#155636',
  emerald600: '#1D7248',

  // Gold accent (VRA default)
  gold600: '#C9A227', // primary action colour
  gold500: '#D4AF37', // pressed / hover
  gold100: '#F5E6BC',
  gold050: '#FBF3DE',

  // Cool, lobby-clean neutrals
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

  // Status families (high-clarity, conventional)
  green600: '#16A34A', green100: '#DCFCE7',
  amber600: '#D97706', amber100: '#FEF3C7',
  red600: '#DC2626', red100: '#FEE2E2',
  blue600: '#2563EB', blue100: '#DBEAFE',
};

// VRA's own brand shades, used when no organization theme is supplied
// (e.g. before login) or as the fallback for the default tenant.
const DEFAULT_BRAND_THEME = {
  brand: palette.emerald800,
  brandDark: palette.emerald900,
  brandTint: palette.emerald700,
  primary: palette.gold600,
  primaryPressed: palette.gold500,
  primarySurface: palette.gold050,
  primarySurfaceStrong: palette.gold100,
};

export const buildColors = (brandTheme) => {
  const b = brandTheme || DEFAULT_BRAND_THEME;
  return {
    // Brand (varies per organization)
    brand: b.brand,
    brandDark: b.brandDark,
    brandTint: b.brandTint,

    // Primary action (varies per organization)
    primary: b.primary,
    primaryPressed: b.primaryPressed,
    primarySurface: b.primarySurface,
    primarySurfaceStrong: b.primarySurfaceStrong,

    // Surfaces
    background: palette.slate050,
    surface: palette.white,
    surfaceAlt: palette.slate100,

    // Text
    textPrimary: palette.emerald900,
    textSecondary: palette.slate500,
    textMuted: palette.slate400,
    textInverse: palette.white,

    // Lines
    border: palette.slate200,
    borderStrong: palette.slate300,

    // Status: each key carries a fill (solid), a soft surface (bg) and a
    // readable foreground (fg) for text/icons on that surface.
    status: {
      onsite: { solid: palette.green600, bg: palette.green100, fg: '#0B6B33' },
      success: { solid: palette.green600, bg: palette.green100, fg: '#0B6B33' },
      pending: { solid: palette.amber600, bg: palette.amber100, fg: '#92400E' },
      rejected: { solid: palette.red600, bg: palette.red100, fg: '#991B1B' },
      error: { solid: palette.red600, bg: palette.red100, fg: '#991B1B' },
      info: { solid: palette.blue600, bg: palette.blue100, fg: '#1E40AF' },
      neutral: { solid: palette.slate500, bg: palette.slate100, fg: palette.slate700 },
    },

    // Escape hatch for raw values
    palette,
  };
};

// Default/back-compat static export — VRA's own colors. Used by
// pre-login screens (Splash, Login, Signup) where no organization is
// known yet, and as the fallback for `useTheme()`.
export const colors = buildColors();

// "#RRGGBB" -> "r,g,b", for building rgba() strings from a org's brand
// hex shades (e.g. AuthBackground's accent glow on post-login screens).
export const hexToRgb = (hex) => {
  const m = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex || '');
  if (!m) return '212,175,55';
  return [m[1], m[2], m[3]].map((h) => parseInt(h, 16)).join(',');
};
