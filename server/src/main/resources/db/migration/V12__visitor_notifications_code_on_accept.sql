-- The visit code is now assigned only when a host admits the visit
-- (see AppointmentService.admit), not at booking time -- so a pending
-- or rejected appointment has no code yet.
ALTER TABLE appointments ALTER COLUMN nfc_code DROP NOT NULL;

-- Notifications can now go to a visitor (matched by email, they have
-- no employee record) as well as staff (matched by employee id).
ALTER TABLE notifications ALTER COLUMN recipient_employee_id DROP NOT NULL;
ALTER TABLE notifications ADD COLUMN recipient_email VARCHAR(255);
