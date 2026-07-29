import React, { useState } from 'react';
import { View, Image, StyleSheet, Alert, Pressable, Share } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import * as Location from 'expo-location';
import { Screen, Header, Text, Card, Button, Input } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type { BrandTheme, IoniconName, OfficeLocation } from '../types';

// A raw GPS reading carries about 14 decimal places, which is both
// unreadable and false precision. 5 places is roughly a metre.
function trimCoord(value: string): string {
  const n = parseFloat(value);
  return Number.isNaN(n) ? value : n.toFixed(5);
}

// Resolves to null if `promise` hasn't settled within `ms`. Used to put
// a ceiling on a GPS fix, which has no built-in timeout.
function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T | null> {
  return Promise.race([
    promise,
    new Promise<null>((resolve) => setTimeout(() => resolve(null), ms)),
  ]);
}

interface CompanySetupScreenProps {
  navigation: RootStackNavigation;
}

// A handful of ready-made brand palettes, so a manager can restyle the
// app without needing a full color-picker UI.
const THEME_PRESETS: { id: string; label: string; theme: BrandTheme }[] = [
  {
    id: 'emerald',
    label: 'Emerald & gold',
    theme: {
      brand: '#0F3D2A',
      brandDark: '#0A2A1D',
      brandTint: '#155636',
      primary: '#C9A227',
      primaryPressed: '#D4AF37',
      primarySurface: '#FBF3DE',
      primarySurfaceStrong: '#F5E6BC',
    },
  },
  {
    id: 'navy',
    label: 'Navy & sky',
    theme: {
      brand: '#1B2A4A',
      brandDark: '#101A30',
      brandTint: '#25396B',
      primary: '#4F8EF7',
      primaryPressed: '#3B76DD',
      primarySurface: '#EAF1FE',
      primarySurfaceStrong: '#D3E3FD',
    },
  },
  {
    id: 'wine',
    label: 'Wine & gold',
    theme: {
      brand: '#5C1A1A',
      brandDark: '#3D1010',
      brandTint: '#7A2626',
      primary: '#E0A62B',
      primaryPressed: '#C48F20',
      primarySurface: '#FDF3DF',
      primarySurfaceStrong: '#F8E4B8',
    },
  },
  {
    id: 'plum',
    label: 'Plum & rose',
    theme: {
      brand: '#3B1D4A',
      brandDark: '#28132F',
      brandTint: '#512A66',
      primary: '#E0679F',
      primaryPressed: '#C74F86',
      primarySurface: '#FCEAF3',
      primarySurfaceStrong: '#F7D2E5',
    },
  },
];

// CompanySetupScreen -- Manager/Administrator only, reachable from
// Settings > Organisation > "Company branding". Covers everything the
// self-serve onboarding story needs after registration: sharing the
// company code, branding, and the office location that backs the
// clock-in geofence check. Staff roster (Directory) and meeting rooms
// each have their own dedicated screens, linked from here.
export default function CompanySetupScreen({ navigation }: CompanySetupScreenProps) {
  const { colors } = useTheme();
  const { organization, updateOrganization } = useAuth();
  const { officeLocations, addOfficeLocation, updateOfficeLocation, removeOfficeLocation } =
    useData();

  const [name, setName] = useState(organization?.name || '');
  const [logoUrl, setLogoUrl] = useState(organization?.logoUrl || '');
  const [wifiNetworkName, setWifiNetworkName] = useState(organization?.wifiNetworkName || '');
  const [savingBrand, setSavingBrand] = useState(false);
  const [pickingLogo, setPickingLogo] = useState(false);

  const onPickLogo = async () => {
    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) {
      Alert.alert('Permission needed', 'Allow photo library access to upload a logo.');
      return;
    }
    setPickingLogo(true);
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ['images'],
        allowsEditing: true,
        aspect: [1, 1],
        quality: 0.6,
        base64: true,
      });
      if (result.canceled) return;
      const asset = result.assets[0];
      if (!asset.base64) {
        Alert.alert('Could not read image', 'Please try a different photo.');
        return;
      }
      setLogoUrl(`data:${asset.mimeType || 'image/jpeg'};base64,${asset.base64}`);
    } finally {
      setPickingLogo(false);
    }
  };

  // Office locations -- an org can have more than one (see
  // DataContext.officeLocations); `editingId` is null while adding a
  // new one, or an existing location's id while editing it. The
  // backend allows one free on any plan and 409s with an upgrade
  // message on a second, which onSaveLocation surfaces as-is rather
  // than pre-checking the plan here.
  const [formOpen, setFormOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [locName, setLocName] = useState('');
  const [latitude, setLatitude] = useState('');
  const [longitude, setLongitude] = useState('');
  const [radiusMeters, setRadiusMeters] = useState('500');
  const [savingLocation, setSavingLocation] = useState(false);
  const [locating, setLocating] = useState(false);
  // Set once a GPS attempt has failed -- reveals the manual latitude/
  // longitude fields. They stay hidden until then on purpose: typing
  // coordinates is the fallback, not the way this is meant to be used.
  const [gpsFailed, setGpsFailed] = useState(false);

  const onStartAddLocation = () => {
    setEditingId(null);
    setLocName('');
    setLatitude('');
    setLongitude('');
    setRadiusMeters('500');
    // Each new form starts on the GPS-first path again -- a failure
    // last time doesn't mean this attempt will fail too.
    setGpsFailed(false);
    setFormOpen(true);
  };

  const onStartEditLocation = (loc: OfficeLocation) => {
    setEditingId(loc.id);
    setLocName(loc.name);
    setLatitude(String(loc.latitude));
    setLongitude(String(loc.longitude));
    setRadiusMeters(String(loc.radiusMeters));
    setGpsFailed(false);
    setFormOpen(true);
  };

  // Fills lat/lng from the phone's own GPS instead of making someone
  // look up coordinates manually -- stand at the office and tap this.
  //
  // Every failure path here ends by revealing the manual coordinate
  // fields (setGpsFailed). Without that, a manager whose phone can't
  // get a fix -- indoors, location services off, permission declined --
  // has no way at all to set an office location, and since clock-in is
  // gated on being inside one, that silently breaks attendance for the
  // whole company with nothing on screen explaining why.
  const onUseCurrentLocation = async () => {
    setLocating(true);
    try {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        setGpsFailed(true);
        Alert.alert(
          'Permission needed',
          'Allow location access to use your current position, or enter the coordinates yourself below.',
        );
        return;
      }

      // A fresh GPS fix indoors can take a very long time (or never
      // arrive) on Android, and getCurrentPositionAsync has no timeout
      // of its own -- left alone it spins forever and reads as a
      // broken button. Fall back to the last known fix, and give up
      // after 15 seconds either way.
      const position =
        (await Location.getLastKnownPositionAsync({ maxAge: 5 * 60 * 1000 })) ??
        (await withTimeout(
          Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced }),
          15000,
        ));

      if (!position) {
        setGpsFailed(true);
        Alert.alert(
          'Could not get location',
          'Your phone did not return a position in time. Try again outdoors, or enter the coordinates yourself below.',
        );
        return;
      }

      setLatitude(String(position.coords.latitude));
      setLongitude(String(position.coords.longitude));
      setGpsFailed(false);
    } catch {
      setGpsFailed(true);
      Alert.alert(
        'Could not get location',
        'Enable location services and try again, or enter the coordinates yourself below.',
      );
    } finally {
      setLocating(false);
    }
  };

  const onShareCode = () => {
    Share.share({
      message: `Join ${organization?.name} on VisiLog. Company code: ${organization?.code}`,
    }).catch(() => {});
  };

  const onSaveBrand = async () => {
    if (!name.trim()) {
      Alert.alert('Almost there', 'Give your company a name.');
      return;
    }
    setSavingBrand(true);
    const result = await updateOrganization({
      name: name.trim(),
      logoUrl: logoUrl.trim() || null,
      wifiNetworkName: wifiNetworkName.trim() || null,
    });
    setSavingBrand(false);
    if (!result.ok) Alert.alert('Could not save', result.error);
  };

  const onPickPreset = async (preset: (typeof THEME_PRESETS)[number]) => {
    setSavingBrand(true);
    const result = await updateOrganization({ theme: preset.theme });
    setSavingBrand(false);
    if (!result.ok) Alert.alert('Could not save', result.error);
  };

  const onSaveLocation = async () => {
    if (!locName.trim()) {
      Alert.alert('Almost there', 'Give this location a name (e.g. "Head Office").');
      return;
    }
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const radius = parseInt(radiusMeters, 10) || 500;
    if (Number.isNaN(lat) || Number.isNaN(lng)) {
      Alert.alert(
        'Almost there',
        'Tap "Use my current location" while standing at that office first.',
      );
      return;
    }
    setSavingLocation(true);
    try {
      const input = { name: locName.trim(), latitude: lat, longitude: lng, radiusMeters: radius };
      if (editingId) {
        await updateOfficeLocation(editingId, input);
      } else {
        await addOfficeLocation(input);
      }
      setFormOpen(false);
      Alert.alert('Saved', 'Staff will need to be within range of this location to clock in.');
    } catch (err) {
      Alert.alert(
        'Could not save',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
    } finally {
      setSavingLocation(false);
    }
  };

  const onRemoveLocation = (loc: OfficeLocation) => {
    Alert.alert(
      'Remove this location?',
      `Staff will no longer be able to clock in at ${loc.name}.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: () =>
            removeOfficeLocation(loc.id).catch((err) =>
              Alert.alert(
                'Could not remove location',
                err instanceof ApiError ? err.message : 'Something went wrong.',
              ),
            ),
        },
      ],
    );
  };

  return (
    <Screen>
      <Header
        title="Company Setup"
        subtitle="Branding, office location, staff & rooms"
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      {/* Company code */}
      <Card accent="info">
        <Text variant="caption" color={colors.textSecondary}>
          Company code
        </Text>
        <View style={styles.codeRow}>
          <Text style={[styles.code, { color: colors.brand }]}>{organization?.code}</Text>
          <Pressable
            onPress={onShareCode}
            style={[styles.shareBtn, { backgroundColor: colors.primarySurface }]}
          >
            <Ionicons name="share-outline" size={16} color={colors.primary} />
            <Text variant="caption" color={colors.brand} style={{ marginLeft: 4 }}>
              Share
            </Text>
          </Pressable>
        </View>
        <Text variant="caption" color={colors.textMuted}>
          Give this to your staff and post it wherever you invite visitors -- they enter it when
          they sign up.
        </Text>
      </Card>

      {/* Branding */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Branding
      </Text>
      <Card>
        <Input label="Company name" value={name} onChangeText={setName} icon="business-outline" />

        <Text variant="label" color={colors.textSecondary} style={styles.logoLabel}>
          Logo
        </Text>
        <Pressable onPress={onPickLogo} disabled={pickingLogo} style={styles.logoRow}>
          <View
            style={[
              styles.logoPreview,
              { borderColor: colors.border, backgroundColor: colors.surfaceAlt },
            ]}
          >
            {logoUrl ? (
              <Image source={{ uri: logoUrl }} style={styles.logoImage} resizeMode="cover" />
            ) : (
              <Ionicons name="image-outline" size={22} color={colors.textMuted} />
            )}
          </View>
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="bodySemibold" color={colors.brand}>
              {pickingLogo ? 'Opening photos...' : logoUrl ? 'Change logo' : 'Upload a logo'}
            </Text>
            <Text variant="caption" color={colors.textMuted}>
              From your device's photo library
            </Text>
          </View>
        </Pressable>

        <Input
          label="...or paste a logo URL"
          value={logoUrl}
          onChangeText={setLogoUrl}
          placeholder="https://..."
          icon="link-outline"
          autoCapitalize="none"
        />
        <Input
          label="WiFi network name"
          value={wifiNetworkName}
          onChangeText={setWifiNetworkName}
          placeholder="e.g. Office-WiFi"
          icon="wifi-outline"
        />
        <Text
          variant="caption"
          color={colors.textMuted}
          style={{ marginTop: -6, marginBottom: spacing.sm }}
        >
          Shown to staff as a reminder of which network to join before clocking in.
        </Text>
        <Button
          label={savingBrand ? 'Saving...' : 'Save'}
          onPress={onSaveBrand}
          disabled={savingBrand}
        />
      </Card>

      <Card style={{ marginTop: spacing.sm }}>
        <Text variant="bodySemibold" style={{ marginBottom: spacing.sm }}>
          Color theme
        </Text>
        <View style={styles.presetGrid}>
          {THEME_PRESETS.map((p) => (
            <Pressable key={p.id} onPress={() => onPickPreset(p)} style={styles.presetItem}>
              <View style={styles.presetSwatches}>
                <View style={[styles.swatch, { backgroundColor: p.theme.brand }]} />
                <View style={[styles.swatch, { backgroundColor: p.theme.primary }]} />
              </View>
              <Text variant="caption" color={colors.textSecondary}>
                {p.label}
              </Text>
            </Pressable>
          ))}
        </View>
      </Card>

      {/* Office locations -- the first is free on any plan; a second+
          requires the enterprise plan (see onSaveLocation, which just
          surfaces the backend's upgrade message if it's rejected). */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Office locations
      </Text>
      <Card padded={false}>
        {officeLocations.length === 0 ? (
          <View style={{ padding: spacing.md }}>
            <Text variant="caption" color={colors.textSecondary}>
              No locations set yet. Staff can clock in from anywhere until you add one.
            </Text>
          </View>
        ) : (
          officeLocations.map((loc, i) => (
            <View key={loc.id}>
              <View style={styles.linkRow}>
                <View style={[styles.linkIcon, { backgroundColor: colors.surfaceAlt }]}>
                  <Ionicons name="location-outline" size={18} color={colors.brand} />
                </View>
                <View style={{ flex: 1 }}>
                  <Text variant="bodySemibold">{loc.name}</Text>
                  <Text variant="caption" color={colors.textSecondary}>
                    {loc.radiusMeters}m radius
                  </Text>
                </View>
                <Pressable onPress={() => onStartEditLocation(loc)} style={{ padding: 6 }}>
                  <Ionicons name="create-outline" size={20} color={colors.textMuted} />
                </Pressable>
                <Pressable onPress={() => onRemoveLocation(loc)} style={{ padding: 6 }}>
                  <Ionicons name="trash-outline" size={20} color={colors.status.rejected.solid} />
                </Pressable>
              </View>
              {i < officeLocations.length - 1 && (
                <View style={[styles.divider, { backgroundColor: colors.border }]} />
              )}
            </View>
          ))
        )}
      </Card>

      {!formOpen && (
        <Button
          label="Add office location"
          icon="add-circle-outline"
          variant="secondary"
          onPress={onStartAddLocation}
          style={{ marginTop: spacing.sm }}
        />
      )}

      {formOpen && (
        <Card style={{ marginTop: spacing.sm }}>
          <Text variant="bodySemibold" style={{ marginBottom: spacing.sm }}>
            {editingId ? 'Edit location' : 'New location'}
          </Text>
          <Input
            label="Name"
            value={locName}
            onChangeText={setLocName}
            placeholder="e.g. Head Office"
            icon="business-outline"
          />
          <Button
            label={locating ? 'Getting your location...' : 'Use my current location'}
            icon="locate"
            variant="secondary"
            onPress={onUseCurrentLocation}
            disabled={locating}
            style={{ marginBottom: spacing.md }}
          />
          <View style={[styles.locationStatus, { backgroundColor: colors.surfaceAlt }]}>
            <Ionicons
              name={
                latitude.trim() && longitude.trim() ? 'checkmark-circle' : 'alert-circle-outline'
              }
              size={18}
              color={latitude.trim() && longitude.trim() ? colors.primary : colors.textMuted}
            />
            {/* Shows the actual coordinates once set, not just "Location
                set". A bare confirmation is useless for the one thing an
                admin needs to check -- whether the pin landed on their
                office or on wherever the phone happened to think it was.
                Trimmed to 5 decimal places, roughly a metre. */}
            <Text variant="bodyMd" color={colors.textSecondary} style={{ marginLeft: 8, flex: 1 }}>
              {latitude.trim() && longitude.trim()
                ? `Location set: ${trimCoord(latitude)}, ${trimCoord(longitude)}`
                : 'No location set yet'}
            </Text>
          </View>

          {/* Only appears once GPS has actually failed -- see gpsFailed.
              These fields were deliberately removed as the primary way
              to set a location (nobody should have to type coordinates
              normally), but with no fallback at all a phone that can't
              get a fix leaves the whole company unable to clock in. */}
          {gpsFailed ? (
            <View style={{ marginTop: spacing.sm }}>
              <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: 6 }}>
                Or enter the coordinates yourself: open Google Maps, press and hold on your
                office, and copy the two numbers it shows.
              </Text>
              <Input
                label="Latitude"
                value={latitude}
                onChangeText={setLatitude}
                placeholder="e.g. 5.6037"
                icon="navigate-outline"
                keyboardType="numbers-and-punctuation"
              />
              <Input
                label="Longitude"
                value={longitude}
                onChangeText={setLongitude}
                placeholder="e.g. -0.1870"
                icon="navigate-outline"
                keyboardType="numbers-and-punctuation"
              />
            </View>
          ) : null}

          <Input
            label="Radius (meters)"
            value={radiusMeters}
            onChangeText={setRadiusMeters}
            placeholder="e.g. 500"
            icon="radio-outline"
            keyboardType="number-pad"
          />
          <View style={{ flexDirection: 'row' }}>
            <Button
              label="Cancel"
              variant="ghost"
              onPress={() => setFormOpen(false)}
              style={{ flex: 1, marginRight: spacing.xs }}
            />
            <Button
              label={savingLocation ? 'Saving...' : 'Save'}
              onPress={onSaveLocation}
              disabled={savingLocation}
              style={{ flex: 1, marginLeft: spacing.xs }}
            />
          </View>
        </Card>
      )}

      {/* Staff & rooms */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Staff & rooms
      </Text>
      <Card padded={false}>
        <LinkRow
          icon="people-outline"
          title="Staff roster"
          sub="Add employees & set their roles"
          onPress={() => navigation.navigate('Directory')}
        />
        <View style={[styles.divider, { backgroundColor: colors.border }]} />
        <LinkRow
          icon="business-outline"
          title="Meeting rooms"
          sub="Add or remove bookable rooms"
          onPress={() => navigation.navigate('MeetingRooms')}
        />
        <View style={[styles.divider, { backgroundColor: colors.border }]} />
        <LinkRow
          icon="document-text-outline"
          title="Legal agreement"
          sub="The subscription terms your company agreed to"
          onPress={() => navigation.navigate('LegalAgreement')}
        />
      </Card>
    </Screen>
  );
}

function LinkRow({
  icon,
  title,
  sub,
  onPress,
}: {
  icon: IoniconName;
  title: string;
  sub: string;
  onPress: () => void;
}) {
  const { colors } = useTheme();
  return (
    <Pressable style={styles.linkRow} onPress={onPress}>
      <View style={[styles.linkIcon, { backgroundColor: colors.surfaceAlt }]}>
        <Ionicons name={icon} size={18} color={colors.brand} />
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="bodySemibold">{title}</Text>
        <Text variant="caption" color={colors.textSecondary}>
          {sub}
        </Text>
      </View>
      <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  logoLabel: { marginBottom: 6 },
  logoRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.md },
  logoPreview: {
    width: 56,
    height: 56,
    borderRadius: radius.md,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  logoImage: { width: '100%', height: '100%' },
  codeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginVertical: 4,
  },
  // fontFamily, never fontWeight: Android can't synthesize a bold face
  // for a loaded custom font -- a bare fontWeight here silently swaps
  // the whole run of text to the system font instead.
  code: { fontSize: 22, fontFamily: fonts.displayBold, letterSpacing: 1 },
  shareBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.sm,
    paddingVertical: 6,
    borderRadius: radius.pill,
  },
  presetGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.md },
  presetItem: { alignItems: 'center', width: 70 },
  presetSwatches: { flexDirection: 'row', marginBottom: 4 },
  swatch: {
    width: 22,
    height: 22,
    borderRadius: 11,
    marginHorizontal: -4,
    borderWidth: 2,
    borderColor: '#fff',
  },
  linkRow: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  linkIcon: {
    width: 32,
    height: 32,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, marginLeft: spacing.md + 32 + spacing.sm },
  locationStatus: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: radius.md,
    padding: spacing.sm,
    marginBottom: spacing.sm,
  },
});
