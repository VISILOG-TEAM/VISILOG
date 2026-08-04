import React, { useEffect, useMemo, useRef, useState } from 'react';
import {
  Modal,
  View,
  StyleSheet,
  TextInput,
  Pressable,
  FlatList,
  ActivityIndicator,
  Keyboard,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as Location from 'expo-location';
import { WebView } from 'react-native-webview';
import Text from './Text';
import Button from './Button';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';

interface MapLocationPickerProps {
  visible: boolean;
  initialLatitude?: number | null;
  initialLongitude?: number | null;
  onCancel: () => void;
  onConfirm: (latitude: number, longitude: number) => void;
}

interface SearchResult {
  displayName: string;
  latitude: number;
  longitude: number;
}

// Falls back to Accra, Ghana when nothing's set yet -- roughly centres
// the map on VRA's own default tenant rather than opening on the
// middle of the Atlantic (0, 0).
const DEFAULT_CENTER = { lat: 5.6037, lng: -0.187 };

// Resolves to null if `promise` hasn't settled within `ms` -- a GPS fix
// has no built-in timeout, and this map opens in a modal the user is
// staring at, so it can't just spin forever waiting for one.
function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T | null> {
  return Promise.race([
    promise,
    new Promise<null>((resolve) => setTimeout(() => resolve(null), ms)),
  ]);
}

// Builds the self-contained page the WebView loads: Leaflet + OpenStreetMap
// tiles pulled from a CDN, no API key needed (unlike the Google Maps JS
// SDK, which would require a billing-enabled key this app can't ship
// with). Tap or drag the pin to choose the exact spot; "Confirm" posts
// the coordinates back to React Native via postMessage -- the only
// channel a WebView has to talk to its host. `window.flyTo` is the
// reverse channel: RN calls it (via injectJavaScript) to move the pin
// after a search result is picked, without reloading the whole page.
function buildMapHtml(lat: number, lng: number): string {
  return `<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <style>
    html, body, #map { height: 100%; margin: 0; padding: 0; }
    .confirm-btn {
      position: absolute; bottom: 16px; left: 16px; right: 16px; z-index: 1000;
      background: #0F3D2A; color: #fff; text-align: center; padding: 14px;
      border-radius: 10px; font-family: -apple-system, Roboto, sans-serif;
      font-weight: 600; font-size: 15px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);
    }
  </style>
</head>
<body>
  <div id="map"></div>
  <div class="confirm-btn" onclick="confirmPick()">Confirm this spot</div>
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <script>
    const map = L.map('map').setView([${lat}, ${lng}], 16);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors',
      maxZoom: 19,
    }).addTo(map);
    const marker = L.marker([${lat}, ${lng}], { draggable: true }).addTo(map);
    map.on('click', (e) => marker.setLatLng(e.latlng));
    function confirmPick() {
      const pos = marker.getLatLng();
      window.ReactNativeWebView.postMessage(JSON.stringify({ latitude: pos.lat, longitude: pos.lng }));
    }
    window.flyTo = function(lat, lng) {
      const pos = [lat, lng];
      marker.setLatLng(pos);
      map.setView(pos, 16);
    };
  </script>
</body>
</html>`;
}

// Free-text place search via Nominatim (OpenStreetMap's own geocoder) --
// same "no API key" reasoning as the map tiles themselves. Debounced so
// every keystroke doesn't fire a request; Nominatim's usage policy asks
// for a real identifying User-Agent and no more than ~1 request/second,
// both of which the debounce and app name below take care of.
async function searchPlaces(query: string): Promise<SearchResult[]> {
  const url = `https://nominatim.openstreetmap.org/search?format=json&addressdetails=0&limit=6&q=${encodeURIComponent(query)}`;
  const res = await fetch(url, {
    headers: { 'User-Agent': 'VisiLog/1.0 (office-location-picker)' },
  });
  if (!res.ok) throw new Error('Search failed');
  const data = await res.json();
  return (Array.isArray(data) ? data : []).map((r: { display_name: string; lat: string; lon: string }) => ({
    displayName: r.display_name,
    latitude: parseFloat(r.lat),
    longitude: parseFloat(r.lon),
  }));
}

// Full-screen modal wrapping the map -- office-location picking is a
// one-time setup task, not something that benefits from squeezing into
// the same card as the rest of the form.
export default function MapLocationPicker({
  visible,
  initialLatitude,
  initialLongitude,
  onCancel,
  onConfirm,
}: MapLocationPickerProps) {
  const { colors } = useTheme();
  const [picked, setPicked] = useState<{ latitude: number; longitude: number } | null>(null);
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchResult[]>([]);
  const [searching, setSearching] = useState(false);
  const [showResults, setShowResults] = useState(false);
  const webviewRef = useRef<WebView>(null);

  const html = useMemo(
    () =>
      buildMapHtml(
        initialLatitude ?? DEFAULT_CENTER.lat,
        initialLongitude ?? DEFAULT_CENTER.lng,
      ),
    // Only rebuild the page when the modal opens -- rebuilding on every
    // drag/tap would reload the whole WebView and reset the pin.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [visible],
  );

  // Reset search state each time the picker is (re)opened, so a stale
  // query/result list from a previous location doesn't linger.
  useEffect(() => {
    if (visible) {
      setQuery('');
      setResults([]);
      setShowResults(false);
      setPicked(null);
    }
  }, [visible]);

  // Only when there's no existing/typed location to center on (adding a
  // brand-new office, not editing a saved one) -- opens on the device's
  // actual current position (e.g. Kumasi, Accra, wherever the manager
  // actually is) instead of always defaulting to the same fixed point,
  // same as onUseCurrentLocation elsewhere in Company Setup. Flies the
  // already-rendered map there via the same channel search results use,
  // rather than rebuilding the WebView (see the html useMemo above).
  useEffect(() => {
    if (!visible || initialLatitude != null || initialLongitude != null) return;
    let cancelled = false;
    (async () => {
      try {
        const { status } = await Location.getForegroundPermissionsAsync();
        if (status !== 'granted') return;
        const position =
          (await Location.getLastKnownPositionAsync({ maxAge: 5 * 60 * 1000 })) ??
          (await withTimeout(
            Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced }),
            10000,
          ));
        if (cancelled || !position) return;
        const { latitude, longitude } = position.coords;
        setPicked({ latitude, longitude });
        webviewRef.current?.injectJavaScript(`window.flyTo(${latitude}, ${longitude}); true;`);
      } catch {
        // Fall back to the default center -- no GPS fix is not worth
        // interrupting the picker over, the pin is still draggable.
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [visible, initialLatitude, initialLongitude]);

  useEffect(() => {
    if (query.trim().length < 3) {
      setResults([]);
      return;
    }
    let cancelled = false;
    setSearching(true);
    const timer = setTimeout(() => {
      searchPlaces(query.trim())
        .then((r) => {
          if (!cancelled) setResults(r);
        })
        .catch(() => {
          if (!cancelled) setResults([]);
        })
        .finally(() => {
          if (!cancelled) setSearching(false);
        });
    }, 500);
    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [query]);

  const onSelectResult = (result: SearchResult) => {
    setShowResults(false);
    Keyboard.dismiss();
    setQuery(result.displayName);
    setPicked({ latitude: result.latitude, longitude: result.longitude });
    webviewRef.current?.injectJavaScript(
      `window.flyTo(${result.latitude}, ${result.longitude}); true;`,
    );
  };

  return (
    <Modal visible={visible} animationType="slide" onRequestClose={onCancel}>
      <View style={[styles.wrap, { backgroundColor: colors.background }]}>
        <View style={styles.header}>
          <Text variant="h3">Choose office location</Text>
          <Text variant="caption" color={colors.textSecondary}>
            Search for a place, or tap/drag the pin to the exact spot.
          </Text>
        </View>

        <View style={styles.searchWrap}>
          <View
            style={[
              styles.searchField,
              { backgroundColor: colors.surface, borderColor: colors.border },
            ]}
          >
            <Ionicons name="search-outline" size={18} color={colors.textMuted} />
            <TextInput
              value={query}
              onChangeText={(t) => {
                setQuery(t);
                setShowResults(true);
              }}
              onFocus={() => setShowResults(true)}
              placeholder="Search for a place..."
              placeholderTextColor={colors.textMuted}
              style={[styles.searchInput, { color: colors.textPrimary }]}
            />
            {searching ? <ActivityIndicator size="small" color={colors.primary} /> : null}
          </View>

          {showResults && results.length > 0 ? (
            <View
              style={[
                styles.resultsCard,
                { backgroundColor: colors.surface, borderColor: colors.border },
              ]}
            >
              <FlatList
                data={results}
                keyExtractor={(_, i) => String(i)}
                keyboardShouldPersistTaps="handled"
                renderItem={({ item }) => (
                  <Pressable
                    onPress={() => onSelectResult(item)}
                    style={[styles.resultRow, { borderBottomColor: colors.border }]}
                  >
                    <Ionicons name="location-outline" size={16} color={colors.textMuted} />
                    <Text
                      variant="bodyMd"
                      numberOfLines={2}
                      style={{ flex: 1, marginLeft: spacing.xs }}
                    >
                      {item.displayName}
                    </Text>
                  </Pressable>
                )}
              />
            </View>
          ) : null}
        </View>

        <WebView
          ref={webviewRef}
          source={{ html }}
          style={styles.webview}
          onMessage={(event) => {
            try {
              const data = JSON.parse(event.nativeEvent.data);
              if (typeof data.latitude === 'number' && typeof data.longitude === 'number') {
                setPicked(data);
              }
            } catch {
              // Ignore malformed messages -- the page only ever posts
              // one shape, so this would mean a script error, not
              // something the user can act on.
            }
          }}
        />
        <View style={styles.footer}>
          <Button label="Cancel" variant="ghost" onPress={onCancel} style={{ flex: 1, marginRight: spacing.xs }} />
          <Button
            label="Use this location"
            disabled={!picked}
            onPress={() => picked && onConfirm(picked.latitude, picked.longitude)}
            style={{ flex: 1, marginLeft: spacing.xs }}
          />
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  wrap: { flex: 1 },
  header: { padding: spacing.md, paddingBottom: spacing.sm, gap: 2 },
  searchWrap: { paddingHorizontal: spacing.md, paddingBottom: spacing.sm, zIndex: 10 },
  searchField: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderRadius: radius.md,
    paddingHorizontal: spacing.sm,
    height: 44,
    gap: 8,
  },
  searchInput: { flex: 1, fontSize: 15, paddingVertical: 0 },
  resultsCard: {
    marginTop: 4,
    borderWidth: 1,
    borderRadius: radius.md,
    maxHeight: 220,
    overflow: 'hidden',
  },
  resultRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing.sm,
    borderBottomWidth: 1,
  },
  webview: { flex: 1 },
  footer: {
    flexDirection: 'row',
    padding: spacing.md,
    paddingBottom: spacing.xl,
  },
});
