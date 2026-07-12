import React, { createContext, useContext, useState } from 'react';
import { currentUser as defaultUser, employees } from '../data/mockData';

// AuthContext exposes the signed-in user, plus login/logout actions.
// In a real app these would hit an OAuth 2.0 / JWT endpoint (as described
// in the VisiLog architecture). For the demo we just toggle state.
const AuthContext = createContext(null);

// The demo credentials shipped in the VisiLog User Guide:
const DEMO_EMAIL = 'employee@company.com';
const DEMO_PASSWORD = 'password1234';
// Soft default so the role-picker can preselect something sensible —
// the picker itself is now the source of truth for the final role.
const detectRole = (email) => {
  const e = (email || '').toLowerCase().trim();
  if (e.startsWith('manager@')) return 'manager';
  if (e.startsWith('reception@') || e.startsWith('receptionist@')) return 'receptionist';
  if (e.endsWith('@company.com')) return 'employee';
  return 'visitor';
};

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null); // null = signed out
  // Shown once right after a successful login — resets on every fresh
  // login since this is a stateless mock (no persistence across app
  // reloads), but never reappears again during that same signed-in session.
  const [hasChosenRole, setHasChosenRole] = useState(false);
  // Only relevant once role === 'receptionist': have they passed the
  // employee-ID check yet?
  const [receptionistVerified, setReceptionistVerified] = useState(false);

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
      avatarTint: 'gold',
    });
    setHasChosenRole(false);
    setReceptionistVerified(false);
    return { ok: true };
  };

  // Finalizes the role chosen on the one-time RoleSelectScreen.
  const chooseRole = (role) => {
    const defaultNames = {
      visitor: 'Visitor',
      employee: 'Employee',
      receptionist: 'Receptionist',
      manager: 'Manager',
    };
    setUser((u) => (u ? { ...u, role, name: u.name || defaultNames[role] } : u));
    setHasChosenRole(true);
  };

  // Receptionist employee-ID check against the mock staff directory —
  // confirms the ID belongs to someone in the Reception department and
  // adopts their name, standing in for "the app checks the company database."
  const verifyReceptionistId = (employeeId) => {
    const clean = (employeeId || '').trim().toUpperCase();
    const match = employees.find((e) => e.employeeId.toUpperCase() === clean);
    if (!match) {
      return { ok: false, error: 'That employee ID was not found.' };
    }
    if (match.department !== 'Reception') {
      return { ok: false, error: 'This ID is not registered as a Receptionist.' };
    }
    setUser((u) => (u ? { ...u, name: match.name, employeeId: match.employeeId } : u));
    setReceptionistVerified(true);
    return { ok: true };
  };

  const logout = () => {
    setUser(null);
    setHasChosenRole(false);
    setReceptionistVerified(false);
  };

  return (
    <AuthContext.Provider
      value={{
        user, login, logout, DEMO_EMAIL, DEMO_PASSWORD,
        hasChosenRole, chooseRole,
        receptionistVerified, verifyReceptionistId,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
