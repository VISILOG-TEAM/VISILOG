import AsyncStorage from '@react-native-async-storage/async-storage';

// Holds the signed-in JWT in memory (so api/client.js can read it
// synchronously on every request) while mirroring it to AsyncStorage
// (so a signed-in session survives an app reload). AuthContext is the
// only thing that calls setToken/clearToken; everything else just
// reads via getToken().
const STORAGE_KEY = 'visilog.authToken';

let currentToken: string | null = null;

export const getToken = (): string | null => currentToken;

// `persist` false (LoginScreen's "Remember me" unchecked) keeps the
// token in memory only -- the app works normally for this launch, but
// won't restore the session on the next cold start.
export const setToken = async (token: string | null, persist = true): Promise<void> => {
  currentToken = token;
  if (!persist) {
    await AsyncStorage.removeItem(STORAGE_KEY);
    return;
  }
  if (token) {
    await AsyncStorage.setItem(STORAGE_KEY, token);
  } else {
    await AsyncStorage.removeItem(STORAGE_KEY);
  }
};

export const clearToken = async (): Promise<void> => {
  await setToken(null);
};

// Called once on app boot (see AuthContext) to restore a session from
// a previous app launch, before the first render that needs it.
export const loadStoredToken = async (): Promise<string | null> => {
  currentToken = await AsyncStorage.getItem(STORAGE_KEY);
  return currentToken;
};