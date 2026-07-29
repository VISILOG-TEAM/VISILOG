-- Visitor check-in is now a separate step from admitting an appointment.
-- Admitting = receptionist approves the request; check-in = visitor physically arrives.
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS checked_in BOOLEAN NOT NULL DEFAULT FALSE;

-- Preserve existing data: already-admitted appointments are treated as checked-in
-- (old behaviour was admit + check-in in one step, so they're already on-site).
UPDATE appointments SET checked_in = TRUE WHERE status = 'ADMITTED';

-- Allow room bookings to be rescheduled after creation.
ALTER TABLE room_bookings ADD COLUMN IF NOT EXISTS reschedule_reason VARCHAR(1000);
ALTER TABLE room_bookings ADD COLUMN IF NOT EXISTS rescheduled_at TIMESTAMPTZ;
