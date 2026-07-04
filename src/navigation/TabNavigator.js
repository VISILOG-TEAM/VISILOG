import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';

import DashboardScreen from '../screens/DashboardScreen';
import VisitorsScreen from '../screens/VisitorsScreen';
import AppointmentsScreen from '../screens/AppointmentsScreen';
import DirectoryScreen from '../screens/DirectoryScreen';
import MoreScreen from '../screens/MoreScreen';

import { colors } from '../theme/colors';
import { fonts } from '../theme/typography';

const Tab = createBottomTabNavigator();

// Five-tab bottom bar:
//   Dashboard | Visitors | Appointments | Directory | More
// The four standalone modules (Call Log, Reports, NFC, etc.) live
// behind the More tab so the bar never crowds.
export default function TabNavigator() {
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
          height: 64,
          paddingBottom: 8,
          paddingTop: 6,
        },
        tabBarLabelStyle: {
          fontFamily: fonts.medium,
          fontSize: 11,
        },
        tabBarIcon: ({ color, focused }) => {
          const icons = {
            Dashboard: focused ? 'home' : 'home-outline',
            Visitors: focused ? 'people' : 'people-outline',
            Appointments: focused ? 'calendar' : 'calendar-outline',
            Directory: focused ? 'book' : 'book-outline',
            More: focused ? 'ellipsis-horizontal-circle' : 'ellipsis-horizontal-circle-outline',
          };
          return <Ionicons name={icons[route.name]} size={22} color={color} />;
        },
      })}
    >
      <Tab.Screen name="Dashboard" component={DashboardScreen} />
      <Tab.Screen name="Visitors" component={VisitorsScreen} />
      <Tab.Screen name="Appointments" component={AppointmentsScreen} />
      <Tab.Screen name="Directory" component={DirectoryScreen} />
      <Tab.Screen name="More" component={MoreScreen} />
    </Tab.Navigator>
  );
}
