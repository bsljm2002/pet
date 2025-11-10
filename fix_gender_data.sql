-- 사용자 테이블의 gender 값을 대문자로 변경
UPDATE users
SET gender = UPPER(gender)
WHERE gender IN ('male', 'female');

-- 확인
SELECT id, email, gender FROM users LIMIT 10;
