package com.example.pet.demo.chat.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

/**
 * 채팅방 엔티티
 * 예약이 확정되면 자동으로 생성됨
 */
@Entity
@Table(name = "chat_rooms")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatRoom {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * 연결된 예약 ID
     */
    @Column(nullable = false, unique = true)
    private Long reservationId;

    /**
     * 사용자 ID
     */
    @Column(nullable = false)
    private Long userId;

    /**
     * 파트너 ID (User ID)
     */
    @Column(nullable = false)
    private Long partnerId;

    /**
     * 서비스 타입 (HOSPITAL, SITTER)
     */
    @Column(nullable = false, length = 20)
    private String serviceType;

    /**
     * 마지막 메시지
     */
    @Column(columnDefinition = "TEXT")
    private String lastMessage;

    /**
     * 마지막 메시지 시간
     */
    @Column
    private OffsetDateTime lastMessageTime;

    /**
     * 사용자의 읽지 않은 메시지 수
     */
    @Column
    @Builder.Default
    private Integer userUnreadCount = 0;

    /**
     * 파트너의 읽지 않은 메시지 수
     */
    @Column
    @Builder.Default
    private Integer partnerUnreadCount = 0;

    /**
     * 채팅방 생성 시간
     */
    @Column(nullable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    /**
     * 채팅방 활성 상태
     */
    @Column
    @Builder.Default
    private Boolean isActive = true;

    public void updateLastMessage(String message, OffsetDateTime time) {
        this.lastMessage = message;
        this.lastMessageTime = time;
    }

    public void incrementUserUnreadCount() {
        this.userUnreadCount++;
    }

    public void incrementPartnerUnreadCount() {
        this.partnerUnreadCount++;
    }

    public void resetUserUnreadCount() {
        this.userUnreadCount = 0;
    }

    public void resetPartnerUnreadCount() {
        this.partnerUnreadCount = 0;
    }
}
