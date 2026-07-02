CREATE TABLE receptionists (
    receptionist_id   SERIAL PRIMARY KEY,
    full_name         VARCHAR(100)        NOT NULL,
    email             VARCHAR(150)        UNIQUE NOT NULL,
    phone             VARCHAR(20),
    password_hash     TEXT                NOT NULL,
    role              VARCHAR(20)         NOT NULL DEFAULT 'receptionist'
                          CHECK (role IN ('receptionist', 'admin')),
    is_active         BOOLEAN             NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE hosts (
    host_id           SERIAL PRIMARY KEY,
    full_name         VARCHAR(100)        NOT NULL,
    email             VARCHAR(150)        UNIQUE NOT NULL,
    phone             VARCHAR(20),
    department        VARCHAR(100),
    is_available      BOOLEAN             NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE nfc_cards (
    card_id           SERIAL PRIMARY KEY,
    nfc_uid           VARCHAR(100)        UNIQUE NOT NULL,
    status            VARCHAR(20)         NOT NULL DEFAULT 'available'
                          CHECK (status IN ('available', 'in_use', 'decommissioned')),
    issued_at         TIMESTAMP,
    returned_at       TIMESTAMP,
    created_at        TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE visitors (
    visitor_id        SERIAL PRIMARY KEY,
    full_name         VARCHAR(100)        NOT NULL,
    email             VARCHAR(150),
    phone             VARCHAR(20)         NOT NULL,
    id_type           VARCHAR(50),
    id_number         VARCHAR(100),
    photo_url         TEXT,
    created_at        TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE visits (
    visit_id          SERIAL PRIMARY KEY,
    visitor_id        INT                 NOT NULL REFERENCES visitors(visitor_id),
    host_id           INT                 NOT NULL REFERENCES hosts(host_id),
    nfc_card_id       INT                 REFERENCES nfc_cards(card_id),
    receptionist_id   INT                 REFERENCES receptionists(receptionist_id),
    purpose           TEXT                NOT NULL,
    status            VARCHAR(20)         NOT NULL DEFAULT 'checked_in'
                          CHECK (status IN ('checked_in', 'checked_out', 'cancelled')),
    check_in_time     TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,
    check_out_time    TIMESTAMP,
    notes             TEXT
);

CREATE TABLE nfc_scan_logs (
    log_id            SERIAL PRIMARY KEY,
    nfc_card_id       INT                 NOT NULL REFERENCES nfc_cards(card_id),
    visit_id          INT                 REFERENCES visits(visit_id),
    scan_type         VARCHAR(10)         NOT NULL
                          CHECK (scan_type IN ('entry', 'exit')),
    scanned_at        TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,
    scanned_by        INT                 REFERENCES receptionists(receptionist_id)
);

CREATE TABLE appointment_requests (
    appointment_id    SERIAL PRIMARY KEY,
    visitor_id        INT                 REFERENCES visitors(visitor_id),
    host_id           INT                 REFERENCES hosts(host_id),
    requested_date    DATE                NOT NULL,
    requested_time    TIME                NOT NULL,
    purpose           TEXT                NOT NULL,
    status            VARCHAR(20)         DEFAULT 'pending'
                          CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at        TIMESTAMP           DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE email_notifications (
    notification_id   SERIAL PRIMARY KEY,
    visit_id          INT                 REFERENCES visits(visit_id),
    recipient_email   VARCHAR(150)        NOT NULL,
    subject           VARCHAR(255)        NOT NULL,
    message           TEXT                NOT NULL,
    status            VARCHAR(20)         DEFAULT 'pending'
                          CHECK (status IN ('pending', 'sent', 'failed')),
    sent_at           TIMESTAMP,
    created_at        TIMESTAMP           DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE visitor_companies (
    company_id        SERIAL PRIMARY KEY,
    visitor_id        INT                 REFERENCES visitors(visitor_id),
    company_name      VARCHAR(100)        NOT NULL,
    company_address   TEXT,
    created_at        TIMESTAMP           DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE emergency_contacts (
    contact_id        SERIAL PRIMARY KEY,
    visitor_id        INT                 REFERENCES visitors(visitor_id),
    contact_name      VARCHAR(100)        NOT NULL,
    contact_phone     VARCHAR(20)         NOT NULL,
    relationship      VARCHAR(50),
    created_at        TIMESTAMP           DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_visits_visitor      ON visits(visitor_id);
CREATE INDEX idx_visits_host         ON visits(host_id);
CREATE INDEX idx_visits_checkin      ON visits(check_in_time);
CREATE INDEX idx_nfc_scan_card       ON nfc_scan_logs(nfc_card_id);
CREATE INDEX idx_nfc_uid             ON nfc_cards(nfc_uid);
