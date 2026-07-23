import type { TextStyle } from 'react-native';

// VisiLog type system
// -------------------------------------------------------------
// Display face: Sora -- geometric, confident, modern. Used for screen
// titles and big numbers, with restraint.
// UI / body face: Inter -- chosen for its crisp figures, which matter a
// lot in a data-heavy reception app (timestamps, counts, logs).

export const fonts = {
  // display / headings
  displaySemibold: 'Sora_600SemiBold',
  displayBold: 'Sora_700Bold',
  displayExtra: 'Sora_800ExtraBold',
  // ui / body
  regular: 'Inter_400Regular',
  medium: 'Inter_500Medium',
  semibold: 'Inter_600SemiBold',
  bold: 'Inter_700Bold',
};

export type TypeScaleVariant =
  | 'display'
  | 'h1'
  | 'h2'
  | 'h3'
  | 'bodyLg'
  | 'body'
  | 'bodyMd'
  | 'bodySemibold'
  | 'label'
  | 'caption'
  | 'eyebrow';

// variant -> text style. Use via <Text variant="h1">...</Text>
export const typeScale: Record<TypeScaleVariant, TextStyle> = {
  display: { fontFamily: fonts.displayExtra, fontSize: 34, lineHeight: 40, letterSpacing: -0.5 },
  h1: { fontFamily: fonts.displayBold, fontSize: 26, lineHeight: 32, letterSpacing: -0.3 },
  h2: { fontFamily: fonts.displaySemibold, fontSize: 20, lineHeight: 26, letterSpacing: -0.2 },
  h3: { fontFamily: fonts.displaySemibold, fontSize: 17, lineHeight: 23 },

  bodyLg: { fontFamily: fonts.regular, fontSize: 16, lineHeight: 24 },
  body: { fontFamily: fonts.regular, fontSize: 15, lineHeight: 22 },
  bodyMd: { fontFamily: fonts.medium, fontSize: 15, lineHeight: 22 },
  bodySemibold: { fontFamily: fonts.semibold, fontSize: 15, lineHeight: 22 },

  label: { fontFamily: fonts.semibold, fontSize: 13, lineHeight: 18 },
  caption: { fontFamily: fonts.medium, fontSize: 12, lineHeight: 16 },
  eyebrow: {
    fontFamily: fonts.semibold,
    fontSize: 11,
    lineHeight: 14,
    letterSpacing: 1.2,
    textTransform: 'uppercase',
  },
};