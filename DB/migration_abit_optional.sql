-- ABTI를 선택 사항으로 변경하는 마이그레이션
-- 실행 전에 데이터베이스 백업을 권장합니다

-- 1. 컬럼명이 abti_type_code인 경우 abit_type_code로 변경하고 NULL 허용
ALTER TABLE `pets`
CHANGE COLUMN `abti_type_code` `abit_type_code`
ENUM('ISTJ','ISFJ','INFJ','INTJ','ISTP','ISFP','INFP','INTP','ESTP','ESFP','ENFP','ENTP','ESTJ','ESFJ','ENFJ','ENTJ') NULL;

-- 2. 만약 컬럼명이 이미 abit_type_code인 경우 NULL만 허용하도록 변경
-- (위 명령이 실패하면 이 명령을 대신 실행)
-- ALTER TABLE `pets`
-- MODIFY COLUMN `abit_type_code`
-- ENUM('ISTJ','ISFJ','INFJ','INTJ','ISTP','ISFP','INFP','INTP','ESTP','ESFP','ENFP','ENTP','ESTJ','ESFJ','ENFJ','ENTJ') NULL;
