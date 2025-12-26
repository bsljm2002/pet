-- LLM 펫 이모티콘 테이블 생성 SQL
-- 기존 테이블이 있다면 삭제하고 다시 생성

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

-- 기존 테이블 삭제
DROP TABLE IF EXISTS `llm_pet_emojis`;

-- 테이블 생성
CREATE TABLE `llm_pet_emojis` (
  `id`                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'PK',
  `pet_id`                BIGINT UNSIGNED NULL COMMENT '펫 ID (FK → pets.id, nullable)',
  `user_id`               BIGINT UNSIGNED NOT NULL COMMENT '요청자 ID (FK → users.id)',
  `source_image_url`      VARCHAR(512) NOT NULL COMMENT '원본 이미지 URL',
  `prompt_meta`           JSON NULL COMMENT '프롬프트 메타데이터 (스타일, 감정 등)',
  `status`                ENUM('REQUESTED','PROCESSING','SUCCEEDED','FAILED') NOT NULL DEFAULT 'REQUESTED' COMMENT '상태',
  `generated_image_url`   VARCHAR(512) NULL COMMENT '생성된 이모티콘 URL',
  `failure_reason`        VARCHAR(1000) NULL COMMENT '실패 사유',
  `created_at`            DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '생성 시각',
  `updated_at`            DATETIME(3) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '갱신 시각',

  PRIMARY KEY (`id`),
  
  KEY `idx_llm_pet_emojis_user_id` (`user_id`),
  KEY `idx_llm_pet_emojis_pet_id` (`pet_id`),
  KEY `idx_llm_pet_emojis_status` (`status`),
  KEY `idx_llm_pet_emojis_created` (`created_at`),

  CONSTRAINT `fk_llm_pet_emojis_pet_id__pets_id`
    FOREIGN KEY (`pet_id`) REFERENCES `pets`(`id`)
    ON DELETE SET NULL,
    
  CONSTRAINT `fk_llm_pet_emojis_user_id__users_id`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
    ON DELETE CASCADE
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='LLM 펫 이모티콘 생성 요청';

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;

