-- 채팅방 테이블 생성
CREATE TABLE IF NOT EXISTS chat_rooms (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    reservation_id BIGINT UNIQUE NOT NULL COMMENT '예약 ID (1:1 관계)',
    user_id BIGINT NOT NULL COMMENT '사용자 ID',
    partner_id BIGINT NOT NULL COMMENT '파트너 ID',
    service_type VARCHAR(20) NOT NULL COMMENT 'HOSPITAL 또는 SITTER',
    last_message TEXT COMMENT '마지막 메시지',
    last_message_time TIMESTAMP NULL COMMENT '마지막 메시지 시간',
    user_unread_count INT DEFAULT 0 COMMENT '사용자 읽지 않은 메시지 수',
    partner_unread_count INT DEFAULT 0 COMMENT '파트너 읽지 않은 메시지 수',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '채팅방 생성 시간',
    is_active BOOLEAN DEFAULT TRUE COMMENT '채팅방 활성 상태',

    -- 외래키 제약조건
    CONSTRAINT fk_chat_room_reservation FOREIGN KEY (reservation_id) REFERENCES reservations(id) ON DELETE CASCADE,
    CONSTRAINT fk_chat_room_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_chat_room_partner FOREIGN KEY (partner_id) REFERENCES users(id) ON DELETE CASCADE,

    -- 인덱스
    INDEX idx_user_id (user_id),
    INDEX idx_partner_id (partner_id),
    INDEX idx_reservation_id (reservation_id),
    INDEX idx_last_message_time (last_message_time)
);
