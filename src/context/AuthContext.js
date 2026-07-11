import React, { createContext, useContext, useState } from 'react';
import { currentUser as defaultUser } from '../data/mockData';

// AuthContext exposes the signed-in user, plus login/logout actions.
// In a real app these would hit an OAuth 2.0 / JWT endpoint (as described
// in the VisiLog architecture). For the demo we just toggle state.
const AuthContext = createContext(null);

// The demo credentials shipped in the VisiLog User Guide:
const DEMO_EMAIL = 'employee@company.com';
const DEMO_PASSWORD = 'password1234';
// Decide what role a user has from their email.
const detectRole = (email) => {
  const e = (email || '').toLowerCase().trim();
  if (e.startsWith('manager@')) return 'manager';
  if (e.startsWith('reception@') || e.startsWith('receptionist@')) return 'receptionist';
  if (e.endsWith('@company.com')) return 'employee';
  return 'visitor';
};

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null); // null = signed out

  const login = (email, password) => {
    if (!email || !password) {
      return { ok: false, error: 'Enter both an email and a password.' };
    }
    const role = detectRole(email);

    // Default name shown in the header for each role
    const defaultNames = {
      visitor: 'Visitor',
      employee: 'Employee',
      receptionist: 'Receptionist',
      manager: 'Manager',
    };

    setUser({
      id: `${role}-${Date.now()}`,
      email: email.trim(),
      name: defaultNames[role],
      role,
      avatarTint: 'teal',
    });
    return { ok: true };
  };

  const logout = () => setUser(null);

  return (
    <AuthContext.Provider value={{ user, login, logout, DEMO_EMAIL, DEMO_PASSWORD }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
