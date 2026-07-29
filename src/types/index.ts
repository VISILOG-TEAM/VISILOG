// Core domain types shared across the app. These describe the *mapped*
// (frontend-normalized, lowercase-enum) shapes produced by context/*.tsx --
// not the raw backend DTOs, which arrive with UPPERCASE enum strings and
// get normalized at the DataContext/AuthContext boundary (see mapVisitor,
// mapAppointment, etc.) so every screen can work with one consistent case.

import type { ComponentProps } from 'react';
import type { Ionicons } from '@expo/vector-icons';
import type { BrandTheme, StatusKey } from '../theme/colors';

export type { BrandTheme, StatusKey };

export type IoniconName = ComponentProps<typeof Ionicons>['name'];

export interface Option<T = string> {
  label: string;
  value: T;
  sublabel?: string;
}

export type Role = 'visitor' | 'receptionist' | 'employee' | 'manager';

export interface User {
  id: string;
  email: string;
  name: string;
  role: Role;
  employeeId: string | null;
  organizationId: string;
  organizationName: string;
  // False between signing up and entering the 6-digit code emailed to
  // this address. RootNavigator holds such an account on the verify
  // screen, and the backend refuses its token everywhere else.
  emailVerified: boolean;
}

// A named GPS point + radius the clock-in/visitor-check-in geofence
// check (locationCheck.ts) can be satisfied against -- an org can have
// more than one (see DataContext.officeLocations); the first is free
// on any plan, a second+ requires the enterprise plan.
export interface OfficeLocation {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
}

export interface Organization {
  id: string;
  code: string;
  name: string;
  logoUrl: string | null;
  theme: BrandTheme;
  wifiNetworkName: string | null;
  // The org's current plan id -- lets every role (not just managers,
  // who alone can see full Billing) do client-side plan-feature checks
  // like SettingsScreen's priority-support badge.
  planId: string | null;
}

export interface Employee {
  id: string;
  employeeId: string;
  name: string;
  department: string;
  phone: string;
  email: string;
  role: Role;
  // Whether this employee's clock-ins are locked to a phone yet -- see
  // ClockRecordService.checkDeviceBinding on the backend.
  deviceBound: boolean;
}

export type VisitorStatus = 'onsite' | 'completed';

export interface Visitor {
  id: string;
  badgeId: string;
  firstName: string;
  lastName: string;
  fullName: string;
  phone: string;
  email: string;
  company: string;
  purpose: string;
  hostId: string;
  checkInAt: string;
  checkOutAt: string | null;
  status: VisitorStatus;
  notes: string;
}

export type AppointmentStatus = 'pending' | 'admitted' | 'rejected';

export interface Appointment {
  id: string;
  visitorName: string;
  visitorPhone: string;
  visitorEmail: string;
  visitorCompany: string;
  purpose: string;
  hostId: string;
  scheduledAt: string;
  status: AppointmentStatus;
  nfcCode: string | null;
  bookedByEmail?: string | null;
  rescheduleReason?: string | null;
  rescheduledAt?: string | null;
  rejectReason?: string | null;
  checkedIn: boolean;
}

export type CallType = 'Incoming' | 'Outgoing' | 'Missed';

export interface Call {
  id: string;
  callerName: string;
  callerPhone: string;
  hostId: string;
  callType: CallType;
  purpose: string;
  durationMinutes: number;
  notes: string;
  timestamp: string;
}

export interface MeetingRoom {
  id: string;
  name: string;
  capacity: number | null;
  floor: string;
  photoUrl: string | null;
  description: string | null;
}

export type ClockType = 'in' | 'out';

export interface ClockRecord {
  id: string;
  employeeId: string;
  employeeName: string;
  type: ClockType;
  timestamp: string;
}

export type MeetingPriority = 'normal' | 'important' | 'urgent';
export type MeetingResponseStatus = 'pending' | 'acknowledged' | 'declined';

export interface RoomBookingResponse {
  employeeId: string;
  status: MeetingResponseStatus;
  declineReason: string | null;
  respondedAt: string | null;
  absent: boolean;
}

export interface ExternalGuest {
  name: string | null;
  email: string | null;
  phone: string | null;
}

export interface RoomBooking {
  id: string;
  roomId: string | null;
  location: string;
  organiserId: string;
  title: string;
  startTime: string;
  endTime: string;
  participantIds: string[];
  externalGuests: ExternalGuest[];
  priority: MeetingPriority;
  responses: RoomBookingResponse[];
  rescheduleReason?: string | null;
  rescheduledAt?: string | null;
}

export type NotificationType =
  | 'meeting_invite'
  | 'meeting_declined'
  | 'visit_admitted'
  | 'visit_rejected'
  | 'visit_checked_out'
  | 'appointment_requested'
  | 'appointment_rescheduled'
  | 'call_logged'
  | 'participant_absent';

export interface AppNotification {
  id: string;
  type: NotificationType;
  title: string;
  body: string;
  relatedId: string | null;
  read: boolean;
  createdAt: string;
}

export interface Plan {
  id: string;
  name: string;
  price: number;
  seatLimit: number;
  features: string[];
}

export type BillingStatus = 'active' | 'trial' | 'past_due';

export interface Billing {
  planId: string;
  status: BillingStatus;
  seatsUsed: number;
  renewalDate: string;
  paymentLast4: string | null;
}

export type InvoiceStatus = 'paid' | 'failed';

export interface Invoice {
  id: string;
  date: string;
  amount: number;
  status: InvoiceStatus;
}

// ---- operation input shapes ----

export interface RegisterVisitorInput {
  firstName: string;
  lastName: string;
  phone: string;
  email?: string;
  company?: string;
  purpose: string;
  hostId: string;
  notes?: string;
}

export interface BookVisitInput {
  visitorName: string;
  visitorPhone: string;
  visitorEmail?: string;
  visitorCompany?: string;
  purpose: string;
  hostId: string;
  scheduledAt: string;
}

export interface LogCallInput {
  callerName: string;
  callerPhone: string;
  hostId: string;
  callType: string;
  purpose: string;
  durationMinutes: number | string;
  notes?: string;
}

export interface EmployeeInput {
  employeeId?: string;
  name: string;
  department?: string;
  phone?: string;
  email?: string;
  role?: Role;
}

export interface BulkImportRowError {
  row: number;
  message: string;
}

export interface BulkImportResult<T> {
  created: T[];
  errors: BulkImportRowError[];
}

export interface OfficeLocationInput {
  name: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
}

export interface MeetingRoomInput {
  name: string;
  capacity?: number | string | null;
  floor?: string;
  photoUrl?: string | null;
  description?: string | null;
}

export interface BookRoomInput {
  roomId?: string | null;
  location?: string;
  title?: string;
  startTime: string;
  endTime: string;
  participantIds?: string[];
  externalGuests?: ExternalGuest[];
  priority?: MeetingPriority;
}

// No backend model exists for standalone NFC cards yet (the per-visit
// NFC code lives on Appointment.nfcCode) -- DataContext seeds this as an
// always-empty array, but NFCCardsScreen is written against this shape
// so it's ready once/if a real NfcCard endpoint exists.
export type NfcCardStatus = 'active' | 'revoked';
export type NfcHolderType = 'employee' | 'visitor';

export interface NfcCard {
  id: string;
  holderId: string;
  holderType: NfcHolderType;
  tokenHash: string;
  issuedAt: string;
  expiresAt: string;
  status: NfcCardStatus;
}

export interface AuthResult {
  ok: boolean;
  error?: string;
  organization?: Organization;
}
