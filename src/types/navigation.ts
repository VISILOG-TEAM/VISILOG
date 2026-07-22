import type { NativeStackNavigationProp, NativeStackScreenProps } from '@react-navigation/native-stack';

// Route param types for the single root native-stack navigator (see
// navigation/RootNavigator.tsx). Every per-role tab navigator
// (VisitorTabNavigator, EmployeeTabNavigator, ManagerTabNavigator,
// TabNavigator) is itself mounted as one screen in this stack, and
// React Navigation merges the stack's navigation prop into every
// nested tab screen -- so typing screens against this one param list
// (rather than a separate list per tab navigator) matches how
// `navigation.navigate(...)` actually resolves at runtime across the
// whole app.
export type RootStackParamList = {
  // Signed-out stack
  Login: undefined;
  Signup: undefined;
  ForgotPassword: undefined;
  RegisterCompany: undefined;
  LegalAgreement: {
    pending?: {
      companyName: string;
      adminName: string;
      adminEmail: string;
      password: string;
    };
  } | undefined;

  // Per-role tab shells
  Tabs: undefined;
  VisitorTabs: undefined;
  EmployeeTabs: undefined;
  ManagerTabs: undefined;

  // Tab screens (registered by name inside each tab navigator)
  Home: undefined;
  Book: undefined;
  Appointments: undefined;
  Settings: undefined;
  Visits: undefined;
  'Clock ins': undefined;
  Logs: undefined;

  // Modal-style screens
  RegisterVisitor: undefined;
  AddEmployee: undefined;
  LogCall: undefined;

  // Pushed detail / sub-module screens
  Visitors: undefined;
  Directory: undefined;
  VisitorDetail: { visitorId: string };
  EmployeeDetail: { employeeId: string };
  CallLog: undefined;
  Reports: undefined;
  NFCCards: undefined;
  NFCLookup: undefined;
  Attendance: undefined;
  History: { tab?: 'appointments' | 'meetings' | 'clock' } | undefined;
  Billing: undefined;
  CompanySetup: undefined;
  MeetingRooms: undefined;
  Notifications: undefined;
};

export type RootStackScreenName = keyof RootStackParamList;

// Reusable prop types for screen components. Most screens only care
// about `navigation` (no route params); use RootStackScreenProps for
// the handful that read route.params (VisitorDetail, EmployeeDetail,
// LegalAgreement).
export type RootStackNavigation = NativeStackNavigationProp<RootStackParamList>;
export type RootStackScreenProps<T extends RootStackScreenName> = NativeStackScreenProps<RootStackParamList, T>;