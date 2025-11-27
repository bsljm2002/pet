package com.example.pet.demo.chat.app;

import com.example.pet.demo.chat.api.dto.ChatRoomRes;
import com.example.pet.demo.chat.domain.ChatRoom;
import com.example.pet.demo.chat.domain.ChatRoomRepository;
import com.example.pet.demo.partner.domain.Partner;
import com.example.pet.demo.partner.domain.PartnerRepository;
import com.example.pet.demo.users.app.UserService;
import com.example.pet.demo.users.domain.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ChatRoomService {

    private final ChatRoomRepository chatRoomRepository;
    private final UserService userService;
    private final PartnerRepository partnerRepository;

    /**
     * 사용자의 채팅방 목록 조회
     */
    public List<ChatRoomRes> getUserChatRooms(Long userId) {
        List<ChatRoom> chatRooms = chatRoomRepository
            .findByUserIdAndIsActiveTrueOrderByLastMessageTimeDesc(userId);

        return chatRooms.stream()
            .map(this::toChatRoomRes)
            .toList();
    }

    /**
     * 파트너의 채팅방 목록 조회
     */
    public List<ChatRoomRes> getPartnerChatRooms(Long partnerId) {
        List<ChatRoom> chatRooms = chatRoomRepository
            .findByPartnerIdAndIsActiveTrueOrderByLastMessageTimeDesc(partnerId);

        return chatRooms.stream()
            .map(this::toChatRoomRes)
            .toList();
    }

    private ChatRoomRes toChatRoomRes(ChatRoom chatRoom) {
        // 파트너 정보 조회
        String partnerName = "알 수 없음";
        String partnerImageUrl = null;

        try {
            User partnerUser = userService.get(chatRoom.getPartnerId());
            partnerName = partnerUser.getUsername();

            // Partner 테이블에서 이미지 조회
            List<Partner> partners = partnerRepository.findByUserId(chatRoom.getPartnerId());
            if (!partners.isEmpty()) {
                partnerImageUrl = partners.get(0).getImageUrl();
            }
        } catch (Exception e) {
            System.out.println("⚠️ 파트너 정보 조회 실패: " + e.getMessage());
        }

        return new ChatRoomRes(
            chatRoom.getId(),
            chatRoom.getReservationId(),
            chatRoom.getUserId(),
            chatRoom.getPartnerId(),
            partnerName,
            partnerImageUrl,
            chatRoom.getLastMessage(),
            chatRoom.getLastMessageTime(),
            chatRoom.getUserUnreadCount(),
            chatRoom.getServiceType(),
            chatRoom.getCreatedAt()
        );
    }
}
