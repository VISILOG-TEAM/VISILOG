CREATE TABLE visitors (
    id BIGSERIAL PRIMARY KEY,
    nfc_card_id VARCHAR(50) UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    phone_number VARCHAR(30) NOT NULL,
    company_name VARCHAR(150),
    purpose_of_visit VARCHAR(255) NOT NULL,
    host_employee VARCHAR(150) NOT NULL,
    check_in_time TIMESTAMP NOT NULL,
    check_out_time TIMESTAMP,
    status VARCHAR(20) NOT NULL
);
