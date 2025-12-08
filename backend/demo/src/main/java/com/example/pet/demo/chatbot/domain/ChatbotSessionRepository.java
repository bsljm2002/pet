package com.example.pet.demo.chatbot.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChatbotSessionRepository extends JpaRepository<ChatbotSession, Long> {

    /**
     * 사용자의 모든 세션 조회 (최신순)
     */
    List<ChatbotSession> findByUserIdOrderByUpdatedAtDesc(Long userId);

    /**
     * 사용자의 세션 개수 조회
     */
    long countByUserId(Long userId);

    /**
     * 사용자의 가장 오래된 세션 조회
     */
    @Query("SELECT s FROM ChatbotSession s WHERE s.userId = :userId ORDER BY s.updatedAt ASC")
    List<ChatbotSession> findOldestByUserId(@Param("userId") Long userId);
}
