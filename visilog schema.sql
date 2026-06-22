-- ============================================================
--  VisiLog Database Schema
--  Visitor Management & Reception Operations System
--  PostgreSQL
-- ============================================================

-- ============================================================
-- 1. RECEPTIONISTS / ADMIN USERS
--    Staff who manage the dashboard and approve visits
-- ============================================================
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


-- ============================================================
-- 2. HOSTS / STAFF BEING VISITED
--    Employees or persons a visitor comes to see
-- ============================================================
CREATE TABLE hosts (
    host_id           SERIAL PRIMARY KEY,
    full_name         VARCHAR(100)        NOT NULL,
    email             VARCHAR(150)        UNIQUE NOT NULL,
    phone             VARCHAR(20),
    department        VARCHAR(100),
    is_available      BOOLEAN             NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- 3. NFC CARDS
--    Physical NFC cards issued at reception
-- ============================================================
CREATE TABLE nfc_cards (
    card_id           SERIAL PRIMARY KEY,
    nfc_uid           VARCHAR(100)        UNIQUE NOT NULL,  -- unique ID from the NFC chip
    status            VARCHAR(20)         NOT NULL DEFAULT 'available'
                          CHECK (status IN ('available', 'in_use', 'decommissioned')),
    issued_at         TIMESTAMP,
    returned_at       TIMESTAMP,
    created_at        TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- 4. VISITORS
--    People who come to the facility
-- ============================================================
CREATE TABLE visitors (
    visitor_id        SERIAL PRIMARY KEY,
    full_name         VARCHAR(100)        NOT NULL,
    email             VARCHAR(150),
    phone             VARCHAR(20)         NOT NULL,
    id_type           VARCHAR(50),                          -- e.g. National ID, Passport
    id_number         VARCHAR(100),
    photo_url         TEXT,                                 -- stored image path or URL
    created_at        TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
-- 5. VISITS  (main log table)
--    Every check-in event linking visitor, host, NFC card,
--    and the receptionist who processed it
-- ============================================================
CREATE TABLE visits (
    visit_id          SERIAL PRIMARY KEY,
    visitor_id        INT                 NOT NULL REFERENCES visitors(visitor_id),
    host_id           INT                 NOT NULL REFERENCES hosts(host_id),
    nfc_card_id       INT                 REFERENCES nfc_cards(card_id),
    receptionist_id   INT                 REFERENCES receptionists(receptionist_id),

    purpose           TEXT                NOT NULL,         -- reason for visit
    status            VARCHAR(20)         NOT NULL DEFAULT 'checked_in'
                          CHECK (status IN ('checked_in', 'checked_out', 'cancelled')),

    check_in_time     TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,
    check_out_time    TIMESTAMP,

    notes             TEXT                                  -- optional receptionist notes
);


-- ============================================================
-- 6. NFC SCAN LOGS
--    Every time an NFC card is scanned (entry or exit)
-- ============================================================
CREATE TABLE nfc_scan_logs (
    log_id            SERIAL PRIMARY KEY,
    nfc_card_id       INT                 NOT NULL REFERENCES nfc_cards(card_id),
    visit_id          INT                 REFERENCES visits(visit_id),
    scan_type         VARCHAR(10)         NOT NULL
                          CHECK (scan_type IN ('entry', 'exit')),
    scanned_at        TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,
    scanned_by        INT                 REFERENCES receptionists(receptionist_id)
);


-- ============================================================
-- INDEXES  (speed up common queries)
-- ============================================================
CREATE INDEX idx_visits_visitor      ON visits(visitor_id);
CREATE INDEX idx_visits_host         ON visits(host_id);
CREATE INDEX idx_visits_checkin      ON visits(check_in_time);
CREATE INDEX idx_nfc_scan_card       ON nfc_scan_logs(nfc_card_id);
CREATE INDEX idx_nfc_uid             ON nfc_cards(nfc_uid);


-- ============================================================
-- SAMPLE DATA  (for testing before Friday)
-- ============================================================

-- Receptionists
INSERT INTO receptionists (full_name, email, phone, password_hash, role)
VALUES
  ('Admin User',    'admin@visilog.com',       '0200000001', 'hashed_password_1', 'admin'),
  ('Grace Mensah',  'grace@visilog.com',       '0200000002', 'hashed_password_2', 'receptionist');

-- Hosts
INSERT INTO hosts (full_name, email, phone, department)
VALUES
  ('Dr. Kwame Asante',  'kwame@company.com',  '0201111111', 'Engineering'),
  ('Mrs. Abena Osei',   'abena@company.com',  '0202222222', 'HR');

-- NFC Cards
INSERT INTO nfc_cards (nfc_uid, status)
VALUES
  ('NFC-UID-001', 'available'),
  ('NFC-UID-002', 'available'),
  ('NFC-UID-003', 'available');

-- Visitors
INSERT INTO visitors (full_name, email, phone, id_type, id_number)
VALUES
  ('John Doe',   'john@gmail.com',  '0244000001', 'National ID', 'GHA-123456789'),
  ('Mary Adjei', 'mary@gmail.com',  '0244000002', 'Passport',    'G1234567');

-- A Visit
INSERT INTO visits (visitor_id, host_id, nfc_card_id, receptionist_id, purpose, status)
VALUES
  (1, 1, 1, 2, 'Project discussion', 'checked_in');

-- NFC Scan Log for that visit
INSERT INTO nfc_scan_logs (nfc_card_id, visit_id, scan_type, scanned_by)
VALUES
  (1, 1, 'entry', 2);
