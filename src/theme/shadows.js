import { Platform } from 'react-native';

// React Native handles shadows differently on iOS (shadow*) and Android
// (elevation), so we express each level once and let Platform.select pick.
const make = (height, blur, opacity, elevation) =>
  Platform.select({
    ios: {
      shadowColor: '#0E1B2C',
      shadowOffset: { width: 0, height },
      shadowOpacity: opacity,
      shadowRadius: blur,
    },
    android: { elevation },
    default: {},
  });

export const shadows = {
  none: {},
  sm: make(1, 3, 0.06, 1),
  md: make(4, 12, 0.08, 3),
  lg: make(10, 24, 0.12, 8),
};
