package com.example.pet.demo.chat.api;

import com.example.pet.demo.chat.api.dto.ChatRoomRes;
import com.example.pet.demo.chat.app.ChatRoomService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/chat-rooms")
@RequiredArgsConstructor
public class ChatRoomController {

    private final ChatRoomService chatRoomService;

    /**
     * 채팅방 목록 조회 (사용자 또는 파트너)
     * GET /api/v1/chat-rooms?userId=1 (일반 사용자)
     * GET /api/v1/chat-rooms?partnerId=1 (파트너)
     */
    @GetMapping
    public ResponseEntity<Map<String, Object>> getChatRooms(
        @RequestParam(value = "userId", required = false) Long userId,
        @RequestParam(value = "partnerId", required = false) Long partnerId
    ) {
        List<ChatRoomRes> chatRooms;

        if (partnerId != null) {
            // 파트너로 조회
            chatRooms = chatRoomService.getPartnerChatRooms(partnerId);
        } else if (userId != null) {
            // 일반 사용자로 조회
            chatRooms = chatRoomService.getUserChatRooms(userId);
        } else {
            // 파라미터가 없으면 빈 리스트 반환
            chatRooms = List.of();
        }

        return ResponseEntity.ok(Map.of(
            "ok", true,
            "data", chatRooms
        ));
    }
}
