package com.example.pet.demo.chatbot.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

public class ChatbotDto {

    /**
     * 세션 생성 요청
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CreateSessionRequest {
        private String title;
    }

    /**
     * 메시지 추가 요청
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AddMessageRequest {
        private String content;
        private Boolean isUser;
    }

    /**
     * 세션 응답
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SessionResponse {
        private Long id;
        private String title;
        private int messageCount;
        private String lastMessage;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;
    }

    /**
     * 세션 상세 응답 (메시지 포함)
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SessionDetailResponse {
        private Long id;
        private String title;
        private List<MessageResponse> messages;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;
    }

    /**
     * 메시지 응답
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MessageResponse {
        private Long id;
        private String content;
        private Boolean isUser;
        private LocalDateTime createdAt;
    }

    /**
     * 세션 목록 응답
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SessionListResponse {
        private List<SessionResponse> sessions;
        private int totalCount;
    }
}
