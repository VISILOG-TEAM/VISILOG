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
import { syncLocalReminders, type ReminderItem } from '../data/pushNotifications';
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
  WifiNetwork,
  WifiNetworkInput,
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
  roomBookings: RoomBooking[];
  employees: Employee[];
  meetingRooms: MeetingRoom[];
  officeLocations: OfficeLocation[];
  wifiNetworks: WifiNetwork[];
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
  admitAppointment: (appointment: Appointment) => Promise<Appointment>;
  checkInAppointment: (appointmentId: string) => Promise<Appointment>;
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
  addWifiNetwork: (input: WifiNetworkInput) => Promise<WifiNetwork>;
  updateWifiNetwork: (id: string, input: WifiNetworkInput) => Promise<WifiNetwork>;
  removeWifiNetwork: (id: string) => Promise<void>;
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
  rescheduleMeeting: (
    id: string,
    newStartTime: string,
    newEndTime: string,
    reason?: string,
  ) => Promise<RoomBooking>;
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
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [meetingRooms, setMeetingRooms] = useState<MeetingRoom[]>([]);
  const [officeLocations, setOfficeLocations] = useState<OfficeLocation[]>([]);
  const [wifiNetworks, setWifiNetworks] = useState<WifiNetwork[]>([]);
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
    // An account that hasn't confirmed its email yet holds a token the
    // backend refuses everywhere but the verify endpoints, so firing
    // these off would just log a dozen 403s for no benefit -- it can't
    // see any of this data until it's through VerifyEmailScreen.
    if (!user || !user.emailVerified) return;
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
      loadOne<WifiNetwork[]>('/api/v1/wifi-networks', (wn) => setWifiNetworks(wn)),
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

  // Keeps on-device "30 minutes before" reminders in sync with this
  // user's own upcoming appointments/meetings every time either list
  // refreshes -- not just visitor's own visits (appointments is already
  // scoped that way per-role, see loadAll), but also filtered down to
  // "am I the host" / "am I organiser or an invited participant who
  // hasn't declined" for Receptionist/Manager, whose appointments and
  // roomBookings lists otherwise include the whole org's, not just
  // theirs to be reminded about. See syncLocalReminders.
  useEffect(() => {
    if (!user) return;
    const items: ReminderItem[] = [];
    for (const a of appointments) {
      const isMine = user.role === 'visitor' ? true : a.hostId === user.employeeId;
      if (isMine && a.status === 'admitted') {
        items.push({
          id: `appointment-${a.id}`,
          title: 'Upcoming visit',
          body: `${a.visitorName} - starting soon`,
          whenISO: a.scheduledAt,
        });
      }
    }
    if (user.employeeId) {
      for (const b of roomBookings) {
        const myResponse = b.responses.find((r) => r.employeeId === user.employeeId);
        const isMine = b.organiserId === user.employeeId || b.participantIds.includes(user.employeeId);
        if (isMine && myResponse?.status !== 'declined') {
          items.push({
            id: `meeting-${b.id}`,
            title: 'Upcoming meeting',
            body: `${b.title} - starting soon`,
            whenISO: b.startTime,
          });
        }
      }
    }
    syncLocalReminders(items).catch(() => {});
  }, [appointments, roomBookings, user]);

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

  // Admit = approve the visit. Visitor is not yet on-site; reception
  // checks them in physically when they arrive (see checkInAppointment).
  const admitAppointment = async (appointment: Appointment): Promise<Appointment> => {
    const apptDto = await apiClient.post<AppointmentDto>(
      `/api/v1/appointments/${appointment.id}/admit`,
    );
    const updated = mapAppointment(apptDto);
    setAppointments((as) => as.map((a) => (a.id === updated.id ? updated : a)));
    return updated;
  };

  // Check-in = visitor physically arrives. Creates the Visitor on-site
  // record and marks the appointment as checked-in.
  const checkInAppointment = async (appointmentId: string): Promise<Appointment> => {
    const apptDto = await apiClient.post<AppointmentDto>(
      `/api/v1/appointments/${appointmentId}/check-in`,
    );
    const updated = mapAppointment(apptDto);
    setAppointments((as) => as.map((a) => (a.id === updated.id ? updated : a)));
    // Refetch visitors so the new on-site visitor shows up everywhere.
    apiClient.get<VisitorDto[]>('/api/v1/visitors').then((dtos) =>
      setVisitors(dtos.map(mapVisitor)),
    ).catch(() => {});
    return updated;
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

  // ---- WiFi networks (shown to staff as "connect to X to clock in") ----

  const addWifiNetwork = async (input: WifiNetworkInput): Promise<WifiNetwork> => {
    const network = await apiClient.post<WifiNetwork>('/api/v1/wifi-networks', input);
    setWifiNetworks((ns) => [...ns, network]);
    return network;
  };

  const updateWifiNetwork = async (id: string, input: WifiNetworkInput): Promise<WifiNetwork> => {
    const network = await apiClient.patch<WifiNetwork>(`/api/v1/wifi-networks/${id}`, input);
    setWifiNetworks((ns) => ns.map((n) => (n.id === id ? network : n)));
    return network;
  };

  const removeWifiNetwork = async (id: string): Promise<void> => {
    await apiClient.delete(`/api/v1/wifi-networks/${id}`);
    setWifiNetworks((ns) => ns.filter((n) => n.id !== id));
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

  const rescheduleMeeting = async (
    id: string,
    newStartTime: string,
    newEndTime: string,
    reason?: string,
  ): Promise<RoomBooking> => {
    const dto = await apiClient.patch<RoomBookingDto>(`/api/v1/room-bookings/${id}/reschedule`, {
      newStartTime,
      newEndTime,
      reason: reason || '',
    });
    const updated = mapRoomBooking(dto);
    setRoomBookings((rs) => rs.map((b) => (b.id === id ? updated : b)));
    return updated;
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
        roomBookings,
        employees,
        meetingRooms,
        officeLocations,
        wifiNetworks,
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
        checkInAppointment,
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
        addWifiNetwork,
        updateWifiNetwork,
        removeWifiNetwork,
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
        rescheduleMeeting,
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
