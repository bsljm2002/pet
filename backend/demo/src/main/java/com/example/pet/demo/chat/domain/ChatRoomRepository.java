package com.example.pet.demo.chat.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {

    /**
     * 예약 ID로 채팅방 조회
     */
    Optional<ChatRoom> findByReservationId(Long reservationId);

    /**
     * 사용자 ID로 채팅방 목록 조회 (활성화된 것만)
     */
    List<ChatRoom> findByUserIdAndIsActiveTrueOrderByLastMessageTimeDesc(Long userId);

    /**
     * 파트너 ID로 채팅방 목록 조회 (활성화된 것만)
     */
    List<ChatRoom> findByPartnerIdAndIsActiveTrueOrderByLastMessageTimeDesc(Long partnerId);

    /**
     * 예약 ID로 채팅방 존재 여부 확인
     */
    boolean existsByReservationId(Long reservationId);
}
