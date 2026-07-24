# VisiLog -- device-binding for clock-in (frontend)
# Run this from the FRONTEND ROOT folder (VisiLog-frontend), NOT the server folder.
$ErrorActionPreference = 'Stop'
Start-Transcript -Path "$PSScriptRoot\devicebinding-log.txt" -Force | Out-Null

function Write-File($RelPath, $Content) {
    $full = Join-Path $PSScriptRoot $RelPath
    $dir = Split-Path $full -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($full, $Content)
}

Write-Host "--- Writing files ---"
$f0 = @'
import * as Application from 'expo-application';
import { Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

const FALLBACK_KEY = 'visilog.deviceId';

// A persistent identifier for this physical device, sent along with
// every clock-in so the backend can lock a staff member's attendance to
// the phone they first used (see ClockRecordService.checkDeviceBinding)
// -- stops "give a coworker my password so they can clock in for me,"
// since it doesn't matter whose login was used, only whose phone it is.
// Prefers the OS-level identifier, which survives an app reinstall
// (unlike a locally-generated id would), so reinstalling the app can't
// be used to dodge the device lock.
export async function getDeviceId(): Promise<string | null> {
  try {
    if (Platform.OS === 'android') {
      const id = Application.getAndroidId();
      if (id) return id;
    } else if (Platform.OS === 'ios') {
      const id = await Application.getIosIdForVendorAsync();
      if (id) return id;
    }
  } catch {
    // Fall through to the AsyncStorage-based fallback below.
  }
  return getOrCreateFallbackId();
}

// For platforms where the OS-level id isn't available (web preview,
// simulators without one, etc.) -- weaker (an uninstall/reinstall
// resets it), but still better than no device check at all.
async function getOrCreateFallbackId(): Promise<string | null> {
  try {
    const existing = await AsyncStorage.getItem(FALLBACK_KEY);
    if (existing) return existing;
    const generated = `fallback-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    await AsyncStorage.setItem(FALLBACK_KEY, generated);
    return generated;
  } catch {
    return null;
  }
}

'@
Write-File "src\api\deviceId.ts" $f0
$f1 = @'
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
}

export interface OfficeLocation {
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
  officeLocation: OfficeLocation | null;
  wifiNetworkName: string | null;
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

'@
Write-File "src\types\index.ts" $f1
$f2 = @'
import React, {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { apiClient } from '../api/client';
import { getDeviceId } from '../api/deviceId';
import { useAuth } from './AuthContext';
import type {
  Appointment,
  AppointmentStatus,
  AppNotification,
  Billing,
  BookRoomInput,
  BookVisitInput,
  BulkImportResult,
  Call,
  ClockRecord,
  ClockType,
  Employee,
  EmployeeInput,
  Invoice,
  LogCallInput,
  MeetingPriority,
  MeetingResponseStatus,
  MeetingRoom,
  MeetingRoomInput,
  NfcCard,
  NotificationType,
  Plan,
  RegisterVisitorInput,
  Role,
  RoomBooking,
  RoomBookingResponse,
  Visitor,
  VisitorStatus,
} from '../types';

// DataContext talks to the real VisiLog backend (see server/). Every
// collection below is fetched for the signed-in user's own organization
// (the backend derives that from the JWT, never from anything we send)
// and kept in local state, updated from each mutation's response so the
// UI doesn't need a full refetch after every action.
//
// Backend enums come back as UPPERCASE strings (VisitorStatus, Role,
// etc.) -- every screen in this app was built against the mock data's
// lowercase/Capitalized casing, so the map* helpers below normalize at
// the boundary and every screen keeps working unchanged.

// ---- raw backend DTO shapes (UPPERCASE enums, as they arrive on the wire) ----

interface VisitorDto extends Omit<Visitor, 'status'> {
  status: string;
}
interface AppointmentDto extends Omit<Appointment, 'status'> {
  status: string;
}
interface CallDto extends Omit<Call, 'callType'> {
  callType: string;
}
interface EmployeeDto {
  id: string;
  employeeCode: string;
  name: string;
  department?: string | null;
  phone?: string | null;
  email?: string | null;
  role: string;
  deviceBound: boolean;
}
interface ClockRecordDto extends Omit<ClockRecord, 'type'> {
  type: string;
}
interface RoomBookingResponseDto extends Omit<RoomBookingResponse, 'status'> {
  status: string;
}
interface RoomBookingDto extends Omit<
  RoomBooking,
  'location' | 'participantIds' | 'priority' | 'responses'
> {
  location?: string | null;
  participantIds?: string[] | null;
  priority?: string | null;
  responses?: RoomBookingResponseDto[] | null;
}
interface PlanDto extends Omit<Plan, 'price'> {
  price: string | number;
}
interface NotificationDto extends Omit<AppNotification, 'type'> {
  type: string;
}
interface BillingDto {
  plan: PlanDto;
  status: string;
  seatsUsed: number;
  renewalDate: string;
  paymentLast4: string | null;
}
interface InvoiceDto extends Omit<Invoice, 'amount' | 'status'> {
  amount: string | number;
  status: string;
}

const cap = (s: string): string => (s ? s.charAt(0) + s.slice(1).toLowerCase() : s);

const mapVisitor = (d: VisitorDto): Visitor => ({
  ...d,
  status: d.status.toLowerCase() as VisitorStatus,
});
const mapAppointment = (d: AppointmentDto): Appointment => ({
  ...d,
  status: d.status.toLowerCase() as AppointmentStatus,
});
const mapCall = (d: CallDto): Call => ({ ...d, callType: cap(d.callType) as Call['callType'] });
const mapEmployee = (d: EmployeeDto): Employee => ({
  id: d.id,
  employeeId: d.employeeCode,
  name: d.name,
  department: d.department || '',
  phone: d.phone || '',
  email: d.email || '',
  role: d.role.toLowerCase() as Role,
  deviceBound: d.deviceBound,
});
const mapClockRecord = (d: ClockRecordDto): ClockRecord => ({
  ...d,
  type: d.type.toLowerCase() as ClockType,
});
const mapRoomBookingResponse = (d: RoomBookingResponseDto): RoomBookingResponse => ({
  ...d,
  status: d.status.toLowerCase() as MeetingResponseStatus,
});
const mapRoomBooking = (d: RoomBookingDto): RoomBooking => ({
  ...d,
  location: d.location || '',
  participantIds: d.participantIds || [],
  priority: (d.priority || 'normal').toLowerCase() as MeetingPriority,
  responses: (d.responses || []).map(mapRoomBookingResponse),
});
const mapPlan = (d: PlanDto): Plan => ({ ...d, price: Number(d.price) });
const mapBilling = (d: BillingDto): Billing => ({
  planId: d.plan.id,
  status: d.status.toLowerCase() as Billing['status'],
  seatsUsed: d.seatsUsed,
  renewalDate: d.renewalDate,
  paymentLast4: d.paymentLast4,
});
const mapInvoice = (d: InvoiceDto): Invoice => ({
  ...d,
  amount: Number(d.amount),
  status: d.status.toLowerCase() as Invoice['status'],
});
const mapNotification = (d: NotificationDto): AppNotification => ({
  ...d,
  type: d.type.toLowerCase() as NotificationType,
});

interface DataContextValue {
  // collections
  visitors: Visitor[];
  appointments: Appointment[];
  calls: Call[];
  nfcCards: NfcCard[];
  roomBookings: RoomBooking[];
  employees: Employee[];
  meetingRooms: MeetingRoom[];
  // lookup helpers
  employeeById: (id: string) => Employee | undefined;
  roomById: (id: string) => MeetingRoom | undefined;
  // pull-to-refresh -- refetches every collection above in one go
  refreshAll: () => Promise<void>;
  // operations
  registerAndCheckIn: (input: RegisterVisitorInput) => Promise<Visitor>;
  checkOutVisitor: (visitorId: string, notes?: string) => Promise<Visitor>;
  updateAppointmentStatus: (
    id: string,
    status: AppointmentStatus,
    reason?: string,
  ) => Promise<Appointment>;
  admitAppointment: (appointment: Appointment) => Promise<Visitor>;
  logCall: (input: LogCallInput) => Promise<Call>;
  addEmployee: (input: EmployeeInput) => Promise<Employee>;
  updateEmployee: (id: string, input: EmployeeInput) => Promise<Employee>;
  bulkImportEmployees: (rows: EmployeeInput[]) => Promise<BulkImportResult<Employee>>;
  removeEmployee: (id: string) => Promise<void>;
  addMeetingRoom: (input: MeetingRoomInput) => Promise<MeetingRoom>;
  updateMeetingRoom: (id: string, input: MeetingRoomInput) => Promise<MeetingRoom>;
  bulkImportMeetingRooms: (rows: MeetingRoomInput[]) => Promise<BulkImportResult<MeetingRoom>>;
  removeMeetingRoom: (id: string) => Promise<void>;
  bookVisit: (input: BookVisitInput) => Promise<Appointment>;
  findAppointmentByCode: (code: string) => Promise<Appointment | null>;
  // work attendance (clock in/out) + appointment rescheduling
  clockRecords: ClockRecord[];
  clockIn: (employeeId: string, employeeName: string) => Promise<ClockRecord>;
  clockOut: (employeeId: string, employeeName: string) => Promise<ClockRecord>;
  isClockedIn: (employeeId: string) => boolean;
  hasClockedInToday: (employeeId: string) => boolean;
  refreshClockRecords: () => Promise<void>;
  resetEmployeeDevice: (employeeId: string) => Promise<void>;
  rescheduleAppointment: (
    id: string,
    newScheduledAt: string,
    reason?: string,
  ) => Promise<Appointment>;
  // self-service room booking
  bookRoom: (input: BookRoomInput) => Promise<RoomBooking>;
  refreshRoomBookings: () => Promise<void>;
  respondToMeeting: (
    bookingId: string,
    status: 'acknowledged' | 'declined',
    reason?: string,
  ) => Promise<void>;
  markParticipantAbsent: (bookingId: string, employeeId: string, absent: boolean) => Promise<void>;
  // billing / subscriptions
  plans: Plan[];
  billing: Billing | null;
  invoices: Invoice[];
  changePlan: (planId: string) => Promise<Billing>;
  // in-app notifications (meeting invites, etc.)
  notifications: AppNotification[];
  unreadNotificationCount: number;
  refreshNotifications: () => Promise<void>;
  markNotificationRead: (id: string) => Promise<void>;
  // derived
  stats: {
    visitorsToday: number;
    onsite: number;
    callsToday: number;
    visitorsThisMonth: number;
    pendingApprovals: number;
  };
}

const DataContext = createContext<DataContextValue | null>(null);

export function DataProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();

  const [visitors, setVisitors] = useState<Visitor[]>([]);
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [calls, setCalls] = useState<Call[]>([]);
  // No backend model for standalone NFC cards in this pass -- the
  // per-visit NFC code lives on the appointment itself (see nfcCode).
  const [nfcCards] = useState<NfcCard[]>([]);
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [meetingRooms, setMeetingRooms] = useState<MeetingRoom[]>([]);
  const [clockRecords, setClockRecords] = useState<ClockRecord[]>([]);
  const [roomBookings, setRoomBookings] = useState<RoomBooking[]>([]);
  const [billing, setBilling] = useState<Billing | null>(null);
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [plans, setPlans] = useState<Plan[]>([]);
  const [notifications, setNotifications] = useState<AppNotification[]>([]);

  // Fetches every collection for the signed-in user. Used both for the
  // one-time load on sign-in and as the shared pull-to-refresh action
  // every screen calls -- previously the only way to see something
  // that changed server-side (e.g. a new pending appointment someone
  // else booked) was to sign out and back in, since nothing ever
  // refetched on its own. Billing/invoices are manager-only on the
  // backend, so non-managers skip those calls entirely rather than
  // getting a 403.
  const loadAll = async (): Promise<void> => {
    if (!user) return;
    const isManager = user.role === 'manager';
    const appointmentsPath =
      user.role === 'visitor' ? '/api/v1/appointments?mine=true' : '/api/v1/appointments';

    const [v, a, c, e, r, cr, rb, p] = await Promise.all([
      apiClient.get<VisitorDto[]>('/api/v1/visitors'),
      apiClient.get<AppointmentDto[]>(appointmentsPath),
      apiClient.get<CallDto[]>('/api/v1/calls'),
      apiClient.get<EmployeeDto[]>('/api/v1/employees'),
      apiClient.get<MeetingRoom[]>('/api/v1/meeting-rooms'),
      apiClient.get<ClockRecordDto[]>('/api/v1/clock-records'),
      apiClient.get<RoomBookingDto[]>('/api/v1/room-bookings'),
      apiClient.get<PlanDto[]>('/api/v1/plans'),
    ]);
    setVisitors(v.map(mapVisitor));
    setAppointments(a.map(mapAppointment));
    setCalls(c.map(mapCall));
    setEmployees(e.map(mapEmployee));
    setMeetingRooms(r);
    setClockRecords(cr.map(mapClockRecord));
    setRoomBookings(rb.map(mapRoomBooking));
    setPlans(p.map(mapPlan));

    if (isManager) {
      const [b, inv] = await Promise.all([
        apiClient.get<BillingDto>('/api/v1/billing'),
        apiClient.get<InvoiceDto[]>('/api/v1/billing/invoices'),
      ]);
      setBilling(mapBilling(b));
      setInvoices(inv.map(mapInvoice));
    }

    // Visitors have no employeeId, so there's nothing for them to be
    // notified about (meeting invites only ever target staff).
    if (user.employeeId) {
      const n = await apiClient.get<NotificationDto[]>('/api/v1/notifications');
      setNotifications(n.map(mapNotification));
    }
  };

  useEffect(() => {
    if (!user) {
      setVisitors([]);
      setAppointments([]);
      setCalls([]);
      setEmployees([]);
      setMeetingRooms([]);
      setClockRecords([]);
      setRoomBookings([]);
      setBilling(null);
      setInvoices([]);
      setPlans([]);
      setNotifications([]);
      return;
    }
    loadAll();
  }, [user?.id]);

  const refreshAll = async (): Promise<void> => {
    await loadAll();
  };

  // ---- lookup helpers ----
  const employeeById = (id: string) => employees.find((e) => e.id === id);
  const roomById = (id: string) => meetingRooms.find((r) => r.id === id);

  // ---- visitor operations ----

  const registerAndCheckIn = async (input: RegisterVisitorInput): Promise<Visitor> => {
    const dto = await apiClient.post<VisitorDto>('/api/v1/visitors', {
      firstName: input.firstName,
      lastName: input.lastName,
      phone: input.phone,
      email: input.email,
      company: input.company,
      purpose: input.purpose,
      hostId: input.hostId,
      notes: input.notes,
    });
    const visitor = mapVisitor(dto);
    setVisitors((vs) => [visitor, ...vs]);
    return visitor;
  };

  const checkOutVisitor = async (visitorId: string, notes = ''): Promise<Visitor> => {
    const dto = await apiClient.patch<VisitorDto>(`/api/v1/visitors/${visitorId}/check-out`, {
      notes,
    });
    const visitor = mapVisitor(dto);
    setVisitors((vs) => vs.map((v) => (v.id === visitorId ? visitor : v)));
    return visitor;
  };

  // ---- appointment operations ----

  const bookVisit = async (input: BookVisitInput): Promise<Appointment> => {
    const dto = await apiClient.post<AppointmentDto>('/api/v1/appointments', {
      visitorName: input.visitorName,
      visitorPhone: input.visitorPhone,
      visitorEmail: input.visitorEmail,
      visitorCompany: input.visitorCompany,
      purpose: input.purpose,
      hostId: input.hostId,
      scheduledAt: input.scheduledAt,
    });
    const appointment = mapAppointment(dto);
    setAppointments((as) => [appointment, ...as]);
    return appointment;
  };

  const findAppointmentByCode = async (code: string): Promise<Appointment | null> => {
    const clean = (code || '').trim().toUpperCase();
    if (!clean) return null;
    try {
      const dto = await apiClient.get<AppointmentDto>(
        `/api/v1/appointments/by-code/${encodeURIComponent(clean)}`,
      );
      return mapAppointment(dto);
    } catch {
      return null;
    }
  };

  const updateAppointmentStatus = async (
    id: string,
    status: AppointmentStatus,
    reason?: string,
  ): Promise<Appointment> => {
    const dto = await apiClient.patch<AppointmentDto>(`/api/v1/appointments/${id}/status`, {
      status,
      reason,
    });
    const appointment = mapAppointment(dto);
    setAppointments((as) => as.map((a) => (a.id === id ? appointment : a)));
    return appointment;
  };

  // Admitting also registers + checks in the visitor server-side. The
  // admit response is only the updated appointment, so we refetch the
  // visitor list (newest-first) and hand back that just-created record.
  const admitAppointment = async (appointment: Appointment): Promise<Visitor> => {
    const apptDto = await apiClient.post<AppointmentDto>(
      `/api/v1/appointments/${appointment.id}/admit`,
    );
    const updated = mapAppointment(apptDto);
    setAppointments((as) => as.map((a) => (a.id === updated.id ? updated : a)));

    const visitorDtos = await apiClient.get<VisitorDto[]>('/api/v1/visitors');
    const mapped = visitorDtos.map(mapVisitor);
    setVisitors(mapped);
    return mapped[0];
  };

  // ---- call log operations ----

  const logCall = async (input: LogCallInput): Promise<Call> => {
    const dto = await apiClient.post<CallDto>('/api/v1/calls', {
      callerName: input.callerName,
      callerPhone: input.callerPhone,
      hostId: input.hostId,
      callType: input.callType,
      purpose: input.purpose,
      durationMinutes: Number(input.durationMinutes) || 0,
      notes: input.notes,
    });
    const call = mapCall(dto);
    setCalls((cs) => [call, ...cs]);
    return call;
  };

  // ---- directory (staff roster) operations -- manager only ----

  const addEmployee = async (input: EmployeeInput): Promise<Employee> => {
    const dto = await apiClient.post<EmployeeDto>('/api/v1/employees', {
      employeeCode: input.employeeId,
      name: input.name,
      department: input.department,
      phone: input.phone,
      email: input.email,
      role: input.role || 'employee',
    });
    const employee = mapEmployee(dto);
    setEmployees((es) => [...es, employee]);
    return employee;
  };

  // CSV bulk import -- parsed rows come in already shaped like
  // EmployeeInput (see DirectoryScreen's mapRow); the backend still
  // validates and reports back per-row, since a CSV can have typos a
  // single-add form would never let through.
  const bulkImportEmployees = async (
    rows: EmployeeInput[],
  ): Promise<BulkImportResult<Employee>> => {
    const res = await apiClient.post<{
      created: EmployeeDto[];
      errors: BulkImportResult<never>['errors'];
    }>('/api/v1/employees/bulk', {
      employees: rows.map((r) => ({
        employeeCode: r.employeeId,
        name: r.name,
        department: r.department,
        phone: r.phone,
        email: r.email,
        role: r.role || 'employee',
      })),
    });
    const created = res.created.map(mapEmployee);
    setEmployees((es) => [...es, ...created]);
    return { created, errors: res.errors };
  };

  const updateEmployee = async (id: string, input: EmployeeInput): Promise<Employee> => {
    const dto = await apiClient.patch<EmployeeDto>(`/api/v1/employees/${id}`, {
      employeeCode: input.employeeId,
      name: input.name,
      department: input.department,
      phone: input.phone,
      email: input.email,
      role: input.role,
    });
    const employee = mapEmployee(dto);
    setEmployees((es) => es.map((e) => (e.id === id ? employee : e)));
    return employee;
  };

  const removeEmployee = async (id: string): Promise<void> => {
    await apiClient.delete(`/api/v1/employees/${id}`);
    setEmployees((es) => es.filter((e) => e.id !== id));
  };

  // ---- meeting rooms (Company Setup, manager only) ----

  const addMeetingRoom = async (input: MeetingRoomInput): Promise<MeetingRoom> => {
    const room = await apiClient.post<MeetingRoom>('/api/v1/meeting-rooms', {
      name: input.name,
      capacity: Number(input.capacity) || null,
      floor: input.floor,
      photoUrl: input.photoUrl || null,
      description: input.description || null,
    });
    setMeetingRooms((rs) => [...rs, room]);
    return room;
  };

  // CSV bulk import -- see bulkImportEmployees above for the pattern.
  const bulkImportMeetingRooms = async (
    rows: MeetingRoomInput[],
  ): Promise<BulkImportResult<MeetingRoom>> => {
    const res = await apiClient.post<{
      created: MeetingRoom[];
      errors: BulkImportResult<never>['errors'];
    }>('/api/v1/meeting-rooms/bulk', {
      rooms: rows.map((r) => ({
        name: r.name,
        capacity: Number(r.capacity) || null,
        floor: r.floor,
        photoUrl: r.photoUrl || null,
        description: r.description || null,
      })),
    });
    setMeetingRooms((rs) => [...rs, ...res.created]);
    return res;
  };

  const updateMeetingRoom = async (id: string, input: MeetingRoomInput): Promise<MeetingRoom> => {
    const room = await apiClient.patch<MeetingRoom>(`/api/v1/meeting-rooms/${id}`, {
      name: input.name,
      capacity: Number(input.capacity) || null,
      floor: input.floor,
      photoUrl: input.photoUrl || null,
      description: input.description || null,
    });
    setMeetingRooms((rs) => rs.map((r) => (r.id === id ? room : r)));
    return room;
  };

  const removeMeetingRoom = async (id: string): Promise<void> => {
    await apiClient.delete(`/api/v1/meeting-rooms/${id}`);
    setMeetingRooms((rs) => rs.filter((r) => r.id !== id));
  };

  // ---- clock in/out (work attendance) ----

  const clockIn = async (employeeId: string, employeeName: string): Promise<ClockRecord> => {
    const deviceId = await getDeviceId();
    const dto = await apiClient.post<ClockRecordDto>('/api/v1/clock-records/in', {
      employeeId,
      employeeName,
      deviceId,
    });
    const record = mapClockRecord(dto);
    setClockRecords((cs) => [record, ...cs]);
    return record;
  };

  const clockOut = async (employeeId: string, employeeName: string): Promise<ClockRecord> => {
    const deviceId = await getDeviceId();
    const dto = await apiClient.post<ClockRecordDto>('/api/v1/clock-records/out', {
      employeeId,
      employeeName,
      deviceId,
    });
    const record = mapClockRecord(dto);
    setClockRecords((cs) => [record, ...cs]);
    return record;
  };

  // Manager-only -- clears the phone link so the next clock-in from any
  // device re-binds fresh. See ClockCard's "different phone" error and
  // EmployeeDetailScreen's reset button.
  const resetEmployeeDevice = async (id: string): Promise<void> => {
    const dto = await apiClient.post<EmployeeDto>(`/api/v1/employees/${id}/reset-device`, {});
    const employee = mapEmployee(dto);
    setEmployees((es) => es.map((e) => (e.id === id ? employee : e)));
  };

  // Everything above only reflects actions taken in *this* signed-in
  // session -- a receptionist clocking in on their own phone doesn't
  // push anything to a manager's already-open app (no websockets/
  // polling in this build). ManagerClockInsScreen calls this whenever
  // it comes into focus so it actually picks up everyone else's
  // clock-ins/outs instead of showing whatever was loaded at login.
  const refreshClockRecords = async (): Promise<void> => {
    const cr = await apiClient.get<ClockRecordDto[]>('/api/v1/clock-records');
    setClockRecords(cr.map(mapClockRecord));
  };

  // Records are newest-first -- these stay synchronous, derived from the
  // locally-held ledger, so ClockCard's render logic doesn't change.
  const isClockedIn = (employeeId: string): boolean => {
    const mine = clockRecords.find((c) => c.employeeId === employeeId);
    return !!mine && mine.type === 'in';
  };

  const hasClockedInToday = (employeeId: string): boolean => {
    const todayKey = new Date().toDateString();
    return clockRecords.some(
      (c) =>
        c.employeeId === employeeId &&
        c.type === 'in' &&
        new Date(c.timestamp).toDateString() === todayKey,
    );
  };

  // ---- self-service meeting booking ----

  const bookRoom = async (input: BookRoomInput): Promise<RoomBooking> => {
    const dto = await apiClient.post<RoomBookingDto>('/api/v1/room-bookings', {
      roomId: input.roomId || null,
      location: input.roomId ? null : input.location || '',
      title: input.title || 'Meeting',
      startTime: input.startTime,
      endTime: input.endTime,
      participantIds: input.participantIds || [],
      externalGuests: input.externalGuests || [],
      priority: input.priority || 'normal',
    });
    const booking = mapRoomBooking(dto);
    setRoomBookings((rs) => [booking, ...rs]);
    return booking;
  };

  // A participant acknowledging ("seen it") or declining (with a
  // reason) their invite to someone else's meeting.
  const respondToMeeting = async (
    bookingId: string,
    status: 'acknowledged' | 'declined',
    reason?: string,
  ): Promise<void> => {
    const dto = await apiClient.patch<RoomBookingDto>(
      `/api/v1/room-bookings/${bookingId}/respond`,
      {
        status,
        reason,
      },
    );
    const updated = mapRoomBooking(dto);
    setRoomBookings((rs) => rs.map((b) => (b.id === bookingId ? updated : b)));
  };

  // Organiser marking who actually showed up to their own meeting,
  // after the fact -- independent of whether that person acknowledged
  // or declined beforehand.
  const markParticipantAbsent = async (
    bookingId: string,
    employeeId: string,
    absent: boolean,
  ): Promise<void> => {
    const dto = await apiClient.patch<RoomBookingDto>(
      `/api/v1/room-bookings/${bookingId}/participants/${employeeId}/absent`,
      { absent },
    );
    const updated = mapRoomBooking(dto);
    setRoomBookings((rs) => rs.map((b) => (b.id === bookingId ? updated : b)));
  };

  // Same cross-session staleness issue as clock records: roomBookings
  // is only loaded once at login, so a meeting booked in a different
  // signed-in session (e.g. Manager books on their phone, Receptionist
  // is already looking at the Meetings tab on theirs) wouldn't appear
  // without this. AppointmentsScreen calls it on focus.
  const refreshRoomBookings = async (): Promise<void> => {
    const rb = await apiClient.get<RoomBookingDto[]>('/api/v1/room-bookings');
    setRoomBookings(rb.map(mapRoomBooking));
  };

  // ---- appointment rescheduling (Employee & Visitor only) ----

  const rescheduleAppointment = async (
    id: string,
    newScheduledAt: string,
    reason?: string,
  ): Promise<Appointment> => {
    const dto = await apiClient.patch<AppointmentDto>(`/api/v1/appointments/${id}/reschedule`, {
      newScheduledAt,
      reason: reason || '',
    });
    const appointment = mapAppointment(dto);
    setAppointments((as) => as.map((a) => (a.id === id ? appointment : a)));
    return appointment;
  };

  // ---- billing (manager only) ----

  const changePlan = async (planId: string): Promise<Billing> => {
    const dto = await apiClient.patch<BillingDto>('/api/v1/billing/plan', { planId });
    const next = mapBilling(dto);
    setBilling(next);
    return next;
  };

  // ---- in-app notifications ----

  const refreshNotifications = async (): Promise<void> => {
    const n = await apiClient.get<NotificationDto[]>('/api/v1/notifications');
    setNotifications(n.map(mapNotification));
  };

  const markNotificationRead = async (id: string): Promise<void> => {
    const dto = await apiClient.patch<NotificationDto>(`/api/v1/notifications/${id}/read`);
    const updated = mapNotification(dto);
    setNotifications((ns) => ns.map((n) => (n.id === id ? updated : n)));
  };

  const unreadNotificationCount = notifications.filter((n) => !n.read).length;

  // ---- derived stats for the dashboard ----
  const stats = useMemo(() => {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).getTime();

    const todayVisitors = visitors.filter((v) => new Date(v.checkInAt).getTime() >= startOfDay);
    const onsite = visitors.filter((v) => v.status === 'onsite');
    const callsToday = calls.filter((c) => new Date(c.timestamp).getTime() >= startOfDay);
    const monthVisitors = visitors.filter((v) => new Date(v.checkInAt).getTime() >= startOfMonth);
    const pendingApprovals = appointments.filter((a) => a.status === 'pending');

    return {
      visitorsToday: todayVisitors.length,
      onsite: onsite.length,
      callsToday: callsToday.length,
      visitorsThisMonth: monthVisitors.length,
      pendingApprovals: pendingApprovals.length,
    };
  }, [visitors, calls, appointments]);

  return (
    <DataContext.Provider
      value={{
        // collections
        visitors,
        appointments,
        calls,
        nfcCards,
        roomBookings,
        employees,
        meetingRooms,
        // lookup helpers
        employeeById,
        roomById,
        // pull-to-refresh
        refreshAll,
        // operations
        registerAndCheckIn,
        checkOutVisitor,
        updateAppointmentStatus,
        admitAppointment,
        logCall,
        addEmployee,
        updateEmployee,
        bulkImportEmployees,
        removeEmployee,
        addMeetingRoom,
        updateMeetingRoom,
        bulkImportMeetingRooms,
        removeMeetingRoom,
        bookVisit,
        findAppointmentByCode,
        // work attendance (clock in/out) + appointment rescheduling
        clockRecords,
        clockIn,
        clockOut,
        isClockedIn,
        hasClockedInToday,
        refreshClockRecords,
        resetEmployeeDevice,
        rescheduleAppointment,
        // self-service room booking
        bookRoom,
        refreshRoomBookings,
        respondToMeeting,
        markParticipantAbsent,
        // billing / subscriptions
        plans,
        billing,
        invoices,
        changePlan,
        // in-app notifications
        notifications,
        unreadNotificationCount,
        refreshNotifications,
        markNotificationRead,
        // derived
        stats,
      }}
    >
      {children}
    </DataContext.Provider>
  );
}

export const useData = (): DataContextValue => {
  const ctx = useContext(DataContext);
  if (!ctx) throw new Error('useData must be used within a DataProvider');
  return ctx;
};

'@
Write-File "src\context\DataContext.tsx" $f2
$f3 = @'
import React from 'react';
import { View, StyleSheet, Pressable, Linking, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen, Header, Text, Card, Avatar, Button } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { useData } from '../context/DataContext';
import { useAuth } from '../context/AuthContext';
import { ApiError } from '../api/client';
import type { RootStackScreenProps } from '../types/navigation';
import type { IoniconName } from '../types';

// EmployeeDetailScreen -- single staff member's profile.
export default function EmployeeDetailScreen({
  route,
  navigation,
}: RootStackScreenProps<'EmployeeDetail'>) {
  const { colors } = useTheme();
  const { employeeId } = route.params;
  const { employees, removeEmployee, resetEmployeeDevice } = useData();
  const { user } = useAuth();
  const employee = employees.find((e) => e.id === employeeId);

  if (!employee) {
    return (
      <Screen>
        <Header title="Not found" rightIcon="close" onRightPress={() => navigation.goBack()} />
      </Screen>
    );
  }

  const onRemove = () => {
    Alert.alert('Remove employee?', `${employee.name} will be removed from the directory.`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Remove',
        style: 'destructive',
        onPress: async () => {
          try {
            await removeEmployee(employee.id);
            navigation.goBack();
          } catch (err) {
            Alert.alert(
              'Could not remove employee',
              err instanceof ApiError ? err.message : 'Something went wrong.',
            );
          }
        },
      },
    ]);
  };

  const onResetDevice = () => {
    Alert.alert(
      'Reset clocked-in device?',
      `${employee.name} will be able to clock in from a new phone. Only do this if they've genuinely switched devices.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Reset',
          style: 'destructive',
          onPress: async () => {
            try {
              await resetEmployeeDevice(employee.id);
            } catch (err) {
              Alert.alert(
                'Could not reset device',
                err instanceof ApiError ? err.message : 'Something went wrong.',
              );
            }
          },
        },
      ],
    );
  };

  return (
    <Screen>
      <Header title="Staff profile" rightIcon="close" onRightPress={() => navigation.goBack()} />

      <Card>
        <View style={styles.headerRow}>
          <Avatar name={employee.name} size={64} />
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="h2">{employee.name}</Text>
            <Text variant="caption" color={colors.textSecondary}>
              {employee.department}
            </Text>
          </View>
        </View>

        <View style={styles.actionRow}>
          <ActionPill
            icon="call"
            label="Call"
            onPress={() => Linking.openURL(`tel:${employee.phone}`)}
          />
          <ActionPill
            icon="mail"
            label="Email"
            onPress={() => Linking.openURL(`mailto:${employee.email}`)}
          />
          <ActionPill
            icon="chatbubble-ellipses"
            label="Message"
            onPress={() => Linking.openURL(`sms:${employee.phone}`)}
          />
        </View>
      </Card>

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Contact
      </Text>
      <Card>
        <Row icon="call-outline" label="Personal phone" value={employee.phone} />
        <Divider />
        <Row icon="mail-outline" label="Email" value={employee.email} />
        <Divider />
        <Row icon="briefcase-outline" label="Department" value={employee.department} />
      </Card>

      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Clock-in device
      </Text>
      <Card>
        <View style={styles.row}>
          <View style={[styles.icon, { backgroundColor: colors.surfaceAlt }]}>
            <Ionicons
              name={employee.deviceBound ? 'phone-portrait' : 'phone-portrait-outline'}
              size={18}
              color={colors.brand}
            />
          </View>
          <View style={{ flex: 1 }}>
            <Text variant="caption" color={colors.textSecondary}>
              Status
            </Text>
            <Text variant="bodySemibold">
              {employee.deviceBound ? 'Locked to a phone' : 'Not yet locked'}
            </Text>
          </View>
        </View>
        {user?.role === 'manager' && employee.deviceBound && (
          <Button
            label="Reset device"
            variant="secondary"
            icon="refresh-outline"
            onPress={onResetDevice}
            style={{ marginTop: spacing.sm }}
          />
        )}
      </Card>

      <Button
        label="Remove from directory"
        variant="secondary"
        icon="trash-outline"
        onPress={onRemove}
        style={{ marginTop: spacing.xl }}
      />
    </Screen>
  );
}

function Row({ icon, label, value }: { icon: IoniconName; label: string; value: string }) {
  const { colors } = useTheme();
  return (
    <View style={styles.row}>
      <View style={[styles.icon, { backgroundColor: colors.surfaceAlt }]}>
        <Ionicons name={icon} size={18} color={colors.brand} />
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="caption" color={colors.textSecondary}>
          {label}
        </Text>
        <Text variant="bodySemibold">{value}</Text>
      </View>
    </View>
  );
}

function Divider() {
  const { colors } = useTheme();
  return <View style={[styles.divider, { backgroundColor: colors.border }]} />;
}

function ActionPill({
  icon,
  label,
  onPress,
}: {
  icon: IoniconName;
  label: string;
  onPress: () => void;
}) {
  const { colors } = useTheme();
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.pill,
        { backgroundColor: colors.primarySurface },
        pressed && { opacity: 0.85 },
      ]}
    >
      <Ionicons name={icon} size={18} color={colors.primary} />
      <Text variant="caption" color={colors.brand} style={{ marginTop: 2 }}>
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  headerRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.md },
  actionRow: { flexDirection: 'row', gap: spacing.xs },
  pill: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: spacing.sm,
    borderRadius: radius.md,
  },
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  row: { flexDirection: 'row', alignItems: 'center', paddingVertical: spacing.xs },
  icon: {
    width: 32,
    height: 32,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, marginVertical: spacing.xs, marginLeft: 32 + spacing.sm },
});

'@
Write-File "src\screens\EmployeeDetailScreen.tsx" $f3

Write-Host "--- Files written, verifying ---"
$paths = @(
    "src\api\deviceId.ts",
    "src\types\index.ts",
    "src\context\DataContext.tsx",
    "src\screens\EmployeeDetailScreen.tsx"
)
foreach ($p in $paths) {
    $full = Join-Path $PSScriptRoot $p
    if (Test-Path $full) { Write-Host "OK   $p" } else { Write-Host "MISSING   $p" }
}

Stop-Transcript | Out-Null
Write-Host ""
Write-Host "Done. Next steps:"
Write-Host "  1. npx expo install expo-application"
Write-Host "  2. npx tsc --noEmit"
