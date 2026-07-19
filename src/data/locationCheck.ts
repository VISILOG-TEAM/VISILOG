import * as Location from 'expo-location';

// Best-effort "are you actually at the office" geofence check for
// clock-in, alongside the WiFi check in wifiCheck.js. Like that check,
// this is an approximation for a demo, not a real security control —
// a real deployment would verify server-side, not trust the client's
// self-reported GPS.
//
// expo-location supports both native and web (via the browser's
// Geolocation API), so unlike expo-network there's no separate web
// shim to work around here.

interface LatLng {
  latitude: number;
  longitude: number;
}

export interface OfficeLocation extends LatLng {
  radiusMeters: number;
}

export interface LocationCheckResult {
  ok: boolean;
  error?: string;
}

// Haversine distance between two lat/lng points, in meters.
function distanceMeters(a: LatLng, b: LatLng): number {
  const R = 6371000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(b.latitude - a.latitude);
  const dLon = toRad(b.longitude - a.longitude);
  const lat1 = toRad(a.latitude);
  const lat2 = toRad(b.latitude);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

// `officeLocation` is an org's { latitude, longitude, radiusMeters } from mockData.js.
export const isAtOffice = async (officeLocation?: OfficeLocation | null): Promise<LocationCheckResult> => {
  if (!officeLocation) return { ok: true };

  try {
    const { status } = await Location.requestForegroundPermissionsAsync();
    if (status !== 'granted') {
      return { ok: false, error: 'Location permission is required to clock in.' };
    }
    const position = await Location.getCurrentPositionAsync({
      accuracy: Location.Accuracy.Balanced,
    });
    const dist = distanceMeters(position.coords, officeLocation);
    if (dist > officeLocation.radiusMeters) {
      return { ok: false, error: 'You need to be at the office to clock in.' };
    }
    return { ok: true };
  } catch {
    // Location unavailable for some reason (denied, no GPS, etc.) —
    // fail closed, since "can't verify location" shouldn't silently
    // pass a location-based check the way it does for the WiFi one.
    return { ok: false, error: 'Could not verify your location. Enable location services and try again.' };
  }
};
