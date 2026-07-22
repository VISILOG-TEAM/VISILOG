// The OAuth Web Client ID from Google Cloud Console (APIs & Services >
// Credentials). Set via EXPO_PUBLIC_GOOGLE_CLIENT_ID -- same
// override pattern as API_BASE_URL in config.ts. A "Web application"
// client type works across platforms with expo-auth-session's
// browser-based flow, so there's no separate Android/iOS client to
// manage.
export const GOOGLE_CLIENT_ID = process.env.EXPO_PUBLIC_GOOGLE_CLIENT_ID || '';