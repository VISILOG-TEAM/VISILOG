-- VisiLog schema — one Spring Boot monolith, one Postgres database,
-- every tenant-scoped table carries organization_id and is always
-- queried scoped to the caller's own org (enforced in the service
-- layer, never trusted from the client).

CREATE TABLE organizations (
    id                       UUID PRIMARY KEY,
    code                     VARCHAR(32) NOT NULL UNIQUE,
    name                     VARCHAR(255) NOT NULL,
    logo_url                 VARCHAR(1024),
    brand                    VARCHAR(16) NOT NULL,
    brand_dark               VARCHAR(16) NOT NULL,
    brand_tint               VARCHAR(16) NOT NULL,
    primary_color            VARCHAR(16) NOT NULL,
    primary_pressed          VARCHAR(16) NOT NULL,
    primary_surface          VARCHAR(16) NOT NULL,
    primary_surface_strong   VARCHAR(16) NOT NULL,
    office_latitude          DOUBLE PRECISION,
    office_longitude         DOUBLE PRECISION,
    office_radius_meters     INTEGER,
    created_at               TIMESTAMP NOT NULL
);

CREATE TABLE plans (
    id               VARCHAR(32) PRIMARY KEY,
    name             VARCHAR(64) NOT NULL,
    price_per_month  NUMERIC(10,2) NOT NULL,
    seat_limit       INTEGER NOT NULL
);

CREATE TABLE plan_features (
    plan_id   VARCHAR(32) NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
    feature   VARCHAR(255) NOT NULL,
    position  INTEGER NOT NULL
);

CREATE TABLE org_billing (
    id                UUID PRIMARY KEY,
    organization_id   UUID NOT NULL UNIQUE REFERENCES organizations(id) ON DELETE CASCADE,
    plan_id           VARCHAR(32) NOT NULL REFERENCES plans(id),
    status            VARCHAR(16) NOT NULL,
    seats_used        INTEGER NOT NULL DEFAULT 0,
    renewal_date      TIMESTAMP NOT NULL,
    payment_last4     VARCHAR(8)
);

CREATE TABLE invoices (
    id                UUID PRIMARY KEY,
    organization_id   UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    invoice_date      TIMESTAMP NOT NULL,
    amount            NUMERIC(10,2) NOT NULL,
    status            VARCHAR(16) NOT NULL
);

CREATE TABLE employees (
    id                UUID PRIMARY KEY,
    organization_id   UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    employee_code     VARCHAR(32) NOT NULL,
    name              VARCHAR(255) NOT NULL,
    department        VARCHAR(255),
    phone             VARCHAR(64),
    avaya             VARCHAR(32),
    email             VARCHAR(255) NOT NULL,
    role              VARCHAR(16) NOT NULL,
    UNIQUE (organization_id, email),
    UNIQUE (organization_id, employee_code)
);

CREATE TABLE app_users (
    id                UUID PRIMARY KEY,
    organization_id   UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    email             VARCHAR(255) NOT NULL,
    password_hash     VARCHAR(255) NOT NULL,
    name              VARCHAR(255) NOT NULL,
    role              VARCHAR(16) NOT NULL,
    employee_id       UUID REFERENCES employees(id) ON DELETE SET NULL,
    created_at        TIMESTAMP NOT NULL,
    UNIQUE (organization_id, email)
);

CREATE TABLE visitors (
    id                UUID PRIMARY KEY,
    organization_id   UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    badge_id          VARCHAR(32) NOT NULL,
    first_name        VARCHAR(255),
    last_name         VARCHAR(255),
    phone             VARCHAR(64),
    company           VARCHAR(255),
    purpose           VARCHAR(255),
    host_id           UUID REFERENCES employees(id),
    check_in_at       TIMESTAMP NOT NULL,
    check_out_at      TIMESTAMP,
    status            VARCHAR(16) NOT NULL,
    notes             VARCHAR(2000),
    UNIQUE (organization_id, badge_id)
);

CREATE TABLE appointments (
    id                  UUID PRIMARY KEY,
    organization_id     UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    visitor_name        VARCHAR(255),
    visitor_phone       VARCHAR(64),
    visitor_company     VARCHAR(255),
    purpose             VARCHAR(255),
    host_id             UUID REFERENCES employees(id),
    scheduled_at        TIMESTAMP NOT NULL,
    status              VARCHAR(16) NOT NULL,
    nfc_code            VARCHAR(32) NOT NULL,
    booked_by_email     VARCHAR(255),
    reschedule_reason   VARCHAR(1000),
    rescheduled_at      TIMESTAMP,
    UNIQUE (organization_id, nfc_code)
);

CREATE TABLE calls (
    id                  UUID PRIMARY KEY,
    organization_id     UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    caller_name         VARCHAR(255),
    caller_phone        VARCHAR(64),
    host_id             UUID REFERENCES employees(id),
    call_type           VARCHAR(16) NOT NULL,
    purpose             VARCHAR(255),
    duration_minutes    INTEGER NOT NULL DEFAULT 0,
    notes               VARCHAR(2000),
    occurred_at         TIMESTAMP NOT NULL
);

CREATE TABLE nfc_cards (
    id                  UUID PRIMARY KEY,
    organization_id     UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    holder_id           UUID NOT NULL,
    holder_type         VARCHAR(16) NOT NULL,
    token_hash          VARCHAR(255) NOT NULL,
    issued_at           TIMESTAMP NOT NULL,
    expires_at          TIMESTAMP,
    status              VARCHAR(16) NOT NULL
);

CREATE TABLE clock_records (
    id                  UUID PRIMARY KEY,
    organization_id     UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    employee_id         UUID NOT NULL,
    employee_name       VARCHAR(255) NOT NULL,
    type                VARCHAR(8) NOT NULL,
    occurred_at         TIMESTAMP NOT NULL
);

CREATE TABLE meeting_rooms (
    id                  UUID PRIMARY KEY,
    organization_id     UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name                VARCHAR(255) NOT NULL,
    capacity            INTEGER,
    floor               VARCHAR(64)
);

CREATE TABLE room_bookings (
    id                  UUID PRIMARY KEY,
    organization_id     UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    room_id             UUID REFERENCES meeting_rooms(id),
    location            VARCHAR(500),
    organiser_id        UUID NOT NULL,
    title               VARCHAR(255) NOT NULL,
    start_time          TIMESTAMP NOT NULL,
    end_time            TIMESTAMP NOT NULL
);

CREATE TABLE room_booking_participants (
    room_booking_id     UUID NOT NULL REFERENCES room_bookings(id) ON DELETE CASCADE,
    employee_id         UUID NOT NULL
);

-- Lookup indexes for the org-scoped queries every service performs.
CREATE INDEX idx_employees_org ON employees(organization_id);
CREATE INDEX idx_app_users_org ON app_users(organization_id);
CREATE INDEX idx_visitors_org ON visitors(organization_id);
CREATE INDEX idx_appointments_org ON appointments(organization_id);
CREATE INDEX idx_calls_org ON calls(organization_id);
CREATE INDEX idx_nfc_cards_org ON nfc_cards(organization_id);
CREATE INDEX idx_clock_records_org_employee ON clock_records(organization_id, employee_id);
CREATE INDEX idx_meeting_rooms_org ON meeting_rooms(organization_id);
CREATE INDEX idx_room_bookings_org ON room_bookings(organization_id);
