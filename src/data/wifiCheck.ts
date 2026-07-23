import { Platform } from 'react-native';
import * as Network from 'expo-network';

// Best-effort "are you on the company network" check for clock-in gating.
// There's no backend here to verify a specific SSID (and iOS restricts
// reading SSIDs without special entitlements anyway), so this checks
// WiFi vs. cellular as an approximation -- good enough for a demo, not a
// real security control.
//
// On a real phone (iOS/Android via Expo Go), expo-network correctly
// reports WIFI vs CELLULAR, so this blocks cellular data as intended.
// On web, browsers have no API to distinguish the two -- expo-network's
// web shim always reports UNKNOWN when online -- so there we treat
// "online at all" as passing rather than blocking the feature outright.
export const isOnWifi = async () => {
  try {
    const state = await Network.getNetworkStateAsync();
    if (Platform.OS === 'web') {
      return !!state.isConnected;
    }
    return state.type === Network.NetworkStateType.WIFI && !!state.isConnected;
  } catch {
    // Network module unavailable for some reason -- fail open so the
    // demo isn't blocked by a missing native module.
    return true;
  }
};