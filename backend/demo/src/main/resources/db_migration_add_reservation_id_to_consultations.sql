-- =====================================================
-- 상담 테이블에 예약 ID 컬럼 추가
-- 날짜: 2025-11-25
-- 목적: 예약과 상담 기능 연동
-- =====================================================

-- 1. reservation_id 컬럼 추가 (NULL 허용)
ALTER TABLE consultations
ADD COLUMN reservation_id BIGINT NULL AFTER user_id
COMMENT '연결된 예약 ID (선택적)';

-- 2. 성능 향상을 위한 인덱스 생성
CREATE INDEX idx_reservation_id ON consultations(reservation_id);

-- 3. 변경 사항 확인
SELECT
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_COMMENT
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'consultations'
    AND COLUMN_NAME = 'reservation_id';

-- =====================================================
-- 실행 방법:
--
-- 옵션 1: MySQL CLI에서 실행
-- mysql -u Insa6_aiservice_p3_2 -p -h project-db-campus.smhrd.com -P 3312 Insa6_aiservice_p3_2 < db_migration_add_reservation_id_to_consultations.sql
--
-- 옵션 2: MySQL Workbench나 DBeaver에서 실행
-- 1. 데이터베이스에 연결
-- 2. 위의 ALTER TABLE과 CREATE INDEX 명령문 실행
-- 3. SELECT 문으로 확인
--
-- 옵션 3: Spring Boot application 실행 전 수동 실행
-- =====================================================
