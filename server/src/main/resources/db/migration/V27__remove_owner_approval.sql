-- Owner approval (V24) is removed: a new signup no longer needs a
-- Manager to approve them with an emailed code, so the columns backing
-- that gate are dead weight.
ALTER TABLE app_users DROP COLUMN owner_approved;
ALTER TABLE app_users DROP COLUMN approval_code;
ALTER TABLE app_users DROP COLUMN approval_code_expires_at;
