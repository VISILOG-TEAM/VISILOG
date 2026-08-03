-- Owner approval at signup: alongside confirming their own email, a new
-- account joining an existing company also needs the company's owner
-- (Manager) to approve them with a code emailed separately. Same
-- backfill trick as V22 -- existing accounts default to TRUE (already
-- trusted), new rows created from here on get FALSE.
ALTER TABLE app_users ADD COLUMN owner_approved BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE app_users ALTER COLUMN owner_approved SET DEFAULT FALSE;

ALTER TABLE app_users ADD COLUMN approval_code VARCHAR(10);
ALTER TABLE app_users ADD COLUMN approval_code_expires_at TIMESTAMP;
