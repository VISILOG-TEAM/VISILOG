-- Clock-in device binding, to stop the "give a coworker your password so
-- they clock in for you" case: the first phone an employee ever clocks
-- in from gets linked to their account, and a clock-in attempt from any
-- other phone is rejected regardless of whose login was used. A manager
-- can clear the link from Company Setup if someone genuinely gets a new
-- phone. See ClockRecordService.

ALTER TABLE employees ADD COLUMN bound_device_id VARCHAR(255);
