// Where the VisiLog API lives. Override with EXPO_PUBLIC_API_URL (an
// .env value, or set at build time) — e.g. your machine's LAN IP when
// testing on a physical device/Expo Go, since "localhost" from a phone
// means the phone itself, not your dev machine. Defaults to the normal
// local backend port for web/simulator testing.
export const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:8080';
