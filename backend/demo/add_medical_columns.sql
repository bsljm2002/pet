-- Add medical record columns to reservation table
-- Run this manually in your MySQL database

USE Insa6_aiservice_p3_2;

-- Check if columns already exist before adding
ALTER TABLE reservation
ADD COLUMN IF NOT EXISTS diagnosis TEXT COMMENT '진단 소견',
ADD COLUMN IF NOT EXISTS prescription VARCHAR(500) COMMENT '처방약',
ADD COLUMN IF NOT EXISTS dosage_schedule VARCHAR(50) COMMENT '복용 시간 (아침,점심,저녁)',
ADD COLUMN IF NOT EXISTS dosage_days INT COMMENT '복용 일수',
ADD COLUMN IF NOT EXISTS medical_notes TEXT COMMENT '추가 안내사항';

-- Verify columns were added
DESCRIBE reservation;
