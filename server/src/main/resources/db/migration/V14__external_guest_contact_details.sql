-- External guests move from a single free-text names field to a real
-- per-guest table (name/email/phone), so a meeting invite can actually
-- be sent to them -- see RoomBookingService.book / MailService.
CREATE TABLE room_booking_external_guests (
    room_booking_id   UUID NOT NULL REFERENCES room_bookings(id) ON DELETE CASCADE,
    name              VARCHAR(255),
    email             VARCHAR(255),
    phone             VARCHAR(64)
);
CREATE INDEX idx_room_booking_external_guests_booking ON room_booking_external_guests(room_booking_id);

ALTER TABLE room_bookings DROP COLUMN external_guests;
