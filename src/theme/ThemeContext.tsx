import React, { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { useColorScheme } from 'react-native';
import { buildColors, colors as defaultColors, type BrandTheme, type Colors } from './colors';
import { loadDarkModeOverride, saveDarkModeOverride } from '../api/themePreference';

interface ThemeContextValue {
  colors: Colors;
  dark: boolean;
  setOrgTheme: (theme: BrandTheme | null) => void;
  // null = follow the device's own light/dark setting; true/false = the
  // user explicitly picked one on the Settings screen, which then wins
  // (and is remembered) until they change it again.
  setDarkOverride: (value: boolean | null) => void;
}

// ThemeContext -- makes the color palette both multi-tenant and
// light/dark-aware. `setOrgTheme` is called by AuthContext whenever the
// signed-in organization changes (login, signup, registerCompany, or
// restoring a session on boot); every screen that reads colors via
// useTheme() re-renders with that org's brand colors live, no reload
// needed. `dark` follows the device's system setting by default and
// falls back to the user's own Settings toggle once they've set one.
const ThemeContext = createContext<ThemeContextValue>({
  colors: defaultColors,
  dark: false,
  setOrgTheme: () => {},
  setDarkOverride: () => {},
});

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [orgTheme, setOrgTheme] = useState<BrandTheme | null>(null);
  const systemScheme = useColorScheme();
  const [darkOverride, setDarkOverrideState] = useState<boolean | null>(null);

  useEffect(() => {
    loadDarkModeOverride().then(setDarkOverrideState);
  }, []);

  const setDarkOverride = (value: boolean | null) => {
    setDarkOverrideState(value);
    saveDarkModeOverride(value);
  };

  const dark = darkOverride ?? systemScheme === 'dark';
  const colors = useMemo(() => buildColors(orgTheme, dark), [orgTheme, dark]);

  return (
    <ThemeContext.Provider value={{ colors, dark, setOrgTheme, setDarkOverride }}>
      {children}
    </ThemeContext.Provider>
  );
}

export const useTheme = () => useContext(ThemeContext);