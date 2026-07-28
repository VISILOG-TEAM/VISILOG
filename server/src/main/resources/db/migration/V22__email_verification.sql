-- Email verification at signup: a 6-digit code emailed to the address
-- the account was created with, entered in-app before the account can
-- do anything else.
--
-- Note the DEFAULT TRUE on the ADD, flipped to FALSE immediately
-- after: that backfills every account that already exists as verified.
-- Everyone currently using VisiLog signed up before this feature
-- existed and never had a chance to enter a code, so defaulting them
-- to unverified would lock every one of them out of their own app.
-- New rows created from here on get FALSE.
ALTER TABLE app_users ADD COLUMN email_verified BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE app_users ALTER COLUMN email_verified SET DEFAULT FALSE;

ALTER TABLE app_users ADD COLUMN verification_code VARCHAR(10);
ALTER TABLE app_users ADD COLUMN verification_code_expires_at TIMESTAMP;
