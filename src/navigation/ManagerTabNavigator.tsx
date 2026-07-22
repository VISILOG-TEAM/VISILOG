import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import ManagerHomeScreen from '../screens/ManagerHomeScreen';
import EmployeeBookScreen from '../screens/EmployeeBookScreen';
import ManagerClockInsScreen from '../screens/ManagerClockInsScreen';
import AppointmentsScreen from '../screens/AppointmentsScreen';
import SettingsScreen from '../screens/SettingsScreen';

import { useTheme } from '../theme/ThemeContext';
import { fonts } from '../theme/typography';
import type { IoniconName } from '../types';

const Tab = createBottomTabNavigator();

// Five-tab bottom bar for Manager/Administrator: Home | Book | Clock
// ins | Appointment logs | Settings.
export default function ManagerTabNavigator() {
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
        tabBarLabelStyle: { fontFamily: fonts.medium, fontSize: 11 },
        tabBarIcon: ({ color, focused }) => {
          const icons: Record<string, IoniconName> = {
            Home: focused ? 'home' : 'home-outline',
            Book: focused ? 'calendar' : 'calendar-outline',
            'Clock ins': focused ? 'time' : 'time-outline',
            Logs: focused ? 'document-text' : 'document-text-outline',
            Settings: focused ? 'settings' : 'settings-outline',
          };
          return <Ionicons name={icons[route.name]} size={22} color={color} />;
        },
      })}
    >
      <Tab.Screen name="Home" component={ManagerHomeScreen} />
      <Tab.Screen name="Book" component={EmployeeBookScreen} />
      <Tab.Screen name="Clock ins" component={ManagerClockInsScreen} />
      <Tab.Screen name="Logs" component={AppointmentsScreen} options={{ tabBarLabel: 'Logs' }} />
      <Tab.Screen name="Settings" component={SettingsScreen} />
    </Tab.Navigator>
  );
}