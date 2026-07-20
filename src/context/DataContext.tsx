import React, { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { apiClient } from '../api/client';
import { useAuth } from './AuthContext';
import type {
  Appointment, AppointmentStatus, AppNotification, Billing, BookRoomInput, BookVisitInput, Call,
  ClockRecord, ClockType, Employee, EmployeeInput, Invoice, LogCallInput, MeetingRoom,
  MeetingRoomInput, NfcCard, NotificationType, Plan, RegisterVisitorInput, Role, RoomBooking,
  Visitor, VisitorStatus,
} from '../types';

// DataContext talks to the real VisiLog backend (see server/). Every
// collection below is fetched for the signed-in user's own organization
// (the backend derives that from the JWT, never from anything we send)
// and kept in local state, updated from each mutation's response so the
// UI doesn't need a full refetch after every action.
//
// Backend enums come back as UPPERCASE strings (VisitorStatus, Role,
// etc.) — every screen in this app was built against the mock data's
// lowercase/Capitalized casing, so the map* helpers below normalize at
// the boundary and every screen keeps working unchanged.

// ---- raw backend DTO shapes (UPPERCASE enums, as they arrive on the wire) ----

interface VisitorDto extends Omit<Visitor, 'status'> { status: string; }
interface AppointmentDto extends Omit<Appointment, 'status'> { status: string; }
interface CallDto extends Omit<Call, 'callType'> { callType: string; }
interface EmployeeDto {
  id: string; employeeCode: string; name: string;
  department?: string | null; phone?: string | null; email?: string | null; role: string;
}
interface ClockRecordDto extends Omit<ClockRecord, 'type'> { type: string; }
interface RoomBookingDto extends Omit<RoomBooking, 'location' | 'participantIds'> {
  location?: string | null; participantIds?: string[] | null;
}
interface PlanDto extends Omit<Plan, 'price'> { price: string | number; }
interface NotificationDto extends Omit<AppNotification, 'type'> { type: string; }
interface BillingDto {
  plan: PlanDto; status: string; seatsUsed: number; renewalDate: string; paymentLast4: string | null;
}
interface InvoiceDto extends Omit<Invoice, 'amount' | 'status'> { amount: string | number; status: string; }

const cap = (s: string): string => (s ? s.charAt(0) + s.slice(1).toLowerCase() : s);

const mapVisitor = (d: VisitorDto): Visitor => ({ ...d, status: d.status.toLowerCase() as VisitorStatus });
const mapAppointment = (d: AppointmentDto): Appointment => (
  { ...d, status: d.status.toLowerCase() as AppointmentStatus }
);
const mapCall = (d: CallDto): Call => ({ ...d, callType: cap(d.callType) as Call['callType'] });
const mapEmployee = (d: EmployeeDto): Employee => ({
  id: d.id,
  employeeId: d.employeeCode,
  name: d.name,
  department: d.department || '',
  phone: d.phone || '',
  email: d.email || '',
  role: d.role.toLowerCase() as Role,
});
const mapClockRecord = (d: ClockRecordDto): ClockRecord => ({ ...d, type: d.type.toLowerCase() as ClockType });
const mapRoomBooking = (d: RoomBookingDto): RoomBooking => (
  { ...d, location: d.location || '', participantIds: d.participantIds || [] }
);
const mapPlan = (d: PlanDto): Plan => ({ ...d, price: Number(d.price) });
const mapBilling = (d: BillingDto): Billing => ({
  planId: d.plan.id,
  status: d.status.toLowerCase() as Billing['status'],
  seatsUsed: d.seatsUsed,
  renewalDate: d.renewalDate,
  paymentLast4: d.paymentLast4,
});
const mapInvoice = (d: InvoiceDto): Invoice => (
  { ...d, amount: Number(d.amount), status: d.status.toLowerCase() as Invoice['status'] }
);
const mapNotification = (d: NotificationDto): AppNotification => (
  { ...d, type: d.type.toLowerCase() as NotificationType }
);

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
  // operations
  registerAndCheckIn: (input: RegisterVisitorInput) => Promise<Visitor>;
  checkOutVisitor: (visitorId: string, notes?: string) => Promise<Visitor>;
  updateAppointmentStatus: (id: string, status: AppointmentStatus) => Promise<Appointment>;
  admitAppointment: (appointment: Appointment) => Promise<Visitor>;
  logCall: (input: LogCallInput) => Promise<Call>;
  addEmployee: (input: EmployeeInput) => Promise<Employee>;
  updateEmployee: (id: string, input: EmployeeInput) => Promise<Employee>;
  removeEmployee: (id: string) => Promise<void>;
  addMeetingRoom: (input: MeetingRoomInput) => Promise<MeetingRoom>;
  updateMeetingRoom: (id: string, input: MeetingRoomInput) => Promise<MeetingRoom>;
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
  rescheduleAppointment: (id: string, newScheduledAt: string, reason?: string) => Promise<Appointment>;
  // self-service room booking
  bookRoom: (input: BookRoomInput) => Promise<RoomBooking>;
  refreshRoomBookings: () => Promise<void>;
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
  // No backend model for standalone NFC cards in this pass — the
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

  // Load every collection once a user is signed in. Billing/invoices
  // are manager-only on the backend, so non-managers skip those calls
  // entirely rather than getting a 403.
  useEffect(() => {
    if (!user) {
      setVisitors([]); setAppointments([]); setCalls([]); setEmployees([]);
      setMeetingRooms([]); setClockRecords([]); setRoomBookings([]);
      setBilling(null); setInvoices([]); setPlans([]); setNotifications([]);
      return;
    }
    const isManager = user.role === 'manager';
    const appointmentsPath = user.role === 'visitor' ? '/api/v1/appointments?mine=true' : '/api/v1/appointments';

    (async () => {
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
    })();
  }, [user?.id]);

  // ---- lookup helpers ----
  const employeeById = (id: string) => employees.find((e) => e.id === id);
  const roomById = (id: string) => meetingRooms.find((r) => r.id === id);

  // ---- visitor operations ----

  const registerAndCheckIn = async (input: RegisterVisitorInput): Promise<Visitor> => {
    const dto = await apiClient.post<VisitorDto>('/api/v1/visitors', {
      firstName: input.firstName, lastName: input.lastName, phone: input.phone, email: input.email,
      company: input.company, purpose: input.purpose, hostId: input.hostId, notes: input.notes,
    });
    const visitor = mapVisitor(dto);
    setVisitors((vs) => [visitor, ...vs]);
    return visitor;
  };

  const checkOutVisitor = async (visitorId: string, notes = ''): Promise<Visitor> => {
    const dto = await apiClient.patch<VisitorDto>(`/api/v1/visitors/${visitorId}/check-out`, { notes });
    const visitor = mapVisitor(dto);
    setVisitors((vs) => vs.map((v) => (v.id === visitorId ? visitor : v)));
    return visitor;
  };

  // ---- appointment operations ----

  const bookVisit = async (input: BookVisitInput): Promise<Appointment> => {
    const dto = await apiClient.post<AppointmentDto>('/api/v1/appointments', {
      visitorName: input.visitorName, visitorPhone: input.visitorPhone, visitorEmail: input.visitorEmail,
      visitorCompany: input.visitorCompany, purpose: input.purpose, hostId: input.hostId,
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
      const dto = await apiClient.get<AppointmentDto>(`/api/v1/appointments/by-code/${encodeURIComponent(clean)}`);
      return mapAppointment(dto);
    } catch {
      return null;
    }
  };

  const updateAppointmentStatus = async (id: string, status: AppointmentStatus): Promise<Appointment> => {
    const dto = await apiClient.patch<AppointmentDto>(`/api/v1/appointments/${id}/status`, { status });
    const appointment = mapAppointment(dto);
    setAppointments((as) => as.map((a) => (a.id === id ? appointment : a)));
    return appointment;
  };

  // Admitting also registers + checks in the visitor server-side. The
  // admit response is only the updated appointment, so we refetch the
  // visitor list (newest-first) and hand back that just-created record.
  const admitAppointment = async (appointment: Appointment): Promise<Visitor> => {
    const apptDto = await apiClient.post<AppointmentDto>(`/api/v1/appointments/${appointment.id}/admit`);
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
      callerName: input.callerName, callerPhone: input.callerPhone, hostId: input.hostId,
      callType: input.callType, purpose: input.purpose,
      durationMinutes: Number(input.durationMinutes) || 0, notes: input.notes,
    });
    const call = mapCall(dto);
    setCalls((cs) => [call, ...cs]);
    return call;
  };

  // ---- directory (staff roster) operations — manager only ----

  const addEmployee = async (input: EmployeeInput): Promise<Employee> => {
    const dto = await apiClient.post<EmployeeDto>('/api/v1/employees', {
      employeeCode: input.employeeId, name: input.name, department: input.department,
      phone: input.phone, email: input.email, role: input.role || 'employee',
    });
    const employee = mapEmployee(dto);
    setEmployees((es) => [...es, employee]);
    return employee;
  };

  const updateEmployee = async (id: string, input: EmployeeInput): Promise<Employee> => {
    const dto = await apiClient.patch<EmployeeDto>(`/api/v1/employees/${id}`, {
      employeeCode: input.employeeId, name: input.name, department: input.department,
      phone: input.phone, email: input.email, role: input.role,
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
      name: input.name, capacity: Number(input.capacity) || null, floor: input.floor,
      photoUrl: input.photoUrl || null,
    });
    setMeetingRooms((rs) => [...rs, room]);
    return room;
  };

  const updateMeetingRoom = async (id: string, input: MeetingRoomInput): Promise<MeetingRoom> => {
    const room = await apiClient.patch<MeetingRoom>(`/api/v1/meeting-rooms/${id}`, {
      name: input.name, capacity: Number(input.capacity) || null, floor: input.floor,
      photoUrl: input.photoUrl || null,
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
    const dto = await apiClient.post<ClockRecordDto>('/api/v1/clock-records/in', { employeeId, employeeName });
    const record = mapClockRecord(dto);
    setClockRecords((cs) => [record, ...cs]);
    return record;
  };

  const clockOut = async (employeeId: string, employeeName: string): Promise<ClockRecord> => {
    const dto = await apiClient.post<ClockRecordDto>('/api/v1/clock-records/out', { employeeId, employeeName });
    const record = mapClockRecord(dto);
    setClockRecords((cs) => [record, ...cs]);
    return record;
  };

  // Everything above only reflects actions taken in *this* signed-in
  // session — a receptionist clocking in on their own phone doesn't
  // push anything to a manager's already-open app (no websockets/
  // polling in this build). ManagerClockInsScreen calls this whenever
  // it comes into focus so it actually picks up everyone else's
  // clock-ins/outs instead of showing whatever was loaded at login.
  const refreshClockRecords = async (): Promise<void> => {
    const cr = await apiClient.get<ClockRecordDto[]>('/api/v1/clock-records');
    setClockRecords(cr.map(mapClockRecord));
  };

  // Records are newest-first — these stay synchronous, derived from the
  // locally-held ledger, so ClockCard's render logic doesn't change.
  const isClockedIn = (employeeId: string): boolean => {
    const mine = clockRecords.find((c) => c.employeeId === employeeId);
    return !!mine && mine.type === 'in';
  };

  const hasClockedInToday = (employeeId: string): boolean => {
    const todayKey = new Date().toDateString();
    return clockRecords.some((c) => (
      c.employeeId === employeeId
      && c.type === 'in'
      && new Date(c.timestamp).toDateString() === todayKey
    ));
  };

  // ---- self-service meeting booking ----

  const bookRoom = async (input: BookRoomInput): Promise<RoomBooking> => {
    const dto = await apiClient.post<RoomBookingDto>('/api/v1/room-bookings', {
      roomId: input.roomId || null,
      location: input.roomId ? null : (input.location || ''),
      title: input.title || 'Meeting',
      startTime: input.startTime,
      endTime: input.endTime,
      participantIds: input.participantIds || [],
      externalGuests: input.externalGuests || null,
    });
    const booking = mapRoomBooking(dto);
    setRoomBookings((rs) => [booking, ...rs]);
    return booking;
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
    id: string, newScheduledAt: string, reason?: string
  ): Promise<Appointment> => {
    const dto = await apiClient.patch<AppointmentDto>(`/api/v1/appointments/${id}/reschedule`, {
      newScheduledAt, reason: reason || '',
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

    const todayVisitors = visitors.filter(
      (v) => new Date(v.checkInAt).getTime() >= startOfDay
    );
    const onsite = visitors.filter((v) => v.status === 'onsite');
    const callsToday = calls.filter(
      (c) => new Date(c.timestamp).getTime() >= startOfDay
    );
    const monthVisitors = visitors.filter(
      (v) => new Date(v.checkInAt).getTime() >= startOfMonth
    );
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
        visitors, appointments, calls, nfcCards, roomBookings, employees, meetingRooms,
        // lookup helpers
        employeeById, roomById,
        // operations
        registerAndCheckIn, checkOutVisitor,
        updateAppointmentStatus, admitAppointment,
        logCall, addEmployee, updateEmployee, removeEmployee,
        addMeetingRoom, updateMeetingRoom, removeMeetingRoom,
        bookVisit, findAppointmentByCode,
        // work attendance (clock in/out) + appointment rescheduling
        clockRecords, clockIn, clockOut, isClockedIn, hasClockedInToday, refreshClockRecords, rescheduleAppointment,
        // self-service room booking
        bookRoom, refreshRoomBookings,
        // billing / subscriptions
        plans, billing, invoices, changePlan,
        // in-app notifications
        notifications, unreadNotificationCount, refreshNotifications, markNotificationRead,
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
