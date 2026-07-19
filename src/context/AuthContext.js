import React, { createContext, useContext, useEffect, useState } from 'react';
import { apiClient, ApiError } from '../api/client';
import { setToken, clearToken, loadStoredToken } from '../api/tokenStore';
import { useTheme } from '../theme/ThemeContext';

// AuthContext talks to the real VisiLog backend (see server/). Role is
// decided once, server-side, at signup time (by matching the signing-up
// email against the company's staff roster) — there is no more
// role-picker or employee-ID-verify step on the frontend.
const AuthContext = createContext(null);

// Backend roles are uppercase enum names (VISITOR/RECEPTIONIST/EMPLOYEE/
// MANAGER); every screen in this app was built against lowercase.
const mapUser = (userDto) => ({
  id: userDto.id,
  email: userDto.email,
  name: userDto.name,
  role: userDto.role.toLowerCase(),
  employeeId: userDto.employeeId,
  organizationId: userDto.organizationId,
  organizationName: userDto.organizationName,
});

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null); // null = signed out
  const [organization, setOrganization] = useState(null);
  // True until a previously-stored session (if any) has been checked
  // against the backend, so RootNavigator can hold the splash screen
  // rather than flash the login screen for a signed-in user.
  const [initializing, setInitializing] = useState(true);
  const { setOrgTheme } = useTheme();

  // Keep the color palette in sync with whichever org is currently
  // signed in — covers login/signup/registerCompany and boot-restore
  // in one place instead of every screen calling setOrgTheme itself.
  useEffect(() => {
    setOrgTheme(organization ? organization.theme : null);
  }, [organization, setOrgTheme]);

  useEffect(() => {
    (async () => {
      const token = await loadStoredToken();
      if (!token) {
        setInitializing(false);
        return;
      }
      try {
        const [userDto, org] = await Promise.all([
          apiClient.get('/api/v1/auth/me'),
          apiClient.get('/api/v1/org'),
        ]);
        setUser(mapUser(userDto));
        setOrganization(org);
      } catch {
        // Stored token is stale/invalid — sign out quietly.
        await clearToken();
      } finally {
        setInitializing(false);
      }
    })();
  }, []);

  const applyAuthResponse = async (res) => {
    await setToken(res.token);
    setUser(mapUser(res.user));
    setOrganization(res.organization);
  };

  // `companyCode` resolves which paying organization (tenant) this
  // login belongs to — required since VisiLog serves several
  // companies, each with their own data and brand colors.
  const login = async (email, password, companyCode) => {
    if (!email || !password || !companyCode) {
      return { ok: false, error: 'Enter your company code, email and password.' };
    }
    try {
      const res = await apiClient.post('/api/v1/auth/login', {
        companyCode: companyCode.trim(),
        email: email.trim(),
        password,
      });
      await applyAuthResponse(res);
      return { ok: true, organization: res.organization };
    } catch (err) {
      return { ok: false, error: err instanceof ApiError ? err.message : 'Login failed.' };
    }
  };

  // Creates a login account under an existing company. Role is decided
  // server-side: matches `email` against the company's staff roster
  // (that role) or falls back to visitor if there's no match.
  const signup = async (companyCode, email, password, name) => {
    if (!companyCode || !email || !password || !name) {
      return { ok: false, error: 'Please fill in every field above.' };
    }
    try {
      const res = await apiClient.post('/api/v1/auth/signup', {
        companyCode: companyCode.trim(),
        email: email.trim(),
        password,
        name: name.trim(),
      });
      await applyAuthResponse(res);
      return { ok: true, organization: res.organization };
    } catch (err) {
      return { ok: false, error: err instanceof ApiError ? err.message : 'Signup failed.' };
    }
  };

  // Self-serve "sign your company up" — creates the Organization, its
  // first Administrator (Manager) account, and hands back a company
  // code the admin can then share with their staff/visitors.
  const registerCompany = async (companyName, adminName, adminEmail, adminPassword) => {
    if (!companyName || !adminName || !adminEmail || !adminPassword) {
      return { ok: false, error: 'Please fill in every field above.' };
    }
    try {
      const res = await apiClient.post('/api/v1/companies/register', {
        companyName: companyName.trim(),
        adminName: adminName.trim(),
        adminEmail: adminEmail.trim(),
        adminPassword,
      });
      await applyAuthResponse(res);
      return { ok: true, organization: res.organization };
    } catch (err) {
      return { ok: false, error: err instanceof ApiError ? err.message : 'Could not register your company.' };
    }
  };

  // Step-up confirmation before a sensitive action on the *current*
  // session — currently just clock-in (see ClockCard). Re-checks the
  // signed-in user's own password without touching the stored token.
  const verifyPassword = async (password) => {
    try {
      await apiClient.post('/api/v1/auth/verify-password', { password });
      return { ok: true };
    } catch (err) {
      return { ok: false, error: err instanceof ApiError ? err.message : 'Could not verify your password.' };
    }
  };

  const logout = async () => {
    await clearToken();
    setUser(null);
    setOrganization(null);
  };

  // Company Setup > branding (manager only). `theme`, if present, is
  // sent as a whole object — see UpdateOrgRequest on the backend.
  const updateOrganization = async (patch) => {
    try {
      const org = await apiClient.patch('/api/v1/org', patch);
      setOrganization(org);
      return { ok: true, organization: org };
    } catch (err) {
      return { ok: false, error: err instanceof ApiError ? err.message : 'Could not save your changes.' };
    }
  };

  // Company Setup > office location (manager only) — backs the
  // clock-in geofence check (src/data/locationCheck.js).
  const updateOfficeLocation = async (latitude, longitude, radiusMeters) => {
    try {
      const org = await apiClient.patch('/api/v1/org/office-location', { latitude, longitude, radiusMeters });
      setOrganization(org);
      return { ok: true, organization: org };
    } catch (err) {
      return { ok: false, error: err instanceof ApiError ? err.message : 'Could not save the office location.' };
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user, organization, initializing,
        login, signup, registerCompany, logout, verifyPassword,
        updateOrganization, updateOfficeLocation,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
