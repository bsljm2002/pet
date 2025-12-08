package com.example.pet.demo.chatbot.domain;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "chatbot_messages")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatbotMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "session_id", nullable = false)
    private Long sessionId;

    @Column(name = "content", nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(name = "is_user", nullable = false)
    private Boolean isUser;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
