-- Meeting urgency flag, and per-participant "seen it" / declined
-- (with reason) tracking so an organiser can tell who's responded.

ALTER TABLE room_bookings ADD COLUMN priority VARCHAR(16) NOT NULL DEFAULT 'NORMAL';

CREATE TABLE room_booking_responses (
    id                UUID PRIMARY KEY,
    organization_id   UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    room_booking_id   UUID NOT NULL REFERENCES room_bookings(id) ON DELETE CASCADE,
    employee_id       UUID NOT NULL,
    status            VARCHAR(16) NOT NULL DEFAULT 'PENDING',
    decline_reason    VARCHAR(1000),
    responded_at      TIMESTAMP,
    UNIQUE (room_booking_id, employee_id)
);

CREATE INDEX idx_room_booking_responses_booking ON room_booking_responses(room_booking_id);
