-- Update pets_id for existing reservations to enable medical record retrieval
-- Run this manually in your MySQL database

USE Insa6_aiservice_p3_2;

-- Check current state of reservation 171
SELECT id, pets_id, user_id, partner_id, status, diagnosis
FROM reservation
WHERE id = 171;

-- Update reservation 171 with the correct petId (assuming petId = 41 based on the screenshots)
-- Replace 41 with the actual petId if different
UPDATE reservation
SET pets_id = 41
WHERE id = 171;

-- Verify the update
SELECT id, pets_id, user_id, partner_id, status, diagnosis
FROM reservation
WHERE id = 171;

-- Optional: Update all reservations with NULL pets_id to a default petId
-- Uncomment and modify the petId value if needed:
-- UPDATE reservation
-- SET pets_id = 41
-- WHERE pets_id IS NULL AND user_id = 41;

-- Check all reservations with diagnosis data but NULL pets_id
SELECT id, user_id, pets_id, status, diagnosis, prescription, dosage_schedule, dosage_days
FROM reservation
WHERE diagnosis IS NOT NULL AND pets_id IS NULL;
