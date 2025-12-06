-- Add disease_exam_id to reservation table
-- Run this manually in your MySQL database

USE Insa6_aiservice_p3_2;

-- AI 진단 기록 연결 컬럼 추가
ALTER TABLE reservation
ADD COLUMN disease_exam_id BIGINT NULL COMMENT 'AI 진단 기록 ID (FK → disease_exam.id)';

-- 외래키 제약조건 추가 (선택사항)
ALTER TABLE reservation
ADD CONSTRAINT fk_reservation_disease_exam
  FOREIGN KEY (disease_exam_id) REFERENCES disease_exam(id)
  ON DELETE SET NULL;

-- 인덱스 추가 (조회 성능 향상)
CREATE INDEX idx_reservation_disease_exam ON reservation(disease_exam_id);

-- 확인
DESCRIBE reservation;
