// VisiLog mock data
// -------------------------------------------------------------
// This file is the single source of truth for all demo data. In a real
// deployment, every export here would be replaced with a call to the
// Spring Boot REST API described in the VisiLog spec.
//
// The data uses the team's own names from the VisiLog brief so the demo
// feels grounded in the project itself.

// ---------- helpers ----------
const today = new Date();
const isoDaysAgo = (d) => {
  const x = new Date(today);
  x.setDate(x.getDate() - d);
  return x.toISOString();
};
const isoMinutesAgo = (m) => {
  const x = new Date(today);
  x.setMinutes(x.getMinutes() - m);
  return x.toISOString();
};
const isoMinutesAhead = (m) => {
  const x = new Date(today);
  x.setMinutes(x.getMinutes() + m);
  return x.toISOString();
};

// Auto-generated badge IDs use a "VIS-YYYY-NNN" format, mirroring the
// pattern shown in the project's web screenshots (e.g. VIS-2026-001).
export const nextBadgeId = (existing = []) => {
  const year = new Date().getFullYear();
  const nums = existing
    .map((v) => v.badgeId || '')
    .filter((id) => id.startsWith(`VIS-${year}-`))
    .map((id) => parseInt(id.split('-')[2], 10))
    .filter((n) => !isNaN(n));
  const next = (nums.length ? Math.max(...nums) : 0) + 1;
  return `VIS-${year}-${String(next).padStart(3, '0')}`;
};

// ---------- the signed-in receptionist ----------
export const currentUser = {
  id: 'r-001',
  name: 'Wendy Abagna',
  email: 'wendy.abagna@vra.com',
  role: 'Receptionist',
  shift: 'Morning',
  avatarTint: 'teal',
};

// ---------- employees (hosts) ----------
// Dropdown source for "host" pickers across the app, and the directory.
export const employees = [
  { id: 'e-01', employeeId: 'VRA-1001', name: 'Irene Gbadago', department: 'Operations', phone: '+233 24 615 9824', avaya: '2068', email: 'irene.gbadago@vra.com' },
  { id: 'e-02', employeeId: 'VRA-1002', name: 'Naa Abbey', department: 'Customer Service', phone: '+233 24 612 2824', avaya: '5282', email: 'naa.abbey@vra.com' },
  { id: 'e-03', employeeId: 'VRA-1003', name: 'Blessing Amaning-Kwarteng', department: 'Finance', phone: '+233 24 613 6024', avaya: '4779', email: 'blessing.ak@vra.com' },
  { id: 'e-04', employeeId: 'VRA-1004', name: 'Wendy Abagna', department: 'Reception', phone: '+233 24 612 1924', avaya: '2596', email: 'wendy.abagna@vra.com' },
  { id: 'e-05', employeeId: 'VRA-1005', name: 'Abigail Hermann', department: 'Engineering', phone: '+233 24 616 1624', avaya: '1931', email: 'abigail.hermann@vra.com' },
  { id: 'e-06', employeeId: 'VRA-1006', name: 'Kojo Mensah', department: 'Security', phone: '+233 24 555 0102', avaya: '3401', email: 'kojo.mensah@vra.com' },
  { id: 'e-07', employeeId: 'VRA-1007', name: 'Ama Owusu', department: 'Human Resources', phone: '+233 24 555 0103', avaya: '3402', email: 'ama.owusu@vra.com' },
  { id: 'e-08', employeeId: 'VRA-1008', name: 'Yaw Boateng', department: 'IT', phone: '+233 24 555 0104', avaya: '3403', email: 'yaw.boateng@vra.com' },
];

// ---------- purpose-of-visit options ----------
export const visitPurposes = [
  'Official Business',
  'Meeting with Host',
  'Job Interview',
  'Delivery',
  'Maintenance',
  'Contractor Work',
  'Personal',
  'Other',
];

// ---------- visitors (today's log + history) ----------
// `status` is one of: 'onsite' (still in the building), 'completed'
// (checked out), or 'expected' (registered but not yet checked in).
export const initialVisitors = [
  {
    id: 'v-001', badgeId: 'VIS-2026-001',
    firstName: 'Aseye', lastName: 'Abugri', fullName: 'Aseye Abugri',
    phone: '+233 20 111 2233', company: 'Adansi Logistics',
    purpose: 'Official Business', hostId: 'e-02',
    checkInAt: isoMinutesAgo(120), checkOutAt: null,
    status: 'onsite', notes: '',
  },
  {
    id: 'v-002', badgeId: 'VIS-2026-002',
    firstName: 'Eric', lastName: 'Nartey', fullName: 'Eric Nartey',
    phone: '+233 20 444 5566', company: 'Free agent',
    purpose: 'Job Interview', hostId: 'e-07',
    checkInAt: isoMinutesAgo(55), checkOutAt: null,
    status: 'onsite', notes: '',
  },
  {
    id: 'v-003', badgeId: 'VIS-2026-003',
    firstName: 'Emma', lastName: 'Boateng', fullName: 'Emma Boateng',
    phone: '+233 20 777 8899', company: 'Boateng Holdings',
    purpose: 'Meeting with Host', hostId: 'e-01',
    checkInAt: isoMinutesAgo(35), checkOutAt: null,
    status: 'onsite', notes: '',
  },
  {
    id: 'v-004', badgeId: 'VIS-2026-004',
    firstName: 'Secretary', lastName: 'Procurement', fullName: 'Sec. Procurement Office',
    phone: '+233 20 100 4400', company: 'Procurement Office',
    purpose: 'Delivery', hostId: 'e-03',
    checkInAt: isoMinutesAgo(15), checkOutAt: null,
    status: 'onsite', notes: '',
  },
  // Earlier today — already checked out
  {
    id: 'v-005', badgeId: 'VIS-2026-005',
    firstName: 'Akua', lastName: 'Mensimah', fullName: 'Akua Mensimah',
    phone: '+233 20 998 7766', company: 'Sterling Audit',
    purpose: 'Official Business', hostId: 'e-04',
    checkInAt: isoMinutesAgo(360), checkOutAt: isoMinutesAgo(180),
    status: 'completed', notes: 'Quarterly audit closing meeting.',
  },
  {
    id: 'v-006', badgeId: 'VIS-2026-006',
    firstName: 'Kweku', lastName: 'Asare', fullName: 'Kweku Asare',
    phone: '+233 20 222 3344', company: 'Asare & Co.',
    purpose: 'Contractor Work', hostId: 'e-05',
    checkInAt: isoMinutesAgo(420), checkOutAt: isoMinutesAgo(240),
    status: 'completed', notes: '',
  },
  // Earlier this week — for "Visitors This Month"
  {
    id: 'v-007', badgeId: 'VIS-2026-007',
    firstName: 'Fafa', lastName: 'Tetteh', fullName: 'Fafa Tetteh',
    phone: '+233 20 555 1212', company: 'Tetteh Foods',
    purpose: 'Meeting with Host', hostId: 'e-02',
    checkInAt: isoDaysAgo(2), checkOutAt: isoDaysAgo(2),
    status: 'completed', notes: '',
  },
  {
    id: 'v-008', badgeId: 'VIS-2026-008',
    firstName: 'Nana', lastName: 'Yaa', fullName: 'Nana Yaa',
    phone: '+233 20 313 4141', company: 'GhanaNet',
    purpose: 'Maintenance', hostId: 'e-08',
    checkInAt: isoDaysAgo(4), checkOutAt: isoDaysAgo(4),
    status: 'completed', notes: '',
  },
];

// ---------- appointments (pre-registered visits) ----------
export const initialAppointments = [
  {
    id: 'a-001', visitorName: 'Selasi Akoto', visitorPhone: '+233 24 990 1010',
    visitorCompany: 'Akoto Studios', purpose: 'Meeting with Host',
    hostId: 'e-01', scheduledAt: isoMinutesAhead(45), status: 'pending',
  },
  {
    id: 'a-002', visitorName: 'Mawuli Sogbe', visitorPhone: '+233 24 991 2020',
    visitorCompany: 'Sogbe & Partners', purpose: 'Official Business',
    hostId: 'e-03', scheduledAt: isoMinutesAhead(120), status: 'pending',
  },
  {
    id: 'a-003', visitorName: 'Adwoa Asantewaa', visitorPhone: '+233 24 992 3030',
    visitorCompany: 'Asantewaa Crafts', purpose: 'Delivery',
    hostId: 'e-05', scheduledAt: isoMinutesAhead(240), status: 'admitted',
  },
  {
    id: 'a-004', visitorName: 'Felix Quaye', visitorPhone: '+233 24 993 4040',
    visitorCompany: 'Quaye Imports', purpose: 'Job Interview',
    hostId: 'e-07', scheduledAt: isoMinutesAgo(60), status: 'rejected',
  },
];

// ---------- call log ----------
export const callTypes = ['Incoming', 'Outgoing', 'Missed'];
export const initialCalls = [
  {
    id: 'c-001', callerName: 'Joseph Tetteh', callerPhone: '+233 20 100 2030',
    hostId: 'e-02', callType: 'Incoming', purpose: 'Booking enquiry',
    durationMinutes: 4, notes: 'Asked about visiting hours tomorrow.',
    timestamp: isoMinutesAgo(20),
  },
  {
    id: 'c-002', callerName: 'Linda Owusu', callerPhone: '+233 20 100 2040',
    hostId: 'e-07', callType: 'Outgoing', purpose: 'Confirm appointment',
    durationMinutes: 2, notes: '',
    timestamp: isoMinutesAgo(90),
  },
  {
    id: 'c-003', callerName: 'Unknown', callerPhone: '+233 55 200 5050',
    hostId: 'e-04', callType: 'Missed', purpose: 'General enquiry',
    durationMinutes: 0, notes: 'Called twice, voicemail left.',
    timestamp: isoMinutesAgo(180),
  },
  {
    id: 'c-004', callerName: 'Patricia Adjei', callerPhone: '+233 20 100 2060',
    hostId: 'e-01', callType: 'Incoming', purpose: 'Delivery dispatch',
    durationMinutes: 6, notes: 'Driver running 30 minutes late.',
    timestamp: isoMinutesAgo(260),
  },
];

// ---------- NFC virtual cards ----------
// `holderType` is 'employee' or 'visitor'. `status` is 'active' | 'revoked'.
export const initialNfcCards = [
  { id: 'nfc-001', holderId: 'e-01', holderType: 'employee', tokenHash: '8a7b…f201',
    issuedAt: isoDaysAgo(120), expiresAt: isoDaysAgo(-245), status: 'active' },
  { id: 'nfc-002', holderId: 'e-02', holderType: 'employee', tokenHash: '3c4d…a019',
    issuedAt: isoDaysAgo(120), expiresAt: isoDaysAgo(-245), status: 'active' },
  { id: 'nfc-003', holderId: 'a-003', holderType: 'visitor', tokenHash: '5e6f…b234',
    issuedAt: isoMinutesAgo(180), expiresAt: isoMinutesAhead(240), status: 'active' },
  { id: 'nfc-004', holderId: 'e-08', holderType: 'employee', tokenHash: '7g8h…c567',
    issuedAt: isoDaysAgo(60), expiresAt: isoDaysAgo(-300), status: 'revoked' },
];

// ---------- attendance taps (NFC) ----------
export const initialAttendance = [
  { id: 'att-1', employeeId: 'e-01', tapType: 'in', timestamp: isoMinutesAgo(420), readerId: 'main-entry' },
  { id: 'att-2', employeeId: 'e-02', tapType: 'in', timestamp: isoMinutesAgo(415), readerId: 'main-entry' },
  { id: 'att-3', employeeId: 'e-03', tapType: 'in', timestamp: isoMinutesAgo(390), readerId: 'main-entry' },
  { id: 'att-4', employeeId: 'e-04', tapType: 'in', timestamp: isoMinutesAgo(450), readerId: 'main-entry' },
  { id: 'att-5', employeeId: 'e-05', tapType: 'in', timestamp: isoMinutesAgo(380), readerId: 'side-entry' },
];

// ---------- meeting room bookings ----------
export const meetingRooms = [
  { id: 'r-01', name: 'Boardroom A', capacity: 12, floor: '3rd Floor' },
  { id: 'r-02', name: 'Briefing Room', capacity: 6, floor: '2nd Floor' },
  { id: 'r-03', name: 'Innovation Lab', capacity: 8, floor: '4th Floor' },
];

export const initialRoomBookings = [
  { id: 'rb-1', roomId: 'r-01', organiserId: 'e-01', title: 'Q3 review',
    startTime: isoMinutesAhead(30), endTime: isoMinutesAhead(120),
    participantIds: ['e-01', 'e-02', 'e-03'] },
  { id: 'rb-2', roomId: 'r-03', organiserId: 'e-08', title: 'Sprint planning',
    startTime: isoMinutesAhead(180), endTime: isoMinutesAhead(300),
    participantIds: ['e-08', 'e-05'] },
];

// ---------- lookup helpers ----------
export const employeeById = (id) => employees.find((e) => e.id === id);
export const roomById = (id) => meetingRooms.find((r) => r.id === id);
