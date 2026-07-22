-- Seat counts shown to customers as ranges rather than a single exact
-- number -- easier to reason about when deciding a plan. seat_limit
-- stays the real enforced cap (the top of each range); see
-- EmployeeService.checkSeatCap.

UPDATE plans SET seat_limit = 20 WHERE id = 'starter';
UPDATE plans SET seat_limit = 100 WHERE id = 'pro';

DELETE FROM plan_features;

INSERT INTO plan_features (plan_id, feature, position) VALUES
    ('starter', '10-20 staff seats', 0),
    ('pro', '50-100 staff seats', 0),
    ('enterprise', '500+ staff seats', 0),
    ('enterprise', 'Custom branding & theming', 1);
