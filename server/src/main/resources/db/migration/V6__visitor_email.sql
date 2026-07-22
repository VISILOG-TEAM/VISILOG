-- A place to record a visitor's email -- reception fills it in for a
-- walk-in check-in, and a visitor booking their own appointment can
-- enter one too (it's a real appointment field, not just their login
-- email, since a visitor may want to give a different contact email
-- for the actual meeting).

ALTER TABLE visitors ADD COLUMN email VARCHAR(255);
ALTER TABLE appointments ADD COLUMN visitor_email VARCHAR(255);