-- 상담 테이블 생성 SQL
CREATE TABLE IF NOT EXISTS consultations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '상담 ID',
    user_id BIGINT NOT NULL COMMENT '고객 ID (users 테이블 FK)',
    partner_id BIGINT NOT NULL COMMENT '파트너 ID (partners 테이블 FK)',
    reservation_id BIGINT NULL COMMENT '연결된 예약 ID (선택적, reservations 테이블 FK)',
    pet_type VARCHAR(20) NOT NULL COMMENT '반려동물 종류 (강아지, 고양이 등)',
    subject VARCHAR(100) NOT NULL COMMENT '상담 제목',
    content TEXT NOT NULL COMMENT '상담 내용',
    image_url VARCHAR(500) NULL COMMENT '첨부 이미지 URL (선택적)',
    answer TEXT NULL COMMENT '파트너 답변',
    answered_at DATETIME NULL COMMENT '답변 일시',
    status ENUM('PENDING', 'ANSWERED', 'CLOSED', 'CANCELLED')
        NOT NULL DEFAULT 'PENDING'
        COMMENT '상담 상태 (PENDING: 대기중, ANSWERED: 답변완료, CLOSED: 종료, CANCELLED: 취소)',
    created_at DATETIME NOT NULL COMMENT '생성 일시',

    -- 외래키 제약 조건
    FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE
        COMMENT '사용자 삭제 시 상담도 삭제',

    FOREIGN KEY (partner_id) REFERENCES partners(id)
        ON DELETE CASCADE
        COMMENT '파트너 삭제 시 상담도 삭제',

    FOREIGN KEY (reservation_id) REFERENCES reservations(id)
        ON DELETE SET NULL
        COMMENT '예약 삭제 시 상담은 유지하고 연결만 해제',

    -- 인덱스
    INDEX idx_user_id (user_id),
    INDEX idx_partner_id (partner_id),
    INDEX idx_reservation_id (reservation_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='간편 상담 테이블';
