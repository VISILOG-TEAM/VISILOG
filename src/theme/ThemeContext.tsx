import React, {
  createContext,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { buildColors, colors as defaultColors, type BrandTheme, type Colors } from './colors';
import { loadDarkModeOverride, saveDarkModeOverride } from '../api/themePreference';

interface ThemeContextValue {
  colors: Colors;
  dark: boolean;
  setOrgTheme: (theme: BrandTheme | null) => void;
  // The app defaults to light regardless of the device's own OS
  // setting -- dark is opt-in only, via the Settings toggle.
  setDarkOverride: (value: boolean) => void;
}

// ThemeContext -- makes the color palette both multi-tenant and
// light/dark-aware. `setOrgTheme` is called by AuthContext whenever the
// signed-in organization changes (login, signup, registerCompany, or
// restoring a session on boot); every screen that reads colors via
// useTheme() re-renders with that org's brand colors live, no reload
// needed. `dark` defaults to false (light) and only becomes true once
// the user explicitly turns it on in Settings -- it does not follow the
// device's own OS-level dark mode setting.
const ThemeContext = createContext<ThemeContextValue>({
  colors: defaultColors,
  dark: false,
  setOrgTheme: () => {},
  setDarkOverride: () => {},
});

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [orgTheme, setOrgTheme] = useState<BrandTheme | null>(null);
  const [dark, setDarkState] = useState(false);

  React.useEffect(() => {
    loadDarkModeOverride().then((saved) => {
      if (saved != null) setDarkState(saved);
    });
  }, []);

  const setDarkOverride = (value: boolean) => {
    setDarkState(value);
    saveDarkModeOverride(value);
  };

  const colors = useMemo(() => buildColors(orgTheme, dark), [orgTheme, dark]);

  return (
    <ThemeContext.Provider value={{ colors, dark, setOrgTheme, setDarkOverride }}>
      {children}
    </ThemeContext.Provider>
  );
}

export const useTheme = () => useContext(ThemeContext);