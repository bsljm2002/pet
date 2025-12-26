package com.example.pet.demo.chatbot.application;

import com.example.pet.demo.chatbot.api.dto.ChatbotDto;
import com.example.pet.demo.chatbot.domain.ChatbotMessage;
import com.example.pet.demo.chatbot.domain.ChatbotMessageRepository;
import com.example.pet.demo.chatbot.domain.ChatbotSession;
import com.example.pet.demo.chatbot.domain.ChatbotSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ChatbotService {

    private final ChatbotSessionRepository sessionRepository;
    private final ChatbotMessageRepository messageRepository;

    private static final int MAX_SESSIONS_PER_USER = 50;

    /**
     * 사용자의 모든 세션 조회
     */
    public ChatbotDto.SessionListResponse getSessions(Long userId) {
        List<ChatbotSession> sessions = sessionRepository.findByUserIdOrderByUpdatedAtDesc(userId);

        List<ChatbotDto.SessionResponse> sessionResponses = sessions.stream()
                .map(this::toSessionResponse)
                .collect(Collectors.toList());

        return ChatbotDto.SessionListResponse.builder()
                .sessions(sessionResponses)
                .totalCount(sessionResponses.size())
                .build();
    }

    /**
     * 세션 상세 조회 (메시지 포함)
     */
    public ChatbotDto.SessionDetailResponse getSessionDetail(Long sessionId, Long userId) {
        ChatbotSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("세션을 찾을 수 없습니다."));

        if (!session.getUserId().equals(userId)) {
            throw new IllegalArgumentException("접근 권한이 없습니다.");
        }

        List<ChatbotMessage> messages = messageRepository.findBySessionIdOrderByCreatedAtAsc(sessionId);

        List<ChatbotDto.MessageResponse> messageResponses = messages.stream()
                .map(this::toMessageResponse)
                .collect(Collectors.toList());

        return ChatbotDto.SessionDetailResponse.builder()
                .id(session.getId())
                .title(session.getTitle())
                .messages(messageResponses)
                .createdAt(session.getCreatedAt())
                .updatedAt(session.getUpdatedAt())
                .build();
    }

    /**
     * 새 세션 생성
     */
    @Transactional
    public ChatbotDto.SessionResponse createSession(Long userId, ChatbotDto.CreateSessionRequest request) {
        // 최대 세션 수 체크 및 오래된 세션 삭제
        long sessionCount = sessionRepository.countByUserId(userId);
        if (sessionCount >= MAX_SESSIONS_PER_USER) {
            List<ChatbotSession> oldestSessions = sessionRepository.findOldestByUserId(userId);
            if (!oldestSessions.isEmpty()) {
                deleteSession(oldestSessions.get(0).getId(), userId);
            }
        }

        String title = request.getTitle();
        if (title == null || title.trim().isEmpty()) {
            title = "새 대화";
        }

        ChatbotSession session = ChatbotSession.builder()
                .userId(userId)
                .title(title)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        ChatbotSession savedSession = sessionRepository.save(session);
        return toSessionResponse(savedSession);
    }

    /**
     * 메시지 추가
     */
    @Transactional
    public ChatbotDto.MessageResponse addMessage(Long sessionId, Long userId, ChatbotDto.AddMessageRequest request) {
        ChatbotSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("세션을 찾을 수 없습니다."));

        if (!session.getUserId().equals(userId)) {
            throw new IllegalArgumentException("접근 권한이 없습니다.");
        }

        ChatbotMessage message = ChatbotMessage.builder()
                .sessionId(sessionId)
                .content(request.getContent())
                .isUser(request.getIsUser())
                .createdAt(LocalDateTime.now())
                .build();

        ChatbotMessage savedMessage = messageRepository.save(message);

        // 세션 업데이트 시간 갱신
        session.setUpdatedAt(LocalDateTime.now());

        // 첫 번째 사용자 메시지인 경우 제목 업데이트
        if (request.getIsUser() && "새 대화".equals(session.getTitle())) {
            String newTitle = request.getContent();
            if (newTitle.length() > 30) {
                newTitle = newTitle.substring(0, 30) + "...";
            }
            session.setTitle(newTitle);
        }

        sessionRepository.save(session);

        return toMessageResponse(savedMessage);
    }

    /**
     * 세션 삭제
     */
    @Transactional
    public void deleteSession(Long sessionId, Long userId) {
        ChatbotSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("세션을 찾을 수 없습니다."));

        if (!session.getUserId().equals(userId)) {
            throw new IllegalArgumentException("접근 권한이 없습니다.");
        }

        // 메시지 먼저 삭제
        messageRepository.deleteBySessionId(sessionId);
        // 세션 삭제
        sessionRepository.delete(session);
    }

    /**
     * 세션 제목 수정
     */
    @Transactional
    public ChatbotDto.SessionResponse updateSessionTitle(Long sessionId, Long userId, String newTitle) {
        ChatbotSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("세션을 찾을 수 없습니다."));

        if (!session.getUserId().equals(userId)) {
            throw new IllegalArgumentException("접근 권한이 없습니다.");
        }

        session.setTitle(newTitle);
        session.setUpdatedAt(LocalDateTime.now());
        ChatbotSession updatedSession = sessionRepository.save(session);

        return toSessionResponse(updatedSession);
    }

    private ChatbotDto.SessionResponse toSessionResponse(ChatbotSession session) {
        long messageCount = messageRepository.countBySessionId(session.getId());
        List<ChatbotMessage> messages = messageRepository.findBySessionIdOrderByCreatedAtAsc(session.getId());
        String lastMessage = messages.isEmpty() ? "" : messages.get(messages.size() - 1).getContent();
        if (lastMessage.length() > 50) {
            lastMessage = lastMessage.substring(0, 50) + "...";
        }

        return ChatbotDto.SessionResponse.builder()
                .id(session.getId())
                .title(session.getTitle())
                .messageCount((int) messageCount)
                .lastMessage(lastMessage)
                .createdAt(session.getCreatedAt())
                .updatedAt(session.getUpdatedAt())
                .build();
    }

    private ChatbotDto.MessageResponse toMessageResponse(ChatbotMessage message) {
        return ChatbotDto.MessageResponse.builder()
                .id(message.getId())
                .content(message.getContent())
                .isUser(message.getIsUser())
                .createdAt(message.getCreatedAt())
                .build();
    }
}
