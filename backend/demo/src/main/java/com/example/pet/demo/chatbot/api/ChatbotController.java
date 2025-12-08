package com.example.pet.demo.chatbot.api;

import com.example.pet.demo.chatbot.api.dto.ChatbotDto;
import com.example.pet.demo.chatbot.application.ChatbotService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/chatbot")
@RequiredArgsConstructor
public class ChatbotController {

    private final ChatbotService chatbotService;

    /**
     * 사용자의 모든 채팅 세션 조회
     */
    @GetMapping("/sessions")
    public ResponseEntity<ChatbotDto.SessionListResponse> getSessions(
            @RequestParam Long userId) {
        return ResponseEntity.ok(chatbotService.getSessions(userId));
    }

    /**
     * 특정 세션 상세 조회 (메시지 포함)
     */
    @GetMapping("/sessions/{sessionId}")
    public ResponseEntity<ChatbotDto.SessionDetailResponse> getSessionDetail(
            @PathVariable Long sessionId,
            @RequestParam Long userId) {
        return ResponseEntity.ok(chatbotService.getSessionDetail(sessionId, userId));
    }

    /**
     * 새 세션 생성
     */
    @PostMapping("/sessions")
    public ResponseEntity<ChatbotDto.SessionResponse> createSession(
            @RequestParam Long userId,
            @RequestBody ChatbotDto.CreateSessionRequest request) {
        return ResponseEntity.ok(chatbotService.createSession(userId, request));
    }

    /**
     * 세션에 메시지 추가
     */
    @PostMapping("/sessions/{sessionId}/messages")
    public ResponseEntity<ChatbotDto.MessageResponse> addMessage(
            @PathVariable Long sessionId,
            @RequestParam Long userId,
            @RequestBody ChatbotDto.AddMessageRequest request) {
        return ResponseEntity.ok(chatbotService.addMessage(sessionId, userId, request));
    }

    /**
     * 세션 삭제
     */
    @DeleteMapping("/sessions/{sessionId}")
    public ResponseEntity<Void> deleteSession(
            @PathVariable Long sessionId,
            @RequestParam Long userId) {
        chatbotService.deleteSession(sessionId, userId);
        return ResponseEntity.noContent().build();
    }

    /**
     * 세션 제목 수정
     */
    @PatchMapping("/sessions/{sessionId}/title")
    public ResponseEntity<ChatbotDto.SessionResponse> updateSessionTitle(
            @PathVariable Long sessionId,
            @RequestParam Long userId,
            @RequestParam String title) {
        return ResponseEntity.ok(chatbotService.updateSessionTitle(sessionId, userId, title));
    }
}
