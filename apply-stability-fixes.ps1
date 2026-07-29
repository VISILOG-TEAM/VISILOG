# VisiLog -- stability fixes: vanishing data, silent logout, system-font leak.
# Run this from the FRONTEND ROOT folder (VisiLog-frontend), NOT the server folder.
$ErrorActionPreference = 'Stop'
Start-Transcript -Path "$PSScriptRoot\stabilityfixes-log.txt" -Force | Out-Null

function Write-File($RelPath, $Content) {
    $full = Join-Path $PSScriptRoot $RelPath
    $dir = Split-Path $full -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($full, $Content)
}

Write-Host "--- Writing files ---"
$f0 = @'
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
  OfficeLocation,
  OfficeLocationInput,
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
  officeLocations: OfficeLocation[];
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
  addOfficeLocation: (input: OfficeLocationInput) => Promise<OfficeLocation>;
  updateOfficeLocation: (id: string, input: OfficeLocationInput) => Promise<OfficeLocation>;
  removeOfficeLocation: (id: string) => Promise<void>;
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
  refreshEmployees: () => Promise<void>;
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
  const [officeLocations, setOfficeLocations] = useState<OfficeLocation[]>([]);
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
  //
  // Each fetch applies (or fails) INDEPENDENTLY. This used to be one
  // Promise.all, which meant a single failing endpoint -- a backend
  // deploy that's a version behind the app, a Render free-tier cold
  // start timing out one request -- rejected the whole batch before
  // any setter ran, and every list in the app just showed empty. That
  // presented as "all our employees and meeting rooms vanished" when
  // the data was sitting safely in the database the entire time.
  const loadOne = async <T,>(path: string, apply: (data: T) => void): Promise<void> => {
    try {
      apply(await apiClient.get<T>(path));
    } catch (err) {
      // Keep whatever we already have for this collection rather than
      // blanking it -- stale beats empty for every screen we render.
      console.warn(`[DataContext] failed to load ${path}`, err);
    }
  };

  const loadAll = async (): Promise<void> => {
    if (!user) return;
    const isManager = user.role === 'manager';
    const appointmentsPath =
      user.role === 'visitor' ? '/api/v1/appointments?mine=true' : '/api/v1/appointments';

    await Promise.all([
      loadOne<VisitorDto[]>('/api/v1/visitors', (v) => setVisitors(v.map(mapVisitor))),
      loadOne<AppointmentDto[]>(appointmentsPath, (a) => setAppointments(a.map(mapAppointment))),
      loadOne<CallDto[]>('/api/v1/calls', (c) => setCalls(c.map(mapCall))),
      loadOne<EmployeeDto[]>('/api/v1/employees', (e) => setEmployees(e.map(mapEmployee))),
      loadOne<MeetingRoom[]>('/api/v1/meeting-rooms', (r) => setMeetingRooms(r)),
      loadOne<ClockRecordDto[]>('/api/v1/clock-records', (cr) =>
        setClockRecords(cr.map(mapClockRecord)),
      ),
      loadOne<RoomBookingDto[]>('/api/v1/room-bookings', (rb) =>
        setRoomBookings(rb.map(mapRoomBooking)),
      ),
      loadOne<PlanDto[]>('/api/v1/plans', (p) => setPlans(p.map(mapPlan))),
      loadOne<OfficeLocation[]>('/api/v1/office-locations', (ol) => setOfficeLocations(ol)),
      ...(isManager
        ? [
            loadOne<BillingDto>('/api/v1/billing', (b) => setBilling(mapBilling(b))),
            loadOne<InvoiceDto[]>('/api/v1/billing/invoices', (inv) =>
              setInvoices(inv.map(mapInvoice)),
            ),
          ]
        : []),
      // Visitors have no employeeId, so there's nothing for them to be
      // notified about (meeting invites only ever target staff).
      ...(user.employeeId
        ? [
            loadOne<NotificationDto[]>('/api/v1/notifications', (n) =>
              setNotifications(n.map(mapNotification)),
            ),
          ]
        : []),
    ]);
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
    loadAll().catch(() => {});
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

  // ---- office locations (clock-in/visitor geofence) ----
  // The first is free on any plan; a second+ requires the enterprise
  // plan (backend 409s with an upgrade message -- see
  // OfficeLocationService, CompanySetupScreen surfaces that message
  // as-is rather than pre-checking the plan client-side).

  const addOfficeLocation = async (input: OfficeLocationInput): Promise<OfficeLocation> => {
    const loc = await apiClient.post<OfficeLocation>('/api/v1/office-locations', input);
    setOfficeLocations((ls) => [...ls, loc]);
    return loc;
  };

  const updateOfficeLocation = async (
    id: string,
    input: OfficeLocationInput,
  ): Promise<OfficeLocation> => {
    const loc = await apiClient.patch<OfficeLocation>(`/api/v1/office-locations/${id}`, input);
    setOfficeLocations((ls) => ls.map((l) => (l.id === id ? loc : l)));
    return loc;
  };

  const removeOfficeLocation = async (id: string): Promise<void> => {
    await apiClient.delete(`/api/v1/office-locations/${id}`);
    setOfficeLocations((ls) => ls.filter((l) => l.id !== id));
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

  // clockIn() only updates the clockRecords ledger, not the employees
  // list -- so a staff member's deviceBound flag (set server-side the
  // moment they first clock in) wouldn't show up here until the next
  // full reload. EmployeeDetailScreen calls this on focus so reopening
  // a profile after a clock-in reflects the real lock state.
  const refreshEmployees = async (): Promise<void> => {
    const es = await apiClient.get<EmployeeDto[]>('/api/v1/employees');
    setEmployees(es.map(mapEmployee));
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
        officeLocations,
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
        addOfficeLocation,
        updateOfficeLocation,
        removeOfficeLocation,
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
        refreshEmployees,
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
Write-File "src\context\DataContext.tsx" $f0
$f1 = @'
import React, { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { apiClient, ApiError } from '../api/client';
import { setToken, clearToken, loadStoredToken } from '../api/tokenStore';
import { saveRememberedLogin, clearRememberedLogin } from '../api/rememberedLogin';
import { useTheme } from '../theme/ThemeContext';
import type { AuthResult, Organization, Role, User } from '../types';

// AuthContext talks to the real VisiLog backend (see server/). Role is
// decided once, server-side, at signup time (by matching the signing-up
// email against the company's staff roster) -- there is no more
// role-picker or employee-ID-verify step on the frontend.

interface UserDto {
  id: string;
  email: string;
  name: string;
  role: string;
  employeeId: string | null;
  organizationId: string;
  organizationName: string;
}

interface AuthResponse {
  token: string;
  user: UserDto;
  organization: Organization;
}

interface OrganizationPatch {
  name?: string;
  logoUrl?: string | null;
  theme?: Organization['theme'];
  wifiNetworkName?: string | null;
}

interface MessageResult {
  ok: boolean;
  message: string;
}

interface AuthContextValue {
  user: User | null;
  organization: Organization | null;
  initializing: boolean;
  login: (
    email: string,
    password: string,
    companyCode: string,
    remember?: boolean,
  ) => Promise<AuthResult>;
  signup: (
    companyCode: string,
    email: string,
    password: string,
    name: string,
  ) => Promise<AuthResult>;
  loginWithGoogle: (companyCode: string, idToken: string) => Promise<AuthResult>;
  forgotPassword: (companyCode: string, email: string) => Promise<MessageResult>;
  resetPassword: (
    companyCode: string,
    email: string,
    code: string,
    newPassword: string,
  ) => Promise<MessageResult>;
  registerCompany: (
    companyName: string,
    adminName: string,
    adminEmail: string,
    adminPassword: string,
  ) => Promise<AuthResult>;
  logout: () => Promise<void>;
  verifyPassword: (password: string) => Promise<{ ok: boolean; error?: string }>;
  updateOrganization: (patch: OrganizationPatch) => Promise<AuthResult>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

// Backend roles are uppercase enum names (VISITOR/RECEPTIONIST/EMPLOYEE/
// MANAGER); every screen in this app was built against lowercase.
const mapUser = (userDto: UserDto): User => ({
  id: userDto.id,
  email: userDto.email,
  name: userDto.name,
  role: userDto.role.toLowerCase() as Role,
  employeeId: userDto.employeeId,
  organizationId: userDto.organizationId,
  organizationName: userDto.organizationName,
});

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null); // null = signed out
  const [organization, setOrganization] = useState<Organization | null>(null);
  // True until a previously-stored session (if any) has been checked
  // against the backend, so RootNavigator can hold the splash screen
  // rather than flash the login screen for a signed-in user.
  const [initializing, setInitializing] = useState(true);
  const { setOrgTheme } = useTheme();

  // Keep the color palette in sync with whichever org is currently
  // signed in -- covers login/signup/registerCompany and boot-restore
  // in one place instead of every screen calling setOrgTheme itself.
  useEffect(() => {
    setOrgTheme(organization ? organization.theme : null);
  }, [organization, setOrgTheme]);

  useEffect(() => {
    (async () => {
      const token = await loadStoredToken();
      if (!token) {
        setInitializing(false);
        return;
      }
      // The backend's free-tier host spins down when idle and takes up
      // to a minute to wake, so the first request after a quiet spell
      // often fails with a network error or 5xx -- NOT because the
      // stored session is bad. Retry through that window, and only
      // clear the token when the server itself rejects it (401/403).
      // Clearing on any failure -- what this used to do -- silently
      // logged people out whenever the app opened against a sleeping
      // backend, which reads as "the app forgot everything".
      for (let attempt = 0; attempt < 4; attempt++) {
        try {
          const [userDto, org] = await Promise.all([
            apiClient.get<UserDto>('/api/v1/auth/me'),
            apiClient.get<Organization>('/api/v1/org'),
          ]);
          setUser(mapUser(userDto));
          setOrganization(org);
          break;
        } catch (err) {
          if (err instanceof ApiError && (err.status === 401 || err.status === 403)) {
            // Genuinely stale/invalid token -- sign out quietly.
            await clearToken();
            break;
          }
          if (attempt < 3) {
            await new Promise((resolve) => setTimeout(resolve, (attempt + 1) * 5000));
          }
          // After the last attempt: keep the token (the backend may
          // just be waking up) and land on Login -- signing in again
          // once it's awake works, and the next app open restores the
          // session normally.
        }
      }
      setInitializing(false);
    })();
  }, []);

  // `persist` (default true) controls whether the token is written to
  // AsyncStorage -- LoginScreen's "Remember me" toggles this. false
  // keeps the token in memory only, so the session doesn't survive an
  // app restart even though it works normally until then.
  const applyAuthResponse = async (res: AuthResponse, persist = true) => {
    await setToken(res.token, persist);
    setUser(mapUser(res.user));
    setOrganization(res.organization);
  };

  // `companyCode` resolves which paying organization (tenant) this
  // login belongs to -- required since VisiLog serves several
  // companies, each with their own data and brand colors.
  const login = async (
    email: string,
    password: string,
    companyCode: string,
    remember = true,
  ): Promise<AuthResult> => {
    if (!email || !password || !companyCode) {
      return { ok: false, error: 'Enter your company code, email and password.' };
    }
    try {
      const res = await apiClient.post<AuthResponse>('/api/v1/auth/login', {
        companyCode: companyCode.trim(),
        email: email.trim(),
        password,
      });
      await applyAuthResponse(res, remember);
      if (remember) {
        await saveRememberedLogin({ companyCode: companyCode.trim(), email: email.trim() });
      } else {
        await clearRememberedLogin();
      }
      return { ok: true, organization: res.organization };
    } catch (err) {
      return { ok: false, error: err instanceof ApiError ? err.message : 'Login failed.' };
    }
  };

  // Creates a login account under an existing company. Role is decided
  // server-side: matches `email` against the company's staff roster
  // (that role) or falls back to visitor if there's no match.
  const signup = async (
    companyCode: string,
    email: string,
    password: string,
    name: string,
  ): Promise<AuthResult> => {
    if (!companyCode || !email || !password || !name) {
      return { ok: false, error: 'Please fill in every field above.' };
    }
    try {
      const res = await apiClient.post<AuthResponse>('/api/v1/auth/signup', {
        companyCode: companyCode.trim(),
        email: email.trim(),
        password,
        name: name.trim(),
      });
      await applyAuthResponse(res);
      return { ok: true, organization: res.organization };
    } catch (err) {
      return { ok: false, error: err instanceof ApiError ? err.message : 'Signup failed.' };
    }
  };

  // Self-serve "sign your company up" -- creates the Organization, its
  // first Administrator (Manager) account, and hands back a company
  // code the admin can then share with their staff/visitors.
  const registerCompany = async (
    companyName: string,
    adminName: string,
    adminEmail: string,
    adminPassword: string,
  ): Promise<AuthResult> => {
    if (!companyName || !adminName || !adminEmail || !adminPassword) {
      return { ok: false, error: 'Please fill in every field above.' };
    }
    try {
      const res = await apiClient.post<AuthResponse>('/api/v1/companies/register', {
        companyName: companyName.trim(),
        adminName: adminName.trim(),
        adminEmail: adminEmail.trim(),
        adminPassword,
      });
      await applyAuthResponse(res);
      return { ok: true, organization: res.organization };
    } catch (err) {
      return {
        ok: false,
        error: err instanceof ApiError ? err.message : 'Could not register your company.',
      };
    }
  };

  // Google sign-in. The frontend never sees or checks the ID token
  // itself -- it hands the raw token Google issued straight to the
  // backend, which verifies it against Google's own servers (see
  // GoogleTokenService) before trusting anything in it. Same as
  // signup, an existing account for that email logs straight in; a new
  // one gets its role resolved from the staff roster.
  const loginWithGoogle = async (companyCode: string, idToken: string): Promise<AuthResult> => {
    if (!companyCode || !idToken) {
      return { ok: false, error: 'Enter your company code first.' };
    }
    try {
      const res = await apiClient.post<AuthResponse>('/api/v1/auth/google', {
        companyCode: companyCode.trim(),
        idToken,
      });
      await applyAuthResponse(res);
      return { ok: true, organization: res.organization };
    } catch (err) {
      return { ok: false, error: err instanceof ApiError ? err.message : 'Google sign-in failed.' };
    }
  };

  // Forgot Password: request a numeric reset code by email, then submit
  // it alongside a new password. Neither call touches the signed-in
  // session -- both work from the signed-out Login screen.
  const forgotPassword = async (companyCode: string, email: string): Promise<MessageResult> => {
    try {
      const res = await apiClient.post<{ message: string }>('/api/v1/auth/forgot-password', {
        companyCode: companyCode.trim(),
        email: email.trim(),
      });
      return { ok: true, message: res.message };
    } catch (err) {
      return {
        ok: false,
        message: err instanceof ApiError ? err.message : 'Could not send a reset code.',
      };
    }
  };

  const resetPassword = async (
    companyCode: string,
    email: string,
    code: string,
    newPassword: string,
  ): Promise<MessageResult> => {
    try {
      const res = await apiClient.post<{ message: string }>('/api/v1/auth/reset-password', {
        companyCode: companyCode.trim(),
        email: email.trim(),
        code: code.trim(),
        newPassword,
      });
      return { ok: true, message: res.message };
    } catch (err) {
      return {
        ok: false,
        message: err instanceof ApiError ? err.message : 'Could not reset your password.',
      };
    }
  };

  // Step-up confirmation before a sensitive action on the *current*
  // session -- currently just clock-in (see ClockCard). Re-checks the
  // signed-in user's own password without touching the stored token.
  const verifyPassword = async (password: string): Promise<{ ok: boolean; error?: string }> => {
    try {
      await apiClient.post('/api/v1/auth/verify-password', { password });
      return { ok: true };
    } catch (err) {
      return {
        ok: false,
        error: err instanceof ApiError ? err.message : 'Could not verify your password.',
      };
    }
  };

  const logout = async (): Promise<void> => {
    await clearToken();
    setUser(null);
    setOrganization(null);
  };

  // Company Setup > branding (manager only). `theme`, if present, is
  // sent as a whole object -- see UpdateOrgRequest on the backend.
  const updateOrganization = async (patch: OrganizationPatch): Promise<AuthResult> => {
    try {
      const org = await apiClient.patch<Organization>('/api/v1/org', patch);
      setOrganization(org);
      return { ok: true, organization: org };
    } catch (err) {
      return {
        ok: false,
        error: err instanceof ApiError ? err.message : 'Could not save your changes.',
      };
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        organization,
        initializing,
        login,
        signup,
        loginWithGoogle,
        registerCompany,
        logout,
        verifyPassword,
        forgotPassword,
        resetPassword,
        updateOrganization,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = (): AuthContextValue => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider');
  return ctx;
};

'@
Write-File "src\context\AuthContext.tsx" $f1
$f2 = @'
import React, { useState } from 'react';
import { View, Image, StyleSheet, Alert, Pressable, Share } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import * as Location from 'expo-location';
import { Screen, Header, Text, Card, Button, Input } from '../components';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { fonts } from '../theme/typography';
import { useAuth } from '../context/AuthContext';
import { useData } from '../context/DataContext';
import { ApiError } from '../api/client';
import type { RootStackNavigation } from '../types/navigation';
import type { BrandTheme, IoniconName, OfficeLocation } from '../types';

interface CompanySetupScreenProps {
  navigation: RootStackNavigation;
}

// A handful of ready-made brand palettes, so a manager can restyle the
// app without needing a full color-picker UI.
const THEME_PRESETS: { id: string; label: string; theme: BrandTheme }[] = [
  {
    id: 'emerald',
    label: 'Emerald & gold',
    theme: {
      brand: '#0F3D2A',
      brandDark: '#0A2A1D',
      brandTint: '#155636',
      primary: '#C9A227',
      primaryPressed: '#D4AF37',
      primarySurface: '#FBF3DE',
      primarySurfaceStrong: '#F5E6BC',
    },
  },
  {
    id: 'navy',
    label: 'Navy & sky',
    theme: {
      brand: '#1B2A4A',
      brandDark: '#101A30',
      brandTint: '#25396B',
      primary: '#4F8EF7',
      primaryPressed: '#3B76DD',
      primarySurface: '#EAF1FE',
      primarySurfaceStrong: '#D3E3FD',
    },
  },
  {
    id: 'wine',
    label: 'Wine & gold',
    theme: {
      brand: '#5C1A1A',
      brandDark: '#3D1010',
      brandTint: '#7A2626',
      primary: '#E0A62B',
      primaryPressed: '#C48F20',
      primarySurface: '#FDF3DF',
      primarySurfaceStrong: '#F8E4B8',
    },
  },
  {
    id: 'plum',
    label: 'Plum & rose',
    theme: {
      brand: '#3B1D4A',
      brandDark: '#28132F',
      brandTint: '#512A66',
      primary: '#E0679F',
      primaryPressed: '#C74F86',
      primarySurface: '#FCEAF3',
      primarySurfaceStrong: '#F7D2E5',
    },
  },
];

// CompanySetupScreen -- Manager/Administrator only, reachable from
// Settings > Organisation > "Company branding". Covers everything the
// self-serve onboarding story needs after registration: sharing the
// company code, branding, and the office location that backs the
// clock-in geofence check. Staff roster (Directory) and meeting rooms
// each have their own dedicated screens, linked from here.
export default function CompanySetupScreen({ navigation }: CompanySetupScreenProps) {
  const { colors } = useTheme();
  const { organization, updateOrganization } = useAuth();
  const { officeLocations, addOfficeLocation, updateOfficeLocation, removeOfficeLocation } =
    useData();

  const [name, setName] = useState(organization?.name || '');
  const [logoUrl, setLogoUrl] = useState(organization?.logoUrl || '');
  const [wifiNetworkName, setWifiNetworkName] = useState(organization?.wifiNetworkName || '');
  const [savingBrand, setSavingBrand] = useState(false);
  const [pickingLogo, setPickingLogo] = useState(false);

  const onPickLogo = async () => {
    const perm = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (!perm.granted) {
      Alert.alert('Permission needed', 'Allow photo library access to upload a logo.');
      return;
    }
    setPickingLogo(true);
    try {
      const result = await ImagePicker.launchImageLibraryAsync({
        mediaTypes: ['images'],
        allowsEditing: true,
        aspect: [1, 1],
        quality: 0.6,
        base64: true,
      });
      if (result.canceled) return;
      const asset = result.assets[0];
      if (!asset.base64) {
        Alert.alert('Could not read image', 'Please try a different photo.');
        return;
      }
      setLogoUrl(`data:${asset.mimeType || 'image/jpeg'};base64,${asset.base64}`);
    } finally {
      setPickingLogo(false);
    }
  };

  // Office locations -- an org can have more than one (see
  // DataContext.officeLocations); `editingId` is null while adding a
  // new one, or an existing location's id while editing it. The
  // backend allows one free on any plan and 409s with an upgrade
  // message on a second, which onSaveLocation surfaces as-is rather
  // than pre-checking the plan here.
  const [formOpen, setFormOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [locName, setLocName] = useState('');
  const [latitude, setLatitude] = useState('');
  const [longitude, setLongitude] = useState('');
  const [radiusMeters, setRadiusMeters] = useState('500');
  const [savingLocation, setSavingLocation] = useState(false);
  const [locating, setLocating] = useState(false);

  const onStartAddLocation = () => {
    setEditingId(null);
    setLocName('');
    setLatitude('');
    setLongitude('');
    setRadiusMeters('500');
    setFormOpen(true);
  };

  const onStartEditLocation = (loc: OfficeLocation) => {
    setEditingId(loc.id);
    setLocName(loc.name);
    setLatitude(String(loc.latitude));
    setLongitude(String(loc.longitude));
    setRadiusMeters(String(loc.radiusMeters));
    setFormOpen(true);
  };

  // Fills lat/lng from the phone's own GPS instead of making someone
  // look up coordinates manually -- stand at the office and tap this.
  const onUseCurrentLocation = async () => {
    setLocating(true);
    try {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Permission needed', 'Allow location access to use your current position.');
        return;
      }
      const position = await Location.getCurrentPositionAsync({
        accuracy: Location.Accuracy.Balanced,
      });
      setLatitude(String(position.coords.latitude));
      setLongitude(String(position.coords.longitude));
    } catch {
      Alert.alert('Could not get location', 'Enable location services and try again.');
    } finally {
      setLocating(false);
    }
  };

  const onShareCode = () => {
    Share.share({
      message: `Join ${organization?.name} on VisiLog. Company code: ${organization?.code}`,
    }).catch(() => {});
  };

  const onSaveBrand = async () => {
    if (!name.trim()) {
      Alert.alert('Almost there', 'Give your company a name.');
      return;
    }
    setSavingBrand(true);
    const result = await updateOrganization({
      name: name.trim(),
      logoUrl: logoUrl.trim() || null,
      wifiNetworkName: wifiNetworkName.trim() || null,
    });
    setSavingBrand(false);
    if (!result.ok) Alert.alert('Could not save', result.error);
  };

  const onPickPreset = async (preset: (typeof THEME_PRESETS)[number]) => {
    setSavingBrand(true);
    const result = await updateOrganization({ theme: preset.theme });
    setSavingBrand(false);
    if (!result.ok) Alert.alert('Could not save', result.error);
  };

  const onSaveLocation = async () => {
    if (!locName.trim()) {
      Alert.alert('Almost there', 'Give this location a name (e.g. "Head Office").');
      return;
    }
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const radius = parseInt(radiusMeters, 10) || 500;
    if (Number.isNaN(lat) || Number.isNaN(lng)) {
      Alert.alert(
        'Almost there',
        'Tap "Use my current location" while standing at that office first.',
      );
      return;
    }
    setSavingLocation(true);
    try {
      const input = { name: locName.trim(), latitude: lat, longitude: lng, radiusMeters: radius };
      if (editingId) {
        await updateOfficeLocation(editingId, input);
      } else {
        await addOfficeLocation(input);
      }
      setFormOpen(false);
      Alert.alert('Saved', 'Staff will need to be within range of this location to clock in.');
    } catch (err) {
      Alert.alert(
        'Could not save',
        err instanceof ApiError ? err.message : 'Something went wrong.',
      );
    } finally {
      setSavingLocation(false);
    }
  };

  const onRemoveLocation = (loc: OfficeLocation) => {
    Alert.alert(
      'Remove this location?',
      `Staff will no longer be able to clock in at ${loc.name}.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: () =>
            removeOfficeLocation(loc.id).catch((err) =>
              Alert.alert(
                'Could not remove location',
                err instanceof ApiError ? err.message : 'Something went wrong.',
              ),
            ),
        },
      ],
    );
  };

  return (
    <Screen>
      <Header
        title="Company Setup"
        subtitle="Branding, office location, staff & rooms"
        rightIcon="close"
        onRightPress={() => navigation.goBack()}
      />

      {/* Company code */}
      <Card accent="info">
        <Text variant="caption" color={colors.textSecondary}>
          Company code
        </Text>
        <View style={styles.codeRow}>
          <Text style={[styles.code, { color: colors.brand }]}>{organization?.code}</Text>
          <Pressable
            onPress={onShareCode}
            style={[styles.shareBtn, { backgroundColor: colors.primarySurface }]}
          >
            <Ionicons name="share-outline" size={16} color={colors.primary} />
            <Text variant="caption" color={colors.brand} style={{ marginLeft: 4 }}>
              Share
            </Text>
          </Pressable>
        </View>
        <Text variant="caption" color={colors.textMuted}>
          Give this to your staff and post it wherever you invite visitors -- they enter it when
          they sign up.
        </Text>
      </Card>

      {/* Branding */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Branding
      </Text>
      <Card>
        <Input label="Company name" value={name} onChangeText={setName} icon="business-outline" />

        <Text variant="label" color={colors.textSecondary} style={styles.logoLabel}>
          Logo
        </Text>
        <Pressable onPress={onPickLogo} disabled={pickingLogo} style={styles.logoRow}>
          <View
            style={[
              styles.logoPreview,
              { borderColor: colors.border, backgroundColor: colors.surfaceAlt },
            ]}
          >
            {logoUrl ? (
              <Image source={{ uri: logoUrl }} style={styles.logoImage} resizeMode="cover" />
            ) : (
              <Ionicons name="image-outline" size={22} color={colors.textMuted} />
            )}
          </View>
          <View style={{ flex: 1, marginLeft: spacing.sm }}>
            <Text variant="bodySemibold" color={colors.brand}>
              {pickingLogo ? 'Opening photos...' : logoUrl ? 'Change logo' : 'Upload a logo'}
            </Text>
            <Text variant="caption" color={colors.textMuted}>
              From your device's photo library
            </Text>
          </View>
        </Pressable>

        <Input
          label="...or paste a logo URL"
          value={logoUrl}
          onChangeText={setLogoUrl}
          placeholder="https://..."
          icon="link-outline"
          autoCapitalize="none"
        />
        <Input
          label="WiFi network name"
          value={wifiNetworkName}
          onChangeText={setWifiNetworkName}
          placeholder="e.g. Office-WiFi"
          icon="wifi-outline"
        />
        <Text
          variant="caption"
          color={colors.textMuted}
          style={{ marginTop: -6, marginBottom: spacing.sm }}
        >
          Shown to staff as a reminder of which network to join before clocking in.
        </Text>
        <Button
          label={savingBrand ? 'Saving...' : 'Save'}
          onPress={onSaveBrand}
          disabled={savingBrand}
        />
      </Card>

      <Card style={{ marginTop: spacing.sm }}>
        <Text variant="bodySemibold" style={{ marginBottom: spacing.sm }}>
          Color theme
        </Text>
        <View style={styles.presetGrid}>
          {THEME_PRESETS.map((p) => (
            <Pressable key={p.id} onPress={() => onPickPreset(p)} style={styles.presetItem}>
              <View style={styles.presetSwatches}>
                <View style={[styles.swatch, { backgroundColor: p.theme.brand }]} />
                <View style={[styles.swatch, { backgroundColor: p.theme.primary }]} />
              </View>
              <Text variant="caption" color={colors.textSecondary}>
                {p.label}
              </Text>
            </Pressable>
          ))}
        </View>
      </Card>

      {/* Office locations -- the first is free on any plan; a second+
          requires the enterprise plan (see onSaveLocation, which just
          surfaces the backend's upgrade message if it's rejected). */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Office locations
      </Text>
      <Card padded={false}>
        {officeLocations.length === 0 ? (
          <View style={{ padding: spacing.md }}>
            <Text variant="caption" color={colors.textSecondary}>
              No locations set yet. Staff can clock in from anywhere until you add one.
            </Text>
          </View>
        ) : (
          officeLocations.map((loc, i) => (
            <View key={loc.id}>
              <View style={styles.linkRow}>
                <View style={[styles.linkIcon, { backgroundColor: colors.surfaceAlt }]}>
                  <Ionicons name="location-outline" size={18} color={colors.brand} />
                </View>
                <View style={{ flex: 1 }}>
                  <Text variant="bodySemibold">{loc.name}</Text>
                  <Text variant="caption" color={colors.textSecondary}>
                    {loc.radiusMeters}m radius
                  </Text>
                </View>
                <Pressable onPress={() => onStartEditLocation(loc)} style={{ padding: 6 }}>
                  <Ionicons name="create-outline" size={20} color={colors.textMuted} />
                </Pressable>
                <Pressable onPress={() => onRemoveLocation(loc)} style={{ padding: 6 }}>
                  <Ionicons name="trash-outline" size={20} color={colors.status.rejected.solid} />
                </Pressable>
              </View>
              {i < officeLocations.length - 1 && (
                <View style={[styles.divider, { backgroundColor: colors.border }]} />
              )}
            </View>
          ))
        )}
      </Card>

      {!formOpen && (
        <Button
          label="Add office location"
          icon="add-circle-outline"
          variant="secondary"
          onPress={onStartAddLocation}
          style={{ marginTop: spacing.sm }}
        />
      )}

      {formOpen && (
        <Card style={{ marginTop: spacing.sm }}>
          <Text variant="bodySemibold" style={{ marginBottom: spacing.sm }}>
            {editingId ? 'Edit location' : 'New location'}
          </Text>
          <Input
            label="Name"
            value={locName}
            onChangeText={setLocName}
            placeholder="e.g. Head Office"
            icon="business-outline"
          />
          <Button
            label={locating ? 'Getting your location...' : 'Use my current location'}
            icon="locate"
            variant="secondary"
            onPress={onUseCurrentLocation}
            disabled={locating}
            style={{ marginBottom: spacing.md }}
          />
          <View style={[styles.locationStatus, { backgroundColor: colors.surfaceAlt }]}>
            <Ionicons
              name={
                latitude.trim() && longitude.trim() ? 'checkmark-circle' : 'alert-circle-outline'
              }
              size={18}
              color={latitude.trim() && longitude.trim() ? colors.primary : colors.textMuted}
            />
            <Text variant="bodyMd" color={colors.textSecondary} style={{ marginLeft: 8 }}>
              {latitude.trim() && longitude.trim() ? 'Location set' : 'No location set yet'}
            </Text>
          </View>
          <Input
            label="Radius (meters)"
            value={radiusMeters}
            onChangeText={setRadiusMeters}
            placeholder="e.g. 500"
            icon="radio-outline"
            keyboardType="number-pad"
          />
          <View style={{ flexDirection: 'row' }}>
            <Button
              label="Cancel"
              variant="ghost"
              onPress={() => setFormOpen(false)}
              style={{ flex: 1, marginRight: spacing.xs }}
            />
            <Button
              label={savingLocation ? 'Saving...' : 'Save'}
              onPress={onSaveLocation}
              disabled={savingLocation}
              style={{ flex: 1, marginLeft: spacing.xs }}
            />
          </View>
        </Card>
      )}

      {/* Staff & rooms */}
      <Text variant="eyebrow" color={colors.textMuted} style={styles.eyebrow}>
        Staff & rooms
      </Text>
      <Card padded={false}>
        <LinkRow
          icon="people-outline"
          title="Staff roster"
          sub="Add employees & set their roles"
          onPress={() => navigation.navigate('Directory')}
        />
        <View style={[styles.divider, { backgroundColor: colors.border }]} />
        <LinkRow
          icon="business-outline"
          title="Meeting rooms"
          sub="Add or remove bookable rooms"
          onPress={() => navigation.navigate('MeetingRooms')}
        />
        <View style={[styles.divider, { backgroundColor: colors.border }]} />
        <LinkRow
          icon="document-text-outline"
          title="Legal agreement"
          sub="The subscription terms your company agreed to"
          onPress={() => navigation.navigate('LegalAgreement')}
        />
      </Card>
    </Screen>
  );
}

function LinkRow({
  icon,
  title,
  sub,
  onPress,
}: {
  icon: IoniconName;
  title: string;
  sub: string;
  onPress: () => void;
}) {
  const { colors } = useTheme();
  return (
    <Pressable style={styles.linkRow} onPress={onPress}>
      <View style={[styles.linkIcon, { backgroundColor: colors.surfaceAlt }]}>
        <Ionicons name={icon} size={18} color={colors.brand} />
      </View>
      <View style={{ flex: 1 }}>
        <Text variant="bodySemibold">{title}</Text>
        <Text variant="caption" color={colors.textSecondary}>
          {sub}
        </Text>
      </View>
      <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  eyebrow: { marginTop: spacing.xl, marginBottom: spacing.sm },
  logoLabel: { marginBottom: 6 },
  logoRow: { flexDirection: 'row', alignItems: 'center', marginBottom: spacing.md },
  logoPreview: {
    width: 56,
    height: 56,
    borderRadius: radius.md,
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  logoImage: { width: '100%', height: '100%' },
  codeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginVertical: 4,
  },
  // fontFamily, never fontWeight: Android can't synthesize a bold face
  // for a loaded custom font -- a bare fontWeight here silently swaps
  // the whole run of text to the system font instead.
  code: { fontSize: 22, fontFamily: fonts.displayBold, letterSpacing: 1 },
  shareBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.sm,
    paddingVertical: 6,
    borderRadius: radius.pill,
  },
  presetGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.md },
  presetItem: { alignItems: 'center', width: 70 },
  presetSwatches: { flexDirection: 'row', marginBottom: 4 },
  swatch: {
    width: 22,
    height: 22,
    borderRadius: 11,
    marginHorizontal: -4,
    borderWidth: 2,
    borderColor: '#fff',
  },
  linkRow: { flexDirection: 'row', alignItems: 'center', padding: spacing.md },
  linkIcon: {
    width: 32,
    height: 32,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing.sm,
  },
  divider: { height: 1, marginLeft: spacing.md + 32 + spacing.sm },
  locationStatus: {
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: radius.md,
    padding: spacing.sm,
    marginBottom: spacing.sm,
  },
});

'@
Write-File "src\screens\CompanySetupScreen.tsx" $f2

Write-Host "--- Files written, verifying ---"
$paths = @(
    "src\context\DataContext.tsx",
    "src\context\AuthContext.tsx",
    "src\screens\CompanySetupScreen.tsx"
)
foreach ($p in $paths) {
    $full = Join-Path $PSScriptRoot $p
    if (Test-Path $full) { Write-Host "OK   $p" } else { Write-Host "MISSING   $p" }
}

Stop-Transcript | Out-Null
Write-Host ""
Write-Host "Done. Now run: npx tsc --noEmit"
