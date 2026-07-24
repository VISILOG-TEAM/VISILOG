import * as Location from 'expo-location';
import type { OfficeLocation } from '../types';

// Best-effort "are you actually at the office" geofence check for
// clock-in, alongside the WiFi check in wifiCheck.js. Like that check,
// this is an approximation for a demo, not a real security control --
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

// An org can have more than one office location (see
// DataContext.officeLocations) -- passes as soon as the phone is
// within range of any single one of them, so staff at a branch office
// aren't blocked by a radius set for headquarters.
export const isAtOffice = async (
  officeLocations?: OfficeLocation[] | null,
): Promise<LocationCheckResult> => {
  if (!officeLocations || officeLocations.length === 0) return { ok: true };

  try {
    const { status } = await Location.requestForegroundPermissionsAsync();
    if (status !== 'granted') {
      return { ok: false, error: 'Location permission is required to clock in.' };
    }
    const position = await Location.getCurrentPositionAsync({
      accuracy: Location.Accuracy.Balanced,
    });
    const withinAny = officeLocations.some(
      (loc) => distanceMeters(position.coords, loc) <= loc.radiusMeters,
    );
    if (!withinAny) {
      return { ok: false, error: 'You need to be at the office to clock in.' };
    }
    return { ok: true };
  } catch {
    // Location unavailable for some reason (denied, no GPS, etc.) --
    // fail closed, since "can't verify location" shouldn't silently
    // pass a location-based check the way it does for the WiFi one.
    return {
      ok: false,
      error: 'Could not verify your location. Enable location services and try again.',
    };
  }
};
