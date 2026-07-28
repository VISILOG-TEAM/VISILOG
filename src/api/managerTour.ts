import AsyncStorage from '@react-native-async-storage/async-storage';

// Whether this Administrator has already been walked through the app.
// Stored per user id, not as one global flag: two managers sharing a
// tablet (or one signing in after the other on the same phone) should
// each get the tour once, and the first one through shouldn't silently
// skip it for the second.
const key = (userId: string): string => `visilog.hasSeenManagerTour.${userId}`;

export const hasSeenManagerTour = async (userId: string): Promise<boolean> => {
  try {
    return (await AsyncStorage.getItem(key(userId))) === 'true';
  } catch {
    // Storage unavailable -- assume it's been seen rather than
    // reopening the tour on every single app launch.
    return true;
  }
};

export const markManagerTourSeen = async (userId: string): Promise<void> => {
  try {
    await AsyncStorage.setItem(key(userId), 'true');
  } catch {
    // Not worth surfacing: the worst case is the tour appearing again.
  }
};
