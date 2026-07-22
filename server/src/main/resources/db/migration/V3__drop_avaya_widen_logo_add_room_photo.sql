-- Drop the Avaya extension field (not used by this customer's phone
-- system) and widen logo_url to hold a base64 data URI from an
-- uploaded image, not just a short link. Also add a photo per meeting
-- room, so Company Setup can attach a real picture for the visitor map.

ALTER TABLE employees DROP COLUMN avaya;

ALTER TABLE organizations ALTER COLUMN logo_url TYPE TEXT;

ALTER TABLE meeting_rooms ADD COLUMN photo_url TEXT;
