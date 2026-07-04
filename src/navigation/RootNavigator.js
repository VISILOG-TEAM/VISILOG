import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import { useAuth } from '../context/AuthContext';

// Auth screens
import LoginScreen from '../screens/LoginScreen';
import SignupScreen from '../screens/SignupScreen';

// App shell
import TabNavigator from './TabNavigator';

// Detail & modal screens (pushed on top of the tab bar)
import VisitorHomeScreen from '../screens/VisitorHomeScreen';
import EmployeeHomeScreen from '../screens/EmployeeHomeScreen';
import ManagerHomeScreen from '../screens/ManagerHomeScreen';
import NFCLookupScreen from '../screens/NFCLookupScreen';
import RegisterVisitorScreen from '../screens/RegisterVisitorScreen';
import VisitorDetailScreen from '../screens/VisitorDetailScreen';
import EmployeeDetailScreen from '../screens/EmployeeDetailScreen';
import AddEmployeeScreen from '../screens/AddEmployeeScreen';
import LogCallScreen from '../screens/LogCallScreen';
import CallLogScreen from '../screens/CallLogScreen';
import ReportsScreen from '../screens/ReportsScreen';
import SettingsScreen from '../screens/SettingsScreen';
import NFCCardsScreen from '../screens/NFCCardsScreen';
import AttendanceScreen from '../screens/AttendanceScreen';
import RoomBookingsScreen from '../screens/RoomBookingsScreen';
import VisitorBookingScreen from '../screens/VisitorBookingScreen';

const Stack = createNativeStackNavigator();

// Root navigator switches between AuthStack (signed-out) and AppStack
// (signed-in). The choice is driven by the AuthContext's `user` value.
export default function RootNavigator() {
  const { user } = useAuth();

  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {!user ? (
        // ---------- Signed-out stack ----------
        <Stack.Group>
          <Stack.Screen name="Login" component={LoginScreen} />
          <Stack.Screen name="Signup" component={SignupScreen} />
        </Stack.Group>
      ) : (
        // ---------- Signed-in stack ----------
        <Stack.Group>
  {user.role === 'receptionist' && (
    <Stack.Screen name="Tabs" component={TabNavigator} />
  )}
  {user.role === 'visitor' && (
    <Stack.Screen name="VisitorHome" component={VisitorHomeScreen} />
  )}
  {user.role === 'employee' && (
    <Stack.Screen name="EmployeeHome" component={EmployeeHomeScreen} />
  )}
  {user.role === 'manager' && (
    <Stack.Screen name="ManagerHome" component={ManagerHomeScreen} />
  )}

  {/* Modal-style screens (forms) */}
  <Stack.Group screenOptions={{ presentation: 'modal' }}>
    <Stack.Screen name="RegisterVisitor" component={RegisterVisitorScreen} />
    <Stack.Screen name="AddEmployee" component={AddEmployeeScreen} />
    <Stack.Screen name="LogCall" component={LogCallScreen} />
    <Stack.Screen name="VisitorBooking" component={VisitorBookingScreen} />
  </Stack.Group>

  {/* Pushed detail / sub-module screens */}
  <Stack.Screen name="VisitorDetail" component={VisitorDetailScreen} />
  <Stack.Screen name="EmployeeDetail" component={EmployeeDetailScreen} />
  <Stack.Screen name="CallLog" component={CallLogScreen} />
  <Stack.Screen name="Reports" component={ReportsScreen} />
  <Stack.Screen name="Settings" component={SettingsScreen} />
  <Stack.Screen name="NFCCards" component={NFCCardsScreen} />
  <Stack.Screen name="NFCLookup" component={NFCLookupScreen} />
  <Stack.Screen name="Attendance" component={AttendanceScreen} />
  <Stack.Screen name="RoomBookings" component={RoomBookingsScreen} />
</Stack.Group>
      )}
    </Stack.Navigator>
  );
}
