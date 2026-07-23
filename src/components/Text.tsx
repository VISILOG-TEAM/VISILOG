import React from 'react';
import { Text as RNText, type TextProps as RNTextProps } from 'react-native';
import { typeScale, type TypeScaleVariant } from '../theme/typography';
import { useTheme } from '../theme/ThemeContext';

interface TextProps extends RNTextProps {
  variant?: TypeScaleVariant;
  color?: string;
  align?: 'auto' | 'left' | 'right' | 'center' | 'justify';
}

// One Text to rule them all: pick a typographic role with `variant`,
// and the right font/size/spacing comes from the type scale. Falls
// back to the current theme's textPrimary (light or dark) when no
// explicit `color` is passed.
export default function Text({
  variant = 'body',
  color,
  align,
  style,
  children,
  numberOfLines,
  ...rest
}: TextProps) {
  const { colors } = useTheme();
  const base = typeScale[variant] || typeScale.body;
  return (
    <RNText
      numberOfLines={numberOfLines}
      style={[base, { color: color || colors.textPrimary }, align && { textAlign: align }, style]}
      {...rest}
    >
      {children}
    </RNText>
  );
}