import React, { createContext, useContext, useMemo, useState } from 'react';
import {
  initialVisitors, initialAppointments, initialCalls,
  initialNfcCards, initialAttendance, initialRoomBookings,
  nextBadgeId, employees as initialEmployees,
  initialOrgBilling, initialInvoices,
} from '../data/mockData';

// DataContext gathers every piece of mutable demo data and exposes
// the operations the receptionist workflow needs.
const DataContext = createContext(null);

export function DataProvider({ children }) {
  // ---- state ----
  const [visitors, setVisitors] = useState(initialVisitors);
  const [appointments, setAppointments] = useState(initialAppointments);
  const [calls, setCalls] = useState(initialCalls);
  const [nfcCards] = useState(initialNfcCards);
  const [attendance] = useState(initialAttendance);
  const [roomBookings, setRoomBookings] = useState(initialRoomBookings);
  const [employees, setEmployees] = useState(initialEmployees);
  const [visitorAccounts, setVisitorAccounts] = useState([]);
  // Shared clock-in/out ledger. Distinct from `attendance` (the NFC tap
  // log, seeded demo data) — this is the live record behind the personal
  // "on the clock" cards on Employee/Receptionist home screens, and the
  // Manager's Clock-ins screen, so every role sees the same truth.
  const [clockRecords, setClockRecords] = useState([]);
  // Per-organization subscription state, keyed by organizationId — this
  // is what makes the "several companies paying us subscriptions"
  // business model visible in the app (Settings > Billing & subscription,
  // Manager/Administrator only). Invoices are demo history, not appended
  // to on a plan switch — only the live plan/status/seats change.
  const [orgBilling, setOrgBilling] = useState(initialOrgBilling);
  const [invoices] = useState(initialInvoices);

  // ---- visitor operations ----

  // Adds a new visitor and immediately checks them in. Returns the new record.
  const registerAndCheckIn = (input) => {
    const fullName = `${(input.firstName || '').trim()} ${(input.lastName || '').trim()}`.trim();
    const visitor = {
      id: `v-${Date.now()}`,
      badgeId: nextBadgeId(visitors),
      firstName: input.firstName || '',
      lastName: input.lastName || '',
      fullName,
      phone: input.phone || '',
      company: input.company || '',
      purpose: input.purpose || 'Official Business',
      hostId: input.hostId,
      checkInAt: new Date().toISOString(),
      checkOutAt: null,
      status: 'onsite',
      notes: input.notes || '',
    };
    setVisitors((vs) => [visitor, ...vs]);
    return visitor;
  };

  // Marks a visitor as checked out at the current time, with optional notes.
  const checkOutVisitor = (visitorId, notes = '') => {
    setVisitors((vs) =>
      vs.map((v) =>
        v.id === visitorId
          ? { ...v, status: 'completed', checkOutAt: new Date().toISOString(), notes: notes || v.notes }
          : v
      )
    );
  };

  // ---- appointment operations ----

  // Visitor self-registration (from the Signup screen).
  const registerVisitorAccount = (input) => {
    const account = {
      id: `va-${Date.now()}`,
      fullName: input.fullName,
      email: input.email.toLowerCase().trim(),
      password: input.password,
      phone: input.phone || '',
      company: input.company || '',
    };
    setVisitorAccounts((a) => [...a, account]);
    return account;
  };

  // Make a unique NFC code for a visitor booking.
  // Format: VC-XXXX-XXXX (digits only, easy to read out loud).
  const generateVisitorCode = () => {
    const rand = () => Math.floor(1000 + Math.random() * 9000);
    return `VC-${rand()}-${rand()}`;
  };

  // Visitor books a visit — creates a pending appointment with an NFC code.
  const bookVisit = (input) => {
    const appointment = {
      id: `a-${Date.now()}`,
      visitorName: input.visitorName,
      visitorPhone: input.visitorPhone,
      visitorCompany: input.visitorCompany || '',
      purpose: input.purpose,
      hostId: input.hostId,
      scheduledAt: input.scheduledAt || new Date().toISOString(),
      status: 'pending',
      nfcCode: generateVisitorCode(),
      bookedByEmail: input.bookedByEmail || '',
    };
    setAppointments((as) => [appointment, ...as]);
    return appointment;
  };

  // Receptionist's NFC lookup — find a booking by its code.
  const findAppointmentByCode = (code) => {
    const clean = (code || '').trim().toUpperCase();
    return appointments.find((a) => a.nfcCode === clean);
  };

  const updateAppointmentStatus = (id, status) => {
    setAppointments((as) => as.map((a) => (a.id === id ? { ...a, status } : a)));
  };

  // When an appointment is admitted we ALSO register the visitor and
  // check them in, so the front desk doesn't repeat the data entry.
  const admitAppointment = (appointment) => {
    updateAppointmentStatus(appointment.id, 'admitted');
    const [firstName, ...rest] = (appointment.visitorName || '').split(' ');
    return registerAndCheckIn({
      firstName,
      lastName: rest.join(' '),
      phone: appointment.visitorPhone,
      company: appointment.visitorCompany,
      purpose: appointment.purpose,
      hostId: appointment.hostId,
    });
  };

  // ---- call log operations ----

  const logCall = (input) => {
    const call = {
      id: `c-${Date.now()}`,
      callerName: input.callerName || 'Unknown',
      callerPhone: input.callerPhone || '',
      hostId: input.hostId,
      callType: input.callType || 'Incoming',
      purpose: input.purpose || '',
      durationMinutes: Number(input.durationMinutes) || 0,
      notes: input.notes || '',
      timestamp: new Date().toISOString(),
    };
    setCalls((cs) => [call, ...cs]);
    return call;
  };

  // ---- directory operations ----

  const addEmployee = (input) => {
    const emp = {
      id: `e-${Date.now()}`,
      name: input.name || '',
      department: input.department || '',
      phone: input.phone || '',
      avaya: input.avaya || '',
      email: input.email || '',
    };
    setEmployees((es) => [...es, emp]);
    return emp;
  };

  const removeEmployee = (id) => {
    setEmployees((es) => es.filter((e) => e.id !== id));
  };

  // ---- clock in/out (work attendance, not NFC taps) ----

  const clockIn = (employeeId, employeeName) => {
    const record = {
      id: `clk-${Date.now()}`,
      employeeId, employeeName,
      type: 'in',
      timestamp: new Date().toISOString(),
    };
    setClockRecords((cs) => [record, ...cs]);
    return record;
  };

  const clockOut = (employeeId, employeeName) => {
    const record = {
      id: `clk-${Date.now()}`,
      employeeId, employeeName,
      type: 'out',
      timestamp: new Date().toISOString(),
    };
    setClockRecords((cs) => [record, ...cs]);
    return record;
  };

  // Whether `employeeId`'s most recent clock record is an "in" — i.e.
  // they're currently on the clock. Records are newest-first.
  const isClockedIn = (employeeId) => {
    const mine = clockRecords.find((c) => c.employeeId === employeeId);
    return !!mine && mine.type === 'in';
  };

  // One clock-in per calendar day per employee — once they've clocked
  // in today (whether or not they've since clocked out), no more
  // clock-ins are allowed until tomorrow.
  const hasClockedInToday = (employeeId) => {
    const todayKey = new Date().toDateString();
    return clockRecords.some((c) => (
      c.employeeId === employeeId
      && c.type === 'in'
      && new Date(c.timestamp).toDateString() === todayKey
    ));
  };

  // ---- self-service meeting booking (Employee/Manager "Book" tab,
  // and the Receptionist's "Internal meeting" pane — booking a room OR
  // an outside location, with any attendees from the directory) ----

  const bookRoom = (input) => {
    const booking = {
      id: `rb-${Date.now()}`,
      roomId: input.roomId || null,
      location: input.location || '', // set when roomId is null — an outside meeting
      organiserId: input.organiserId,
      title: input.title || 'Meeting',
      startTime: input.startTime,
      endTime: input.endTime,
      participantIds: input.participantIds || [],
    };
    setRoomBookings((rs) => [booking, ...rs]);
    return booking;
  };

  // ---- appointment rescheduling (Employee & Visitor only, per spec —
  // requires a reason so there's a record of why the time changed) ----

  const rescheduleAppointment = (id, newScheduledAt, reason) => {
    setAppointments((as) => as.map((a) => (
      a.id === id
        ? {
            ...a,
            scheduledAt: newScheduledAt,
            rescheduleReason: reason || '',
            rescheduledAt: new Date().toISOString(),
          }
        : a
    )));
  };

  // ---- billing operations (Manager/Administrator only, from Settings) ----

  // Switches an organization's plan, resetting status to 'active' (a
  // successful switch clears any trial/past-due state) — stands in for
  // a real Stripe checkout/upgrade flow.
  const changePlan = (organizationId, planId) => {
    setOrgBilling((b) => ({
      ...b,
      [organizationId]: { ...b[organizationId], planId, status: 'active' },
    }));
  };

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
        visitors, appointments, calls, nfcCards, attendance, roomBookings, employees,
        // operations
        registerAndCheckIn, checkOutVisitor,
        updateAppointmentStatus, admitAppointment,
        logCall, addEmployee, removeEmployee,
        // visitor self-service (Signup / VisitorBooking / NFCLookup screens)
        visitorAccounts, registerVisitorAccount, bookVisit, findAppointmentByCode,
        // work attendance (clock in/out) + appointment rescheduling
        clockRecords, clockIn, clockOut, isClockedIn, hasClockedInToday, rescheduleAppointment,
        // self-service room booking
        bookRoom,
        // billing / subscriptions
        orgBilling, invoices, changePlan,
        // derived
        stats,
      }}
    >
      {children}
    </DataContext.Provider>
  );
}

export const useData = () => useContext(DataContext);
