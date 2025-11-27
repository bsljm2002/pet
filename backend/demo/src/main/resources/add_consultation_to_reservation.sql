-- =====================================================
-- Reservation 테이블에 독립 상담 기능 추가
-- 날짜: 2025-11-25
-- 목적: 독립적인 상담 기능 (예약 없이 사용 가능)
-- =====================================================

-- 1. 기존 컬럼 NULL 허용으로 변경 (상담 레코드를 위해)
ALTER TABLE reservation
MODIFY COLUMN service_categorical VARCHAR(20) NULL COMMENT 'HOSPITAL/GROOMING/CAFE/SITTER (상담 시 NULL)',
MODIFY COLUMN user_type VARCHAR(20) NULL COMMENT '파트너 타입 (상담 시 NULL)',
MODIFY COLUMN status VARCHAR(20) NULL COMMENT '예약 상태 (상담 시 NULL)',
MODIFY COLUMN visit_date_time DATETIME NULL COMMENT '방문 시간 (상담 시 NULL)',
MODIFY COLUMN pets_id BIGINT NULL COMMENT '반려동물 ID (상담 시 NULL)';

-- 2. 레코드 타입 컬럼 추가 (예약 vs 상담 구분)
ALTER TABLE reservation
ADD COLUMN record_type VARCHAR(20) NOT NULL DEFAULT 'RESERVATION' COMMENT '레코드 타입: RESERVATION(예약) 또는 CONSULTATION(독립상담)';

-- 3. 상담 관련 컬럼 추가 (독립 상담용)
ALTER TABLE reservation
ADD COLUMN consultation_subject VARCHAR(100) NULL COMMENT '상담 제목',
ADD COLUMN consultation_content TEXT NULL COMMENT '상담 내용',
ADD COLUMN consultation_answer TEXT NULL COMMENT '파트너 답변',
ADD COLUMN consultation_status VARCHAR(20) DEFAULT 'NONE' COMMENT '상담 상태: PENDING(대기중)/ANSWERED(답변완료)',
ADD COLUMN consultation_requested_at DATETIME NULL COMMENT '상담 요청 일시',
ADD COLUMN consultation_answered_at DATETIME NULL COMMENT '답변 일시';

-- 4. 인덱스 추가 (성능 최적화)
CREATE INDEX idx_record_type ON reservation(record_type);
CREATE INDEX idx_consultation_status ON reservation(consultation_status);

-- 4. 변경 사항 확인
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
    AND (COLUMN_NAME LIKE 'consultation%' OR COLUMN_NAME = 'record_type')
ORDER BY ORDINAL_POSITION;

-- =====================================================
-- 실행 방법:
--
-- 옵션 1: MySQL Workbench / DBeaver에서 실행
-- 1. 데이터베이스에 연결
--    - Host: project-db-campus.smhrd.com
--    - Port: 3312
--    - Database: Insa6_aiservice_p3_2
--    - Username: Insa6_aiservice_p3_2
--    - Password: aischool2
-- 2. 위의 ALTER TABLE 명령문 실행
-- 3. SELECT 문으로 확인
--
-- 옵션 2: MySQL CLI에서 실행
-- mysql -u Insa6_aiservice_p3_2 -p -h project-db-campus.smhrd.com -P 3312 Insa6_aiservice_p3_2 < add_consultation_to_reservation.sql
-- =====================================================

-- =====================================================
-- 상담 상태 설명:
-- - PENDING: 상담 대기 중
-- - ANSWERED: 답변 완료
--
-- 레코드 타입 설명:
-- - RESERVATION: 일반 예약 레코드
-- - CONSULTATION: 독립 상담 레코드 (예약 없이)
-- =====================================================
