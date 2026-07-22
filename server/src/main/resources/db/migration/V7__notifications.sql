-- In-app alerts for staff — e.g. "you've been invited to a meeting".
-- No push/SMS infra in this build: recipients see these the next time
-- they open the app (see NotificationService, NotificationController).

CREATE TABLE notifications (
    id                       UUID PRIMARY KEY,
    organization_id          UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    recipient_employee_id    UUID NOT NULL,
    type                     VARCHAR(32) NOT NULL,
    title                    VARCHAR(255) NOT NULL,
    body                     VARCHAR(1000),
    related_id               UUID,
    read                     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at               TIMESTAMP NOT NULL
);

CREATE INDEX idx_notifications_org_recipient ON notifications(organization_id, recipient_employee_id);
