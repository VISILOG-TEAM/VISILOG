CREATE TABLE push_tokens (
    id                UUID PRIMARY KEY,
    organization_id   UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    employee_id       UUID,
    visitor_email     VARCHAR(255),
    token             VARCHAR(255) NOT NULL UNIQUE,
    created_at        TIMESTAMP NOT NULL
);
CREATE INDEX idx_push_tokens_org_employee ON push_tokens (organization_id, employee_id);
CREATE INDEX idx_push_tokens_org_visitor ON push_tokens (organization_id, visitor_email);

ALTER TABLE appointments ADD COLUMN reminder_sent BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE room_bookings ADD COLUMN reminder_sent BOOLEAN NOT NULL DEFAULT FALSE;
