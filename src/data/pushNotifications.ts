import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';
import Constants from 'expo-constants';
import { Platform } from 'react-native';

// Local (in-app-foreground) notifications still show a banner/sound even
// though remote push (see registerForPushNotificationsAsync) mostly
// isn't reachable through Expo Go -- without a handler, a notification
// that fires while the app is open is suppressed instead of shown.
Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

async function ensurePermissionGranted(): Promise<boolean> {
  if (!Device.isDevice) {
    return false;
  }
  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync('default', {
      name: 'default',
      importance: Notifications.AndroidImportance.DEFAULT,
    });
  }
  const existing = await Notifications.getPermissionsAsync();
  let status = existing.status;
  if (status !== 'granted') {
    const requested = await Notifications.requestPermissionsAsync();
    status = requested.status;
  }
  return status === 'granted';
}

// Requests permission and returns an Expo push token for this device, or
// null if permission was denied, this isn't a physical device (simulators
// have no push capability), or no EAS project id is configured yet (see
// app.json -- run `eas init` once to add one; until then this fails
// quietly instead of throwing).
//
// Also returns null on Android through Expo Go specifically: Expo Go has
// not supported remote push on Android since SDK 53
// (https://expo.dev/changelog/sdk-53), regardless of permissions or
// project id. A development build (`eas build --profile development`)
// is required to actually receive a remote push on Android -- see
// syncLocalReminders for a reminder mechanism that works in Expo Go too.
export async function registerForPushNotificationsAsync(): Promise<string | null> {
  const granted = await ensurePermissionGranted();
  if (!granted) {
    return null;
  }

  const projectId: string | undefined =
    Constants.expoConfig?.extra?.eas?.projectId ?? Constants.easConfig?.projectId;
  if (!projectId) {
    return null;
  }

  try {
    const { data } = await Notifications.getExpoPushTokenAsync({ projectId });
    return data;
  } catch {
    return null;
  }
}

const REMINDER_PREFIX = 'visilog-reminder-';

export interface ReminderItem {
  id: string;
  title: string;
  body: string;
  /** ISO instant of the thing being reminded about -- the notification fires 30 minutes before this. */
  whenISO: string;
}

// Schedules a local, on-device notification 30 minutes before each item
// in `items`, and cancels any previously-scheduled reminder that isn't
// in the list anymore (rescheduled, rejected/declined, or already past)
// or whose time changed. Meant to be called with the signed-in user's
// current set of upcoming appointments/meetings every time that list
// refreshes -- re-running it is what keeps reminders in sync with
// reschedules, not any explicit cancel-on-reschedule hook.
//
// Unlike registerForPushNotificationsAsync, this needs no Expo push
// token, no backend job, and no EAS project id, and works in Expo Go on
// both platforms -- this is what actually fires a "30 minutes before"
// reminder for anyone testing through Expo Go rather than a dev build.
export async function syncLocalReminders(items: ReminderItem[]): Promise<void> {
  if (Platform.OS === 'web') {
    return; // expo-notifications scheduling isn't meaningful in a browser tab
  }
  const granted = await ensurePermissionGranted();
  if (!granted) {
    return;
  }

  const desired = new Map(items.map((i) => [REMINDER_PREFIX + i.id, i]));

  const scheduled = await Notifications.getAllScheduledNotificationsAsync();
  for (const s of scheduled) {
    if (s.identifier.startsWith(REMINDER_PREFIX) && !desired.has(s.identifier)) {
      await Notifications.cancelScheduledNotificationAsync(s.identifier).catch(() => {});
    }
  }

  const now = Date.now();
  for (const [identifier, item] of desired) {
    const triggerAt = new Date(item.whenISO).getTime() - 30 * 60 * 1000;
    // Always cancel first: scheduling again with the same identifier
    // isn't guaranteed to replace an existing trigger time on every
    // platform, and re-running this on every refresh is exactly the
    // "the time changed" case a reschedule hits.
    await Notifications.cancelScheduledNotificationAsync(identifier).catch(() => {});
    if (triggerAt <= now) {
      continue;
    }
    await Notifications.scheduleNotificationAsync({
      identifier,
      content: { title: item.title, body: item.body, sound: 'default' },
      trigger: { type: Notifications.SchedulableTriggerInputTypes.DATE, date: new Date(triggerAt) },
    }).catch(() => {});
  }
}
