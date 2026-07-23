-- Plan feature enforcement: previously the feature lists on each plan
-- card (Custom branding, seat counts) were purely decorative -- nothing
-- actually stopped a Starter org from using them. This adds real
-- enforcement (see PlanFeatureService) while grandfathering every org
-- that already exists as of this migration, so nobody who's already
-- using a feature loses it -- only orgs that register after this ships
-- are subject to the new gates.

ALTER TABLE organizations ADD COLUMN grandfathered_features BOOLEAN NOT NULL DEFAULT FALSE;
UPDATE organizations SET grandfathered_features = TRUE;

INSERT INTO plan_features (plan_id, feature, position) VALUES
    ('pro', 'CSV import & export', 1),
    ('enterprise', 'CSV import & export', 2);