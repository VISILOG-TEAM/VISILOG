import React, { useState } from 'react';
import { View, Image, StyleSheet, Alert, Pressable, Share } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import * as Location from 'expo-location';
import {
  Screen, Header, Text, Card, Button, Input,
} from '../components';
import { colors } from '../theme/colors';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useAuth } from '../context/AuthContext';
import type { RootStackNavigation } from '../types/navigation';
import type { BrandTheme, IoniconName } from '../types';

interface CompanySetupScreenProps {
  navigation: RootStackNavigation;
}

// A handful of ready-made brand palettes, so a manager can restyle the
// app without needing a full color-picker UI.
const THEME_PRESETS: { id: string; label: string; theme: BrandTheme }[] = [
  { id: 'emerald', label: 'Emerald & gold', theme: {
    brand: '#0F3D2A', brandDark: '#0A2A1D', brandTint: '#155636',
    primary: '#C9A227', primaryPressed: '#D4AF37', primarySurface: '#FBF3DE', primarySurfaceStrong: '#F5E6BC',
  } },
  { id: 'navy', label: 'Navy & sky', theme: {
    brand: '#1B2A4A', brandDark: '#101A30', brandTint: '#25396B',
    primary: '#4F8EF7', primaryPressed: '#3B76DD', primarySurface: '#EAF1FE', primarySurfaceStrong: '#D3E3FD',
  } },
  { id: 'wine', label: 'Wine & gold', theme: {
    brand: '#5C1A1A', brandDark: '#3D1010', brandTint: '#7A2626',
    primary: '#E0A62B', primaryPressed: '#C48F20', primarySurface: '#FDF3DF', primarySurfaceStrong: '#F8E4B8',
  } },
  { id: 'plum', label: 'Plum & rose', theme: {
    brand: '#3B1D4A', brandDark: '#28132F', brandTint: '#512A66',
    primary: '#E0679F', primaryPressed: '#C74F86', primarySurface: '#FCEAF3', primarySurfaceStrong: '#F7D2E5',
  } },
];

// CompanySetupScreen — Manager/Administrator only, reachable from
// Settings > Organisation > "Company branding". Covers everything the
// self-serve onboarding story needs after registration: sharing the
// company code, branding, and the office location that backs the
// clock-in geofence check. Staff roster (Directory) and meeting rooms
// each have their own dedicated screens, linked from here.
export default function CompanySetupScreen({ navigation }: CompanySetupScreenProps) {
  const { colors: themeColors } = useTheme();
  const { organization, updateOrganization, updateOfficeLocation } = useAuth();

  const [name, setName] = useState(organization?.name || '');
  const [logoUrl, setLogoUrl] = useState(organization?.logoUrl || '');
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

  const [latitude, setLatitude] = useState(String(organization?.officeLocation?.latitude ?? ''));
  const [longitude, setLongitude] = useState(String(organization?.officeLocation?.longitude ?? ''));
  const [radiusMeters, setRadiusMeters] = useState(String(organization?.officeLocation?.radiusMeters ?? '500'));
  const [savingLocation, setSavingLocation] = useState(false);
  const [locating, setLocating] = useState(false);

  // Fills lat/lng from the phone's own GPS instead of making someone
  // look up coordinates manually — stand at the office and tap this.
  const onUseCurrentLocation = async () => {
    setLocating(true);
    try {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission needed', 'Allow location access to use your current position.');
        return;
      }
      const position = await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced });
      setLatitude(String(position.coords.latitude));
      setLongitude(String(position.coords.longitude));
    } catch {
      Alert.alert('Could not get location', 'Enable location services and try again.');
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
    const result = await updateOrganization({ name: name.trim(), logoUrl: logoUrl.trim() || null });
    setSavingBrand(false);
    if (!result.ok) Alert.alert('Could not save', result.error);
  };

  const onPickPreset = async (preset: typeof THEME_PRESETS[number]) => {
    setSavingBrand(true);
    const result = await updateOrganization({ theme: preset.theme });
    setSavingBrand(false);
    if (!result.ok) Alert.alert('Could not save', result.error);
  };

  const onSaveLocation = async () => {
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const radius = parseInt(radiusMeters, 10);
    if (Number.isNaN(lat) || Number.isNaN(lng) || Number.isNaN(radius)) {
      Alert.alert('Almost there', 'Latitude, longitude and radius must all be numbers.');
      return;
    }
    setSavingLocation(true);
    const result = await updateOfficeLocation(lat, lng, radius);
    setSavingLocation(false);
    if (!result.ok) Alert.alert('Could not save', result.error);
    else Alert.alert('Saved', 'Staff will need to be within range of this location to clock in.');
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
        <Text variant="caption" color={colors.textSecondary}>Company code</Text>
        <View style={styles.codeRow}>
          <Text style={[styles.code, { color: themeColors.brand }]}>{organization?.code}</Text>
          <Pressable onPress={onShareCode} style={[styles.shareBtn, { backgroundColor: themeColors.primarySurface }]}>
            <Ionicons name="share-outline" size={16} color={themeColors.primary} />
            <Text variant="caption" color={themeColors.brand} style={{ marginLeft: 4 }}>Share</Text>
          </Pressable>
        </View>
        <Text variant="caption" color={colors.textMuted}>
          Give this to your staff and post it wherever you invite visitors — they enter it when they sign up.
        </Text>
      </Card>

      {/* Branding */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>Branding</Text>
      <Card>
        <Input label="Company name" value={name} onChangeText={setName} icon="business-outline" />

        <Text variant="label" color={colors.textSecondary} style={styles.logoLabel}>Logo</Text>
        <Pressable onPress={onPickLogo} disabled={pickingLogo} style={styles.logoRow}>
          <View style={[styles.logoPreview, { borderColor: colors.border }]}>
            {logoUrl ? (
              <Image source={{ uri: logoUrl }} style={styles.logoImage} resizeMode="cover" />
            ) : (
              <Ionicons name="image-outline" size={22} color={colors.textMuted} />
            )}
          </View>
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="bodySemibold" color={themeColors.brand}>
              {pickingLogo ? 'Opening photos…' : logoUrl ? 'Change logo' : 'Upload a logo'}
            </Text>
            <Text variant="caption" color={colors.textMuted}>From your device's photo library</Text>
          </View>
        </Pressable>

        <Input label="…or paste a logo URL" value={logoUrl} onChangeText={setLogoUrl}
          placeholder="https://…" icon="link-outline" autoCapitalize="none" />
        <Button label={savingBrand ? 'Saving…' : 'Save'} onPress={onSaveBrand} disabled={savingBrand} />
      </Card>

      <Card style={{ marginTop: spacing.sm }}>
        <Text variant="bodySemibold" style={{ marginBottom: spacing.sm }}>Color theme</Text>
        <View style={styles.presetGrid}>
          {THEME_PRESETS.map((p) => (
            <Pressable key={p.id} onPress={() => onPickPreset(p)} style={styles.presetItem}>
              <View style={styles.presetSwatches}>
                <View style={[styles.swatch, { backgroundColor: p.theme.brand }]} />
                <View style={[styles.swatch, { backgroundColor: p.theme.primary }]} />
              </View>
              <Text variant="caption" color={colors.textSecondary}>{p.label}</Text>
            </Pressable>
          ))}
        </View>
      </Card>

      {/* Office location */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Office location
      </Text>
      <Card>
        <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.sm }}>
          Staff must be within this radius to clock in. Leave blank to skip the location check.
        </Text>
        <Button
          label={locating ? 'Getting your location…' : 'Use my current location'}
          icon="locate"
          variant="secondary"
          onPress={onUseCurrentLocation}
          disabled={locating}
          style={{ marginBottom: spacing.md }}
        />
        <Input label="Latitude" value={latitude} onChangeText={setLatitude}
          placeholder="e.g. 5.6037" icon="locate-outline" keyboardType="numbers-and-punctuation" />
        <Input label="Longitude" value={longitude} onChangeText={setLongitude}
          placeholder="e.g. -0.1870" icon="locate-outline" keyboardType="numbers-and-punctuation" />
        <Input label="Radius (meters)" value={radiusMeters} onChangeText={setRadiusMeters}
          placeholder="e.g. 500" icon="radio-outline" keyboardType="number-pad" />
        <Button label={savingLocation ? 'Saving…' : 'Save location'} onPress={onSaveLocation} disabled={savingLocation} />
      </Card>

      {/* Staff & rooms */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Staff & rooms
      </Text>
      <Card padded={false}>
        <LinkRow icon="people-outline" title="Staff roster" sub="Add employees & set their roles"
          onPress={() => navigation.navigate('Directory')} />
        <View style={styles.divider} />
        <LinkRow icon="business-outline" title="Meeting rooms" sub="Add or remove bookable rooms"
          onPress={() => navigation.navigate('MeetingRooms')} />
        <View style={styles.divider} />
        <LinkRow icon="document-text-outline" title="Legal agreement" sub="The subscription terms your company agreed to"
          onPress={() => navigation.navigate('LegalAgreement')} />
      </Card>
    </Screen>
  );
}

function LinkRow({
  icon, title, sub, onPress,
}: { icon: IoniconName; title: string; sub: string; onPress: () => void }) {
  const { colors: themeColors } = useTheme();
  return (
    <Pressable style={styles.linkRow} onPress={onPress}>
      <View style={styles.linkIcon}>
        <Ionicons name={icon} size={18} color={themeColors.brand} />
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="bodySemibold">{title}</Text>
        <Text variant="caption" color={colors.textSecondary}>{sub}</Text>
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
    width: 56, height: 56, borderRadius: radius.md,
    borderWidth: 1, alignItems: 'center', justifyContent: 'center',
    overflow: 'hidden', backgroundColor: colors.surfaceAlt,
  },
  logoImage: { width: '100%', height: '100%' },
  codeRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginVertical: 4 },
  code: { fontSize: 22, fontWeight: '700', letterSpacing: 1 },
  shareBtn: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: spacing.sm, paddingVertical: 6, borderRadius: radius.pill },
  presetGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.md },
  presetItem: { alignItems: 'center', width: 70 },
  presetSwatches: { flexDirection: 'row', marginBottom: 4 },
  swatch: { width: 22, height: 22, borderRadius: 11, marginHorizontal: -4, borderWidth: 2, borderColor: '#fff' },
  linkRow: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  linkIcon: {
    width: 32, height: 32, borderRadius: 10,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center', justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, backgroundColor: colors.border, marginLeft: spacing.md + 32 + spacing.sm },
});
