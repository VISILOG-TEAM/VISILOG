import React, { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { apiClient, ApiError } from '../api/client';
import { setToken, clearToken, loadStoredToken } from '../api/tokenStore';
import { saveRememberedLogin, clearRememberedLogin } from '../api/rememberedLogin';
import { registerForPushNotificationsAsync } from '../data/pushNotifications';
import { useTheme } from '../theme/ThemeContext';
import type { AuthResult, Organization, Role, User } from '../types';

// AuthContext talks to the real VisiLog backend (see server/). Role is
// decided once, server-side, at signup time (by matching the signing-up
// email against the company's staff roster) -- there is no more
// role-picker or employee-ID-verify step on the frontend.

interface UserDto {
  id: string;
  email: string;
  name: string;
  role: string;
  employeeId: string | null;
  organizationId: string;
  organizationName: string;
  emailVerified: boolean;
}

interface AuthResponse {
  token: string;
  user: UserDto;
  organization: Organization;
}

interface OrganizationPatch {
  name?: string;
  logoUrl?: string | null;
  theme?: Organization['theme'];
  openingTime?: string | null;
  closingTime?: string | null;
}

interface MessageResult {
  ok: boolean;
  message: string;
}

interface AuthContextValue {
  user: User | null;
  organization: Organization | null;
  initializing: boolean;
  login: (
    email: string,
    password: string,
    companyCode: string,
    remember?: boolean,
  ) => Promise<AuthResult>;
  signup: (
    companyCode: string,
    email: string,
    password: string,
    name: string,
  ) => Promise<AuthResult>;
  loginWithGoogle: (companyCode: string, idToken: string) => Promise<AuthResult>;
  forgotPassword: (companyCode: string, email: string) => Promise<MessageResult>;
  resetPassword: (
    companyCode: string,
    email: string,
    code: string,
    newPassword: string,
  ) => Promise<MessageResult>;
  registerCompany: (
    companyName: string,
    adminName: string,
    adminEmail: string,
    adminPassword: string,
  ) => Promise<AuthResult>;
  verifyEmail: (code: string) => Promise<{ ok: boolean; error?: string }>;
  resendVerification: () => Promise<MessageResult>;
  logout: () => Promise<void>;
  verifyPassword: (password: string) => Promise<{ ok: boolean; error?: string }>;
  updateOrganization: (patch: OrganizationPatch) => Promise<AuthResult>;
  updateProfile: (name: string) => Promise<{ ok: boolean; error?: string }>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

// Backend roles are uppercase enum names (VISITOR/RECEPTIONIST/EMPLOYEE/
// MANAGER); every screen in this app was built against lowercase.
const mapUser = (userDto: UserDto): User => ({
  id: userDto.id,
  email: userDto.email,
  name: userDto.name,
  role: userDto.role.toLowerCase() as Role,
  employeeId: userDto.employeeId,
  organizationId: userDto.organizationId,
  organizationName: userDto.organizationName,
  // Accounts created before email verification existed were backfilled
  // as verified server-side; the `!== false` guard covers a response
  // from an older backend build that doesn't send the field at all,
  // which would otherwise strand everyone on the verify screen.
  emailVerified: userDto.emailVerified !== false,
});

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null); // null = signed out
  const [organization, setOrganization] = useState<Organization | null>(null);
  // True until a previously-stored session (if any) has been checked
  // against the backend, so RootNavigator can hold the splash screen
  // rather than flash the login screen for a signed-in user.
  const [initializing, setInitializing] = useState(true);
  const { setOrgTheme } = useTheme();

  // Keep the color palette in sync with whichever org is currently
  // signed in -- covers login/signup/registerCompany and boot-restore
  // in one place instead of every screen calling setOrgTheme itself.
  useEffect(() => {
    setOrgTheme(organization ? organization.theme : null);
  }, [organization, setOrgTheme]);

  // Registers this device's push token once someone's signed in -- one
  // place that covers every path that can set `user` (login, signup,
  // registerCompany, and session restore) instead of duplicating a call
  // at each. Silently does nothing if permission is denied, this isn't a
  // physical device, no EAS project id is configured yet, or (Android +
  // Expo Go) remote push isn't supported at all -- see
  // registerForPushNotificationsAsync and PushNotificationService.
  useEffect(() => {
    if (!user) return;
    let cancelled = false;
    registerForPushNotificationsAsync().then((token) => {
      if (cancelled || !token) return;
      apiClient.post('/api/v1/push-tokens', { token }).catch(() => {});
    });
    return () => {
      cancelled = true;
    };
  }, [user]);

  useEffect(() => {
    (async () => {
      const token = await loadStoredToken();
      if (!token) {
        setInitializing(false);
        return;
      }
      // The backend's free-tier host spins down when idle and takes up
      // to a minute to wake, so the first request after a quiet spell
      // often fails with a network error or 5xx -- NOT because the
      // stored session is bad. Retry through that window, and only
      // clear the token when the server itself rejects it (401/403).
      // Clearing on any failure -- what this used to do -- silently
      // logged people out whenever the app opened against a sleeping
      // backend, which reads as "the app forgot everything".
      for (let attempt = 0; attempt < 4; attempt++) {
        try {
          const [userDto, org] = await Promise.all([
            apiClient.get<UserDto>('/api/v1/auth/me'),
            apiClient.get<Organization>('/api/v1/org'),
          ]);
          setUser(mapUser(userDto));
          setOrganization(org);
          break;
        } catch (err) {
          if (err instanceof ApiError && (err.status === 401 || err.status === 403)) {
            // Genuinely stale/invalid token -- sign out quietly.
            await clearToken();
            break;
          }
          if (attempt < 3) {
            await new Promise((resolve) => setTimeout(resolve, (attempt + 1) * 5000));
          }
          // After the last attempt: keep the token (the backend may
          // just be waking up) and land on Login -- signing in again
          // once it's awake works, and the next app open restores the
          // session normally.
        }
      }
      setInitializing(false);
    })();
  }, []);

  // `persist` (default true) controls whether the token is written to
  // AsyncStorage -- LoginScreen's "Remember me" toggles this. false
  // keeps the token in memory only, so the session doesn't survive an
  // app restart even though it works normally until then.
  const applyAuthResponse = async (res: AuthResponse, persist = true) => {
    await setToken(res.token, persist);
    setUser(mapUser(res.user));
    setOrganization(res.organization);
  };

  // `companyCode` resolves which paying organization (tenant) this
  // login belongs to -- required since VisiLog serves several
  // companies, each with their own data and brand colors.
  const login = async (
    email: string,
    password: string,
    companyCode: string,
    remember = true,
  ): Promise<AuthResult> => {
    if (!email || !password || !companyCode) {
      return { ok: false, error: 'Enter your company code, email and password.' };
    }
    try {
      const res = await apiClient.post<AuthResponse>('/api/v1/auth/login', {
        companyCode: companyCode.trim(),
        email: email.trim(),
        password,
      });
      await applyAuthResponse(res, remember);
      if (remember) {
        await saveRememberedLogin({ companyCode: companyCode.trim(), email: email.trim() });
      } else {
        await clearRememberedLogin();
      }
      return { ok: true, organization: res.organization };
    } catch (err) {
      return { ok: false, error: err instanceof ApiError ? err.message : 'Login failed.' };
    }
  };

  // Creates a login account under an existing company. Role is decided
  // server-side: matches `email` against the company's staff roster
  // (that role) or falls back to visitor if there's no match.
  const signup = async (
    companyCode: string,
    email: string,
    password: string,
    name: string,
  ): Promise<AuthResult> => {
    if (!companyCode || !email || !password || !name) {
      return { ok: false, error: 'Please fill in every field above.' };
    }
    try {
      const res = await apiClient.post<AuthResponse>('/api/v1/auth/signup', {
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

  // Self-serve "sign your company up" -- creates the Organization, its
  // first Administrator (Manager) account, and hands back a company
  // code the admin can then share with their staff/visitors.
  const registerCompany = async (
    companyName: string,
    adminName: string,
    adminEmail: string,
    adminPassword: string,
  ): Promise<AuthResult> => {
    if (!companyName || !adminName || !adminEmail || !adminPassword) {
      return { ok: false, error: 'Please fill in every field above.' };
    }
    try {
      const res = await apiClient.post<AuthResponse>('/api/v1/companies/register', {
        companyName: companyName.trim(),
        adminName: adminName.trim(),
        adminEmail: adminEmail.trim(),
        adminPassword,
      });
      await applyAuthResponse(res);
      return { ok: true, organization: res.organization };
    } catch (err) {
      return {
        ok: false,
        error: err instanceof ApiError ? err.message : 'Could not register your company.',
      };
    }
  };

  // Google sign-in. The frontend never sees or checks the ID token
  // itself -- it hands the raw token Google issued straight to the
  // backend, which verifies it against Google's own servers (see
  // GoogleTokenService) before trusting anything in it. Same as
  // signup, an existing account for that email logs straight in; a new
  // one gets its role resolved from the staff roster.
  const loginWithGoogle = async (companyCode: string, idToken: string): Promise<AuthResult> => {
    if (!companyCode || !idToken) {
      return { ok: false, error: 'Enter your company code first.' };
    }
    try {
      const res = await apiClient.post<AuthResponse>('/api/v1/auth/google', {
        companyCode: companyCode.trim(),
        idToken,
      });
      await applyAuthResponse(res);
      return { ok: true, organization: res.organization };
    } catch (err) {
      return { ok: false, error: err instanceof ApiError ? err.message : 'Google sign-in failed.' };
    }
  };

  // Forgot Password: request a numeric reset code by email, then submit
  // it alongside a new password. Neither call touches the signed-in
  // session -- both work from the signed-out Login screen.
  const forgotPassword = async (companyCode: string, email: string): Promise<MessageResult> => {
    try {
      const res = await apiClient.post<{ message: string }>('/api/v1/auth/forgot-password', {
        companyCode: companyCode.trim(),
        email: email.trim(),
      });
      return { ok: true, message: res.message };
    } catch (err) {
      return {
        ok: false,
        message: err instanceof ApiError ? err.message : 'Could not send a reset code.',
      };
    }
  };

  const resetPassword = async (
    companyCode: string,
    email: string,
    code: string,
    newPassword: string,
  ): Promise<MessageResult> => {
    try {
      const res = await apiClient.post<{ message: string }>('/api/v1/auth/reset-password', {
        companyCode: companyCode.trim(),
        email: email.trim(),
        code: code.trim(),
        newPassword,
      });
      return { ok: true, message: res.message };
    } catch (err) {
      return {
        ok: false,
        message: err instanceof ApiError ? err.message : 'Could not reset your password.',
      };
    }
  };

  // Email verification. Both calls run on the token handed out at
  // signup -- which the backend deliberately restricts to these two
  // endpoints plus /auth/me until the code is entered.
  //
  // A successful verify returns a *replacement* token: the one we're
  // holding has "unverified" signed into it and would keep being
  // refused. applyAuthResponse swaps it in and updates `user`, which
  // is what lets RootNavigator move on to the real app.
  const verifyEmail = async (code: string): Promise<{ ok: boolean; error?: string }> => {
    if (!code.trim()) {
      return { ok: false, error: 'Enter the 6-digit code from your email.' };
    }
    try {
      const res = await apiClient.post<AuthResponse>('/api/v1/auth/verify-email', {
        code: code.trim(),
      });
      await applyAuthResponse(res);
      return { ok: true };
    } catch (err) {
      return {
        ok: false,
        error: err instanceof ApiError ? err.message : 'Could not verify that code.',
      };
    }
  };

  const resendVerification = async (): Promise<MessageResult> => {
    try {
      const res = await apiClient.post<{ message: string }>('/api/v1/auth/resend-verification', {});
      return { ok: true, message: res.message };
    } catch (err) {
      return {
        ok: false,
        message: err instanceof ApiError ? err.message : 'Could not send a new code.',
      };
    }
  };

  // Step-up confirmation before a sensitive action on the *current*
  // session -- currently just clock-in (see ClockCard). Re-checks the
  // signed-in user's own password without touching the stored token.
  const verifyPassword = async (password: string): Promise<{ ok: boolean; error?: string }> => {
    try {
      await apiClient.post('/api/v1/auth/verify-password', { password });
      return { ok: true };
    } catch (err) {
      return {
        ok: false,
        error: err instanceof ApiError ? err.message : 'Could not verify your password.',
      };
    }
  };

  const logout = async (): Promise<void> => {
    await clearToken();
    setUser(null);
    setOrganization(null);
  };

  // Company Setup > branding (manager only). `theme`, if present, is
  // sent as a whole object -- see UpdateOrgRequest on the backend.
  const updateOrganization = async (patch: OrganizationPatch): Promise<AuthResult> => {
    try {
      const org = await apiClient.patch<Organization>('/api/v1/org', patch);
      setOrganization(org);
      return { ok: true, organization: org };
    } catch (err) {
      return {
        ok: false,
        error: err instanceof ApiError ? err.message : 'Could not save your changes.',
      };
    }
  };

  // Settings > "Your profile" -- rename yourself. The JWT doesn't carry
  // the display name (see the backend's JwtService), so the existing
  // session stays valid and we just swap our own copy of the user.
  const updateProfile = async (name: string): Promise<{ ok: boolean; error?: string }> => {
    if (!name.trim()) {
      return { ok: false, error: 'Enter a name.' };
    }
    try {
      const dto = await apiClient.patch<UserDto>('/api/v1/auth/me', { name: name.trim() });
      setUser(mapUser(dto));
      return { ok: true };
    } catch (err) {
      return {
        ok: false,
        error: err instanceof ApiError ? err.message : 'Could not update your name.',
      };
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        organization,
        initializing,
        login,
        signup,
        loginWithGoogle,
        registerCompany,
        verifyEmail,
        resendVerification,
        logout,
        verifyPassword,
        forgotPassword,
        resetPassword,
        updateOrganization,
        updateProfile,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = (): AuthContextValue => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider');
  return ctx;
};
