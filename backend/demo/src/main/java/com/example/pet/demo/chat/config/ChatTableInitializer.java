package com.example.pet.demo.chat.config;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * 채팅방 테이블 초기화
 * 애플리케이션 시작 시 chat_rooms 테이블이 없으면 생성
 */
@Component
@RequiredArgsConstructor
@Order(1)
public class ChatTableInitializer implements CommandLineRunner {

    private final JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) {
        try {
            // chat_rooms 테이블이 존재하는지 확인
            jdbcTemplate.queryForObject(
                "SELECT 1 FROM chat_rooms LIMIT 1",
                Integer.class
            );
            System.out.println("✅ chat_rooms 테이블이 이미 존재합니다.");
        } catch (Exception e) {
            // 테이블이 없으면 생성
            System.out.println("📋 chat_rooms 테이블을 생성합니다...");
            createChatRoomsTable();
        }
    }

    private void createChatRoomsTable() {
        String sql = """
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

                INDEX idx_user_id (user_id),
                INDEX idx_partner_id (partner_id),
                INDEX idx_reservation_id (reservation_id),
                INDEX idx_last_message_time (last_message_time)
            )
            """;

        try {
            jdbcTemplate.execute(sql);
            System.out.println("✅ chat_rooms 테이블 생성 완료!");

            // 외래키 제약조건 추가 시도 (이미 존재하면 무시)
            try {
                jdbcTemplate.execute(
                    "ALTER TABLE chat_rooms " +
                    "ADD CONSTRAINT fk_chat_room_reservation " +
                    "FOREIGN KEY (reservation_id) REFERENCES reservations(id) ON DELETE CASCADE"
                );
            } catch (Exception ex) {
                System.out.println("⚠️ FK 제약조건 추가 건너뜀 (이미 존재하거나 권한 없음)");
            }

            try {
                jdbcTemplate.execute(
                    "ALTER TABLE chat_rooms " +
                    "ADD CONSTRAINT fk_chat_room_user " +
                    "FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE"
                );
            } catch (Exception ex) {
                System.out.println("⚠️ FK 제약조건 추가 건너뜀 (이미 존재하거나 권한 없음)");
            }

            try {
                jdbcTemplate.execute(
                    "ALTER TABLE chat_rooms " +
                    "ADD CONSTRAINT fk_chat_room_partner " +
                    "FOREIGN KEY (partner_id) REFERENCES users(id) ON DELETE CASCADE"
                );
            } catch (Exception ex) {
                System.out.println("⚠️ FK 제약조건 추가 건너뜀 (이미 존재하거나 권한 없음)");
            }

        } catch (Exception e) {
            System.err.println("❌ chat_rooms 테이블 생성 실패: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
