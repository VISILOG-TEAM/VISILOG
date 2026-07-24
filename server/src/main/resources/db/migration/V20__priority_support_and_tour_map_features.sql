-- Priority support becomes a real, visible plan perk again (it existed
-- as a bullet in the original V2 seed but was dropped by later
-- reseeds). Purely a display-driven gate -- SettingsScreen shows a
-- badge and a different Help & support message when the org's current
-- plan's features list contains this string, no new enforcement logic
-- needed since there's no action being blocked, just a UI difference.
--
-- Same pattern for the interactive tour map (CompanyMapSection, already
-- built for visitors) -- reserving it to Pro/Enterprise rather than
-- building anything new; VisitorHomeScreen checks for this string.

INSERT INTO plan_features (plan_id, feature, position) VALUES
    ('pro', 'Priority support', 2),
    ('pro', 'Interactive tour map', 3),
    ('enterprise', 'Priority support', 3),
    ('enterprise', 'Interactive tour map', 4);
