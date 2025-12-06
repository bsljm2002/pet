-- Create medication_log table to track daily medication intake
-- Run this manually in your MySQL database

USE Insa6_aiservice_p3_2;

CREATE TABLE IF NOT EXISTS medication_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    reservation_id BIGINT NOT NULL COMMENT '예약 ID (진료 기록)',
    user_id BIGINT NOT NULL COMMENT '사용자 ID',
    pet_id BIGINT NOT NULL COMMENT '반려동물 ID',
    medication_key VARCHAR(50) NOT NULL COMMENT '복용 키 (예: "1-아침", "2-저녁")',
    taken_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '복용 체크 시간',

    UNIQUE KEY uk_reservation_medication (reservation_id, medication_key),
    INDEX idx_user_id (user_id),
    INDEX idx_pet_id (pet_id),
    INDEX idx_reservation_id (reservation_id)
) COMMENT='약 복용 기록';

-- Verify table was created
DESCRIBE medication_log;
