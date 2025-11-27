-- =====================================================
-- 안전한 상담 기능 마이그레이션
-- 날짜: 2025-11-25
-- =====================================================

-- 1. record_type 컬럼 추가 (기존 레코드는 모두 RESERVATION)
ALTER TABLE reservation
ADD COLUMN IF NOT EXISTS record_type VARCHAR(20) NOT NULL DEFAULT 'RESERVATION'
COMMENT '레코드 타입: RESERVATION(예약) 또는 CONSULTATION(독립상담)';

-- 2. 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_record_type ON reservation(record_type);
CREATE INDEX IF NOT EXISTS idx_consultation_status ON reservation(consultation_status);

-- 3. 확인
SELECT
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'reservation'
    AND COLUMN_NAME = 'record_type';
