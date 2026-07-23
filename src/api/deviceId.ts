import * as Application from 'expo-application';
import { Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

const FALLBACK_KEY = 'visilog.deviceId';

// A persistent identifier for this physical device, sent along with
// every clock-in so the backend can lock a staff member's attendance to
// the phone they first used (see ClockRecordService.checkDeviceBinding)
// -- stops "give a coworker my password so they can clock in for me,"
// since it doesn't matter whose login was used, only whose phone it is.
// Prefers the OS-level identifier, which survives an app reinstall
// (unlike a locally-generated id would), so reinstalling the app can't
// be used to dodge the device lock.
export async function getDeviceId(): Promise<string | null> {
  try {
    if (Platform.OS === 'android') {
      const id = Application.getAndroidId();
      if (id) return id;
    } else if (Platform.OS === 'ios') {
      const id = await Application.getIosIdForVendorAsync();
      if (id) return id;
    }
  } catch {
    // Fall through to the AsyncStorage-based fallback below.
  }
  return getOrCreateFallbackId();
}

// For platforms where the OS-level id isn't available (web preview,
// simulators without one, etc.) -- weaker (an uninstall/reinstall
// resets it), but still better than no device check at all.
async function getOrCreateFallbackId(): Promise<string | null> {
  try {
    const existing = await AsyncStorage.getItem(FALLBACK_KEY);
    if (existing) return existing;
    const generated = `fallback-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    await AsyncStorage.setItem(FALLBACK_KEY, generated);
    return generated;
  } catch {
    return null;
  }
}
