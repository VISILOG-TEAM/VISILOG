-- Fixed subscription catalog, same three tiers as the frontend's
-- former mock data (src/data/mockData.js `plans`). Every newly
-- registered org starts on 'starter' (see AuthService.registerCompany).

INSERT INTO plans (id, name, price_per_month, seat_limit) VALUES
    ('starter', 'Starter', 49.00, 10),
    ('pro', 'Pro', 149.00, 50),
    ('enterprise', 'Enterprise', 399.00, 500);

INSERT INTO plan_features (plan_id, feature, position) VALUES
    ('starter', 'Up to 10 staff seats', 0),
    ('starter', 'Visitor check-in & badges', 1),
    ('starter', 'Email support', 2),
    ('pro', 'Up to 50 staff seats', 0),
    ('pro', 'NFC cards & access logs', 1),
    ('pro', 'Meeting room booking', 2),
    ('pro', 'Priority support', 3),
    ('enterprise', 'Up to 500 staff seats', 0),
    ('enterprise', 'Custom branding & theming', 1),
    ('enterprise', 'Dedicated account manager', 2),
    ('enterprise', 'SLA-backed support', 3);
