import React, { createContext, useContext, useMemo, useState } from 'react';
import {
  initialVisitors, initialAppointments, initialCalls,
  initialNfcCards, initialAttendance, initialRoomBookings,
  nextBadgeId, employees as initialEmployees,
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
  const [roomBookings] = useState(initialRoomBookings);
  const [employees, setEmployees] = useState(initialEmployees);
  const [visitorAccounts, setVisitorAccounts] = useState([]);

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
        // derived
        stats,
      }}
    >
      {children}
    </DataContext.Provider>
  );
}

export const useData = () => useContext(DataContext);
