-- Meetings need to be bookable with people outside the staff roster too
-- (a client, a candidate, a vendor) — participantIds only covers
-- employees, so this holds a free-text list of external guest names.

ALTER TABLE room_bookings ADD COLUMN external_guests TEXT;
