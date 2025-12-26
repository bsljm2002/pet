-- 파트너 갤러리 이미지 컬럼 추가
-- partners 테이블에 gallery_images 컬럼 추가 (최대 8개의 이미지 URL을 저장)

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

-- partners 테이블에 gallery_images 컬럼 추가
-- 컬럼이 이미 존재하면 에러가 발생하지만, 안전하게 처리됨
ALTER TABLE `partners`
ADD COLUMN `gallery_images` TEXT NULL COMMENT '갤러리 이미지 URL들 (최대 8개, 콤마 구분)';

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;
