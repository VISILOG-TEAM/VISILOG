import AsyncStorage from '@react-native-async-storage/async-storage';

// Persists the user's explicit dark-mode choice from Settings, if
// they've made one -- null means "not set yet, follow the device's
// own light/dark setting" (see ThemeContext).
const STORAGE_KEY = 'visilog.darkModeOverride';

export const saveDarkModeOverride = async (value: boolean | null): Promise<void> => {
  if (value === null) {
    await AsyncStorage.removeItem(STORAGE_KEY);
  } else {
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(value));
  }
};

export const loadDarkModeOverride = async (): Promise<boolean | null> => {
  const raw = await AsyncStorage.getItem(STORAGE_KEY);
  if (raw === null) return null;
  try {
    return JSON.parse(raw) as boolean;
  } catch {
    return null;
  }
};