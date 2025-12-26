package com.example.pet.demo.chat.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

/**
 * 채팅 메시지 엔티티
 */
@Entity
@Table(name = "chat_messages")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * 채팅방 ID
     */
    @Column(nullable = false)
    private Long chatRoomId;

    /**
     * 발신자 ID
     */
    @Column(nullable = false)
    private Long senderId;

    /**
     * 발신자 타입 (USER, PARTNER)
     */
    @Column(nullable = false, length = 10)
    private String senderType;

    /**
     * 메시지 내용
     */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;

    /**
     * 메시지 타입 (TEXT, IMAGE)
     */
    @Column(nullable = false, length = 10)
    @Builder.Default
    private String messageType = "TEXT";

    /**
     * 이미지 URL (messageType이 IMAGE일 때)
     */
    @Column
    private String imageUrl;

    /**
     * 메시지 전송 시간
     */
    @Column(nullable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    /**
     * 읽음 여부
     */
    @Column
    @Builder.Default
    private Boolean isRead = false;

    /**
     * 읽은 시간
     */
    @Column
    private OffsetDateTime readAt;

    /**
     * 메시지를 읽음으로 표시
     */
    public void markAsRead() {
        this.isRead = true;
        this.readAt = OffsetDateTime.now();
    }
}
