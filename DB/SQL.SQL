SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS `users` (
  `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '기본키(PK)',

  `username`            VARCHAR(20)  NOT NULL COMMENT '아이디',
  `email`               VARCHAR(255) NOT NULL COMMENT '이메일',
  `password`            VARCHAR(255) NOT NULL COMMENT '비밀번호 해시',
  `nickname`            VARCHAR(50)  NOT NULL COMMENT '닉네임(UNIQUE, FK 대상)',

  `gender`              VARCHAR(10)  NOT NULL COMMENT '성별',
  `birthdate`           DATE     NOT NULL COMMENT '생년월일',
  `address`             VARCHAR(255) NULL     COMMENT '주소',

  `user_type`           ENUM('GENERAL','SELLER','HOSPITAL','GROOMING','SITTER','CAFE')
                        NOT NULL COMMENT '사용자 타입(general/seller/hospital/grooming/sitter/cafe)',
  `status`              ENUM('ACTIVE','LOCKED','DELETED')
                        NOT NULL COMMENT '계정 상태(ACTIVE/LOCKED/DELETED)',

  `tin`                 VARCHAR(50)  NULL     COMMENT '사업자등록번호',
  `business_address`    VARCHAR(255) NULL     COMMENT '사업장 주소',

  `ca_categorical`      ENUM('DOG','CAT','BOTH') NULL COMMENT '개/고양이/둘',
  `vet_specialty`       ENUM(
                          'INTERNAL_MEDICINE',   -- 내과
                          'SURGERY',             -- 외과
                          'ORTHOPEDICS',         -- 정형외과
                          'OPHTHALMOLOGY',       -- 안과
                          'DENTISTRY',           -- 치과
                          'DERMATOLOGY',         -- 피부과
                          'EMERGENCY_MEDICINE'   -- 응급의학과
                        ) NULL COMMENT '진료과목',
  `petsitter_work`      ENUM('WALK','TRANSPORT','HYGIENE','ALL') NULL COMMENT '펫시터 업무(산책/이동/위생관리/전체)',

  `working_days`        DATETIME     NULL     COMMENT '근무가능요일(스펙 유지)',
  `working_start_hours` VARCHAR(10)  NULL     COMMENT '근무 시작시간 예: 09:00',
  `working_end_hours`   VARCHAR(10)  NULL     COMMENT '근무 종료시간 예: 18:00',

  `locked_until`        DATETIME     NULL     COMMENT '잠금 해제 시각(블루투스 대응 등)',
  `last_login_at`       DATETIME     NULL     COMMENT '마지막 로그인 시각',

  `created_at`          DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '생성 시각',
  `updated_at`          DATETIME(3)  NULL     DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '갱신 시각',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users_nickname` (`nickname`),
  UNIQUE KEY `uk_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
  COMMENT='사용자 테이블';

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS `pets` (
  `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`      BIGINT UNSIGNED NOT NULL,
  `species`      ENUM('DOG','CAT') NOT NULL,
  `p_birthdate`  DATE NOT NULL,
  `weight`       DECIMAL(4,1) NOT NULL,
  `abti_type_code` ENUM('ISTJ','ISFJ','INFJ','INTJ','ISTP','ISFP','INFP','INTP',
                        'ESTP','ESFP','ENFP','ENTP','ESTJ','ESFJ','ENFJ','ENTJ') NULL,
  `p_image_url`  VARCHAR(2048) NOT NULL,
  `p_name`       VARCHAR(20) NOT NULL,
  `created_at`   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at`   DATETIME(3) NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),

  UNIQUE KEY `uk_pets_user_name` (`user_id`, `p_name`),

  CONSTRAINT `fk_pets_user_id__users_id`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='반려동물 프로필';

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS `diary` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '다이어리 ID(PK)',
  `title`         VARCHAR(100)    NOT NULL COMMENT '제목',
  `content`       TEXT            NOT NULL COMMENT '본문',
  `pd_image_url`  VARCHAR(2048)   NOT NULL COMMENT '다이어리 이미지 URL',
  `created_at`    DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '생성 시각',
  `pet_id`        BIGINT UNSIGNED NOT NULL COMMENT '반려동물 ID (FK → pets.id)',

  PRIMARY KEY (`id`),

  -- 조회 성능용 보조 인덱스
  KEY `idx_diary_pet_id`   (`pet_id`),
  KEY `idx_diary_created`  (`created_at`),

  -- FK: pets.id (PK)
  CONSTRAINT `fk_diary_pet_id__pets_id`
    FOREIGN KEY (`pet_id`) REFERENCES `pets`(`id`)
    ON DELETE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='반려동물 다이어리';

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS `disease_exam` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'PK',
  `user_id`        BIGINT UNSIGNED NOT NULL COMMENT 'FK → users.id',
  `pet_id`         BIGINT UNSIGNED NOT NULL COMMENT 'FK → pets.id',

  `requested_type` ENUM('EYE','SKIN','OBESITY') NOT NULL COMMENT '요청 유형',
  `summary_label`  ENUM('NORMAL','SUSPECT','CAUTION') NOT NULL COMMENT '최종 요약 판정',
  `disease_result` JSON          NOT NULL COMMENT '모델 결과(JSON)',
  `d_image_url`    VARCHAR(2048) NOT NULL COMMENT '질병 사진 URL',

  `created_at`     DATETIME(3)   NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '생성 시각',
  `deleted_at`     DATETIME      NULL     COMMENT '삭제 시각(소프트삭제)',

  PRIMARY KEY (`id`),

  -- 조회 최적화 인덱스
  KEY `idx_disease_exam_user_id` (`user_id`),
  KEY `idx_disease_exam_pet_id`  (`pet_id`),
  KEY `idx_disease_exam_created` (`created_at`),

  -- 외래키
  CONSTRAINT `fk_disexam_user_id__users_id`
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_disexam_pet_id__pets_id`
    FOREIGN KEY (`pet_id`)  REFERENCES `pets`(`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=
utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='질병 검사';
COMMIT;
SET FOREIGN_KEY_CHECKS = 1;

-- Safe defaults (선택)
SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS `article` (
  `id`                   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '게시글 ID(PK)',
  `author_user_id`       BIGINT UNSIGNED NOT NULL COMMENT '작성자 FK → users.id',

  `title`                TEXT         NOT NULL COMMENT '제목',
  `content_categorical`  ENUM('GUIDE','CAFE','SHOP','HOSPITAL','NOTICE','COMMUNITY')
                         NOT NULL COMMENT '분류',
  `content`              TEXT         NOT NULL COMMENT '본문',

  `read_count`           INT          NOT NULL DEFAULT 0 COMMENT '조회수',
  `like_count`           INT          NOT NULL DEFAULT 0 COMMENT '좋아요 수',
  `comment_count`        INT          NOT NULL DEFAULT 0 COMMENT '댓글 수',

  `article_image_url`    VARCHAR(2048)         NULL COMMENT '대표 이미지 URL(옵션)',
  `user_nickname`        VARCHAR(50)  NOT NULL COMMENT '작성자 닉네임(표시용)',

  `created_at`           DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '생성 시각',
  `updated_at`           DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
                                        ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '갱신 시각',

  PRIMARY KEY (`id`),

  KEY `idx_article_author`   (`author_user_id`),
  KEY `idx_article_created`  (`created_at`),
  KEY `idx_article_category` (`content_categorical`),

  CONSTRAINT `fk_article_author__users_id`
    FOREIGN KEY (`author_user_id`) REFERENCES `users`(`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='게시물';

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;

-- Safe defaults(선택)
SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

CREATE TABLE IF NOT EXISTS `reservation` (
  `id`                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'PK',
  `user_id`             BIGINT UNSIGNED NOT NULL COMMENT '예약자 FK → users.id',
  `partner_id`          BIGINT UNSIGNED NOT NULL COMMENT '파트너 FK → users.id',
  `service_categorical` ENUM('HOSPITAL','GROOMING','CAFE') NOT NULL COMMENT '서비스 카테고리',
  `status`              ENUM('WAITING','CONFIRMED','CHECKED_IN','COMPLETED',
                             'CANCELLED_BY_USER','CANCELLED_BY_BIZ')
                        NOT NULL DEFAULT 'WAITING' COMMENT '예약상태',
  `created_at`          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '예약시간',
  `canceled_at`         DATETIME    NULL COMMENT '취소시간',

  PRIMARY KEY (`id`),

  KEY `idx_reservation_user`       (`user_id`),
  KEY `idx_reservation_partner`    (`partner_id`),
  KEY `idx_reservation_created`    (`created_at`),
  KEY `idx_reservation_status`     (`status`),
  -- (선택) 사용자-파트너-시간 동시 조회 최적화
  -- KEY `idx_reservation_user_partner_created` (`user_id`,`partner_id`,`created_at`),

  CONSTRAINT `fk_reservation_user_id__users_id`
    FOREIGN KEY (`user_id`)   REFERENCES `users`(`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_reservation_partner_id__users_id`
    FOREIGN KEY (`partner_id`) REFERENCES `users`(`id`)
    ON DELETE CASCADE,

  -- 취소 상태면 canceled_at 필수
  CHECK (
    `status` NOT IN ('CANCELLED_BY_USER','CANCELLED_BY_BIZ')
    OR `canceled_at` IS NOT NULL
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
COMMENT='예약';

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE IF NOT EXISTS `llm_pet_emojis` (
    `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `pet_id`        BIGINT UNSIGNED NULL COMMENT 'pets.id (사진 주인)',
    `user_id`       BIGINT UNSIGNED NOT NULL COMMENT '요청자 users.id',
    `image_url`     VARCHAR(512) NOT NULL COMMENT '원본 반려동물 이미지 경로',
    `model_name`    VARCHAR(100) NOT NULL COMMENT '사용된 LLM/이미지 모델',
    `prompt_meta`   JSON NULL COMMENT '품종/감정/스타일 등 프롬프트 구성요소',
    `status`        ENUM('REQUESTED','PROCESSING','SUCCEEDED','FAILED') NOT NULL DEFAULT 'REQUESTED',
    `emoji_url`     VARCHAR(512) NOT NULL COMMENT '생성된 이모지 이미지 경로',
    `error_message` VARCHAR(1000) NULL,
    `confidence`    DECIMAL(5,2) NULL COMMENT '신뢰도 (0~100)',
    `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_pet` (`pet_id`),
    KEY `idx_user` (`user_id`, `status`),
    KEY `idx_status_created` (`status`, `created_at`),
    CONSTRAINT `fk_llm_pet` FOREIGN KEY (`pet_id`) REFERENCES `pets`(`id`),
    CONSTRAINT `fk_llm_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;

