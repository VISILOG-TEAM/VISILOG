# VisiLog — Mobile Frontend

Full React Native (Expo SDK 54) frontend for VisiLog: a visitor management & reception app for the VRA team.

## Quick start

```bash
# Inside C:\Users\HP\VisiLog
npx expo install expo-blur expo-linear-gradient @expo-google-fonts/sora @expo-google-fonts/inter
npx expo start
```

Then open Expo Go on your phone and scan the QR code.

## Demo credentials

Email: `employee@vra.com`
Password: `password1234`

(Tap "Use demo account" on the login screen to auto-fill.)

## What's inside

- Auth flow: Login (teal silk background, glass card, gradient button) + Signup
- Dashboard with 4 stat tiles, pending approvals, quick actions, recent visitor logs
- Visitors: live log with search, status filter, badge IDs, check-out
- Register visitor modal (auto-generated badge, host picker, consent)
- Appointments: pending/admitted/rejected with one-tap admit & reject
- Directory (phone book) with call/email/SMS action pills
- Call log: incoming/outgoing/missed with filters, plus log-call form
- Reports: 24h/7d/30d range, stats, bar chart, top hosts, export buttons
- Settings: profile, password, notifications, branding, sign-out
- NFC 2.0: virtual cards (active/revoked), attendance taps, room bookings
- Visitor pre-registration form

## Tech

- Expo SDK 54
- React Navigation 7 (native-stack + bottom-tabs)
- Context-based state (AuthContext, DataContext)
- expo-blur, expo-linear-gradient
- Sora (display) + Inter (UI) from Google Fonts

## Project layout

```
App.js                       # Entry: fonts + providers + navigation
assets/login-bg.jpg          # Teal silk login background
src/
  components/                # Shared UI primitives (Button, Card, etc.)
  context/                   # AuthContext, DataContext
  data/                      # mockData, formatters
  navigation/                # RootNavigator, TabNavigator
  screens/                   # All 18 screens
  theme/                     # colors, typography, spacing, shadows
```

See `VisiLog_Explanation.docx` (in the parent folder) for a full line-by-line walkthrough.
