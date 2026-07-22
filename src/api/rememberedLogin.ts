import AsyncStorage from '@react-native-async-storage/async-storage';

// "Remember me" on LoginScreen used to only keep the session token
// alive across app restarts -- it never actually remembered anything
// visible to the user, which is what the label promises. This stores
// just the company code + email (never the password) so the login
// form can pre-fill itself next time.
const STORAGE_KEY = 'visilog.rememberedLogin';

export interface RememberedLogin {
  companyCode: string;
  email: string;
}

export const saveRememberedLogin = async (details: RememberedLogin): Promise<void> => {
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(details));
};

export const loadRememberedLogin = async (): Promise<RememberedLogin | null> => {
  const raw = await AsyncStorage.getItem(STORAGE_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as RememberedLogin;
  } catch {
    return null;
  }
};

export const clearRememberedLogin = async (): Promise<void> => {
  await AsyncStorage.removeItem(STORAGE_KEY);
};