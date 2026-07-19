import React, { createContext, useContext, useMemo, useState, type ReactNode } from 'react';
import { buildColors, colors as defaultColors, type BrandTheme, type Colors } from './colors';

interface ThemeContextValue {
  colors: Colors;
  setOrgTheme: (theme: BrandTheme | null) => void;
}

// ThemeContext — makes the color palette multi-tenant. `setOrgTheme`
// is called by AuthContext whenever the signed-in organization changes
// (login, signup, registerCompany, or restoring a session on boot);
// every screen that reads colors via useTheme() re-renders with that
// org's brand colors live, no reload needed.
const ThemeContext = createContext<ThemeContextValue>({ colors: defaultColors, setOrgTheme: () => {} });

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [orgTheme, setOrgTheme] = useState<BrandTheme | null>(null);
  const colors = useMemo(() => buildColors(orgTheme), [orgTheme]);

  return (
    <ThemeContext.Provider value={{ colors, setOrgTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export const useTheme = () => useContext(ThemeContext);
