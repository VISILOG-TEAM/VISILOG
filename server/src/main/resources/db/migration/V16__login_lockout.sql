ALTER TABLE app_users ADD COLUMN failed_login_attempts INT NOT NULL DEFAULT 0;
ALTER TABLE app_users ADD COLUMN locked_until TIMESTAMP;