package com.example.pet.demo.chatbot.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChatbotMessageRepository extends JpaRepository<ChatbotMessage, Long> {

    /**
     * 세션의 모든 메시지 조회 (시간순)
     */
    List<ChatbotMessage> findBySessionIdOrderByCreatedAtAsc(Long sessionId);

    /**
     * 세션의 메시지 삭제
     */
    void deleteBySessionId(Long sessionId);

    /**
     * 세션의 메시지 개수
     */
    long countBySessionId(Long sessionId);
}
