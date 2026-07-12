import React, { createContext, useContext, useMemo, useState } from 'react';
import { buildColors, colors as defaultColors } from './colors';

// ThemeContext — makes the color palette multi-tenant. `setOrgTheme`
// is called once the signed-in user's organization is known (see
// AuthContext.chooseRole / the company-code login flow); every screen
// that reads colors via useTheme() re-renders with that org's brand
// colors live, no reload needed.
const ThemeContext = createContext({ colors: defaultColors, setOrgTheme: () => {} });

export function ThemeProvider({ children }) {
  const [orgTheme, setOrgTheme] = useState(null);
  const colors = useMemo(() => buildColors(orgTheme), [orgTheme]);

  return (
    <ThemeContext.Provider value={{ colors, setOrgTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export const useTheme = () => useContext(ThemeContext);
