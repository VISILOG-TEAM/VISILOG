import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import DashboardScreen from '../screens/DashboardScreen';
import VisitorBookingScreen from '../screens/VisitorBookingScreen';
import AppointmentsScreen from '../screens/AppointmentsScreen';
import SettingsScreen from '../screens/SettingsScreen';

import { useTheme } from '../theme/ThemeContext';
import { fonts } from '../theme/typography';
import type { IoniconName } from '../types';

const Tab = createBottomTabNavigator();

// Four-tab bottom bar for Receptionist: Home | Book | Appointments |
// Settings. Visitors & Directory moved to Dashboard's Quick Actions
// (pushed screens on the root stack) so the bar stays to 4 tabs.
export default function TabNavigator() {
  const { colors } = useTheme();
  // A fixed height/padding left the bar sitting under phones' on-screen
  // gesture/button bar -- insets.bottom is 0 on devices without one, so
  // this only adds space where it's actually needed.
  const insets = useSafeAreaInsets();
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        headerShown: false,
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.textMuted,
        tabBarStyle: {
          backgroundColor: colors.surface,
          borderTopColor: colors.border,
          borderTopWidth: 1,
          height: 56 + insets.bottom,
          paddingBottom: Math.max(insets.bottom, 8),
          paddingTop: 6,
        },
        tabBarLabelStyle: {
          fontFamily: fonts.medium,
          fontSize: 11,
        },
        tabBarIcon: ({ color, focused }) => {
          const icons: Record<string, IoniconName> = {
            Home: focused ? 'home' : 'home-outline',
            Book: focused ? 'calendar' : 'calendar-outline',
            Appointments: focused ? 'checkmark-done' : 'checkmark-done-outline',
            Settings: focused ? 'settings' : 'settings-outline',
          };
          return <Ionicons name={icons[route.name]} size={22} color={color} />;
        },
      })}
    >
      <Tab.Screen name="Home" component={DashboardScreen} />
      <Tab.Screen name="Book" component={VisitorBookingScreen} />
      <Tab.Screen name="Appointments" component={AppointmentsScreen} />
      <Tab.Screen name="Settings" component={SettingsScreen} />
    </Tab.Navigator>
  );
}