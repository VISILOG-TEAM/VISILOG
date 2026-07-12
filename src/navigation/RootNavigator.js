import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import { useAuth } from '../context/AuthContext';

// Auth / onboarding screens
import LoginScreen from '../screens/LoginScreen';
import SignupScreen from '../screens/SignupScreen';
import RoleSelectScreen from '../screens/RoleSelectScreen';
import EmployeeIdVerifyScreen from '../screens/EmployeeIdVerifyScreen';

// Per-role app shells (each is its own bottom-tab navigator)
import TabNavigator from './TabNavigator';
import VisitorTabNavigator from './VisitorTabNavigator';
import EmployeeTabNavigator from './EmployeeTabNavigator';
import ManagerTabNavigator from './ManagerTabNavigator';

// Detail & modal screens (pushed on top of the tab bar)
import VisitorsScreen from '../screens/VisitorsScreen';
import DirectoryScreen from '../screens/DirectoryScreen';
import NFCLookupScreen from '../screens/NFCLookupScreen';
import RegisterVisitorScreen from '../screens/RegisterVisitorScreen';
import VisitorDetailScreen from '../screens/VisitorDetailScreen';
import EmployeeDetailScreen from '../screens/EmployeeDetailScreen';
import AddEmployeeScreen from '../screens/AddEmployeeScreen';
import LogCallScreen from '../screens/LogCallScreen';
import CallLogScreen from '../screens/CallLogScreen';
import ReportsScreen from '../screens/ReportsScreen';
import NFCCardsScreen from '../screens/NFCCardsScreen';
import AttendanceScreen from '../screens/AttendanceScreen';
import BillingScreen from '../screens/BillingScreen';

const Stack = createNativeStackNavigator();

// Root navigator. Signed-out users see Login/Signup. Signed-in users
// pass through two one-time gates — the role picker, then (for
// Receptionist only) an employee-ID check — before landing on their
// role's tab shell.
export default function RootNavigator() {
  const { user, hasChosenRole, receptionistVerified } = useAuth();

  const needsRoleSelect = user && !hasChosenRole;
  const needsIdVerify = user && hasChosenRole && user.role === 'receptionist' && !receptionistVerified;

  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {!user ? (
        // ---------- Signed-out stack ----------
        <Stack.Group>
          <Stack.Screen name="Login" component={LoginScreen} />
          <Stack.Screen name="Signup" component={SignupScreen} />
        </Stack.Group>
      ) : needsRoleSelect ? (
        <Stack.Screen name="RoleSelect" component={RoleSelectScreen} />
      ) : needsIdVerify ? (
        <Stack.Screen name="EmployeeIdVerify" component={EmployeeIdVerifyScreen} />
      ) : (
        // ---------- Signed-in, role-resolved stack ----------
        <Stack.Group>
          {user.role === 'receptionist' && (
            <Stack.Screen name="Tabs" component={TabNavigator} />
          )}
          {user.role === 'visitor' && (
            <Stack.Screen name="VisitorTabs" component={VisitorTabNavigator} />
          )}
          {user.role === 'employee' && (
            <Stack.Screen name="EmployeeTabs" component={EmployeeTabNavigator} />
          )}
          {user.role === 'manager' && (
            <Stack.Screen name="ManagerTabs" component={ManagerTabNavigator} />
          )}

          {/* Modal-style screens (forms) */}
          <Stack.Group screenOptions={{ presentation: 'modal' }}>
            <Stack.Screen name="RegisterVisitor" component={RegisterVisitorScreen} />
            <Stack.Screen name="AddEmployee" component={AddEmployeeScreen} />
            <Stack.Screen name="LogCall" component={LogCallScreen} />
          </Stack.Group>

          {/* Pushed detail / sub-module screens, reachable from Quick
              Actions and various rows rather than living in a tab bar */}
          <Stack.Screen name="Visitors" component={VisitorsScreen} />
          <Stack.Screen name="Directory" component={DirectoryScreen} />
          <Stack.Screen name="VisitorDetail" component={VisitorDetailScreen} />
          <Stack.Screen name="EmployeeDetail" component={EmployeeDetailScreen} />
          <Stack.Screen name="CallLog" component={CallLogScreen} />
          <Stack.Screen name="Reports" component={ReportsScreen} />
          <Stack.Screen name="NFCCards" component={NFCCardsScreen} />
          <Stack.Screen name="NFCLookup" component={NFCLookupScreen} />
          <Stack.Screen name="Attendance" component={AttendanceScreen} />
          <Stack.Screen name="Billing" component={BillingScreen} />
        </Stack.Group>
      )}
    </Stack.Navigator>
  );
}
