import React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import { useAuth } from '../context/AuthContext';
import SplashScreen from '../screens/SplashScreen';

// Auth / onboarding screens
import LoginScreen from '../screens/LoginScreen';
import SignupScreen from '../screens/SignupScreen';
import RegisterCompanyScreen from '../screens/RegisterCompanyScreen';
import LegalAgreementScreen from '../screens/LegalAgreementScreen';

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
import CompanySetupScreen from '../screens/CompanySetupScreen';
import MeetingRoomsScreen from '../screens/MeetingRoomsScreen';
import type { RootStackParamList } from '../types/navigation';

const Stack = createNativeStackNavigator<RootStackParamList>();

// Root navigator. Role is fixed server-side at signup (matched against
// the company's staff roster, or visitor if there's no match), so a
// signed-in user goes straight to their role's tab shell — no picker,
// no ID-verify step. `initializing` covers the one-time check for a
// previously-stored session on cold start.
export default function RootNavigator() {
  const { user, initializing } = useAuth();

  if (initializing) {
    return <SplashScreen />;
  }

  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {!user ? (
        // ---------- Signed-out stack ----------
        <Stack.Group>
          <Stack.Screen name="Login" component={LoginScreen} />
          <Stack.Screen name="Signup" component={SignupScreen} />
          <Stack.Screen name="RegisterCompany" component={RegisterCompanyScreen} />
          <Stack.Screen name="LegalAgreement" component={LegalAgreementScreen} />
        </Stack.Group>
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
          <Stack.Screen name="CompanySetup" component={CompanySetupScreen} />
          <Stack.Screen name="MeetingRooms" component={MeetingRoomsScreen} />
          <Stack.Screen name="LegalAgreement" component={LegalAgreementScreen} />
        </Stack.Group>
      )}
    </Stack.Navigator>
  );
}
