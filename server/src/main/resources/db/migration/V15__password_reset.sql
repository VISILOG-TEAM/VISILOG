ALTER TABLE app_users ADD COLUMN reset_code VARCHAR(10);
ALTER TABLE app_users ADD COLUMN reset_code_expires_at TIMESTAMP;