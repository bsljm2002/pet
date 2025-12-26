package com.example.pet.demo.chat.config;

import com.example.pet.demo.chat.domain.ChatRoom;
import com.example.pet.demo.chat.domain.ChatRoomRepository;
import com.example.pet.demo.reservation.domain.Reservation;
import com.example.pet.demo.reservation.domain.Reservation.ReservationStatus;
import com.example.pet.demo.reservation.domain.ReservationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.time.OffsetDateTime;
import java.util.List;

/**
 * 기존 확정된 예약에 대한 채팅방 자동 생성
 * 테이블 생성 후 한 번만 실행됨
 */
@Component
@RequiredArgsConstructor
@Order(2)
public class ChatRoomBackfillInitializer implements CommandLineRunner {

    private final ReservationRepository reservationRepository;
    private final ChatRoomRepository chatRoomRepository;

    @Override
    public void run(String... args) {
        try {
            System.out.println("📋 기존 확정 예약에 대한 채팅방 생성 확인 중...");

            // 모든 예약 조회
            List<Reservation> allReservations = reservationRepository.findAll();

            int createdCount = 0;
            int existingCount = 0;
            int skippedCount = 0;

            for (Reservation reservation : allReservations) {
                // 확정된 예약만 처리
                if (reservation.getStatus() != ReservationStatus.CONFIRMED) {
                    skippedCount++;
                    continue;
                }

                // 이미 채팅방이 있는지 확인
                if (chatRoomRepository.existsByReservationId(reservation.getId())) {
                    existingCount++;
                    continue;
                }

                // 채팅방 생성
                ChatRoom chatRoom = ChatRoom.builder()
                    .reservationId(reservation.getId())
                    .userId(reservation.getUserId())
                    .partnerId(reservation.getPartnerId())
                    .serviceType(reservation.getServiceCategorical().name())
                    .createdAt(OffsetDateTime.now())
                    .isActive(true)
                    .build();

                chatRoomRepository.save(chatRoom);
                createdCount++;
            }

            System.out.println(
                String.format(
                    "✅ 채팅방 백필 완료: 신규 생성 %d개, 기존 %d개, 미확정 %d개",
                    createdCount,
                    existingCount,
                    skippedCount
                )
            );

        } catch (Exception e) {
            System.err.println("⚠️ 채팅방 백필 실패 (무시 가능): " + e.getMessage());
        }
    }
}
