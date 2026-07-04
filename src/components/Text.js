import React from 'react';
import { Text as RNText } from 'react-native';
import { typeScale } from '../theme/typography';
import { colors } from '../theme/colors';

// One Text to rule them all: pick a typographic role with `variant`,
// and the right font/size/spacing comes from the type scale.
export default function Text({
  variant = 'body',
  color,
  align,
  style,
  children,
  numberOfLines,
  ...rest
}) {
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
