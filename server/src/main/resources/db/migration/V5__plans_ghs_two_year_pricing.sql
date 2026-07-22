-- Billing moves from a monthly USD subscription to the real model this
-- app now uses: a flat 2-year subscription priced in Ghana cedis (GHS),
-- paid up front via the legal-agreement/subscription step at company
-- registration (see AuthService.registerCompany). Plan tiers differ by
-- staff seat limit and whether custom branding is included — every
-- other capability (visitor check-in, NFC, meeting rooms) is already
-- available to every organization regardless of plan, so the old
-- feature lists implying otherwise were never actually true.

ALTER TABLE plans RENAME COLUMN price_per_month TO price;

UPDATE plans SET price = 400.00, seat_limit = 10 WHERE id = 'starter';
UPDATE plans SET price = 1200.00, seat_limit = 50 WHERE id = 'pro';
UPDATE plans SET price = 3500.00, seat_limit = 500 WHERE id = 'enterprise';

DELETE FROM plan_features;

INSERT INTO plan_features (plan_id, feature, position) VALUES
    ('starter', 'Up to 10 staff seats', 0),
    ('pro', 'Up to 50 staff seats', 0),
    ('enterprise', 'Up to 500 staff seats', 0),
    ('enterprise', 'Custom branding & theming', 1);
