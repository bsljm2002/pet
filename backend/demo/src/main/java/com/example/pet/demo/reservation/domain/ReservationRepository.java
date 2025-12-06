package com.example.pet.demo.reservation.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Reservation Repository
 */
@Repository
public interface ReservationRepository extends JpaRepository<Reservation, Long> {

    /**
     * 사용자별 예약 목록 조회
     */
    List<Reservation> findByUserIdOrderByCreatedAtDesc(Long userId);

    /**
     * 사용자별 완료된 예약 목록 조회 (리뷰 작성 가능한 예약)
     */
    List<Reservation> findByUserIdAndStatusOrderByCreatedAtDesc(
            Long userId,
            Reservation.ReservationStatus status
    );

    /**
     * 사용자가 특정 파트너에게 완료된 예약이 있는지 확인
     */
    @Query("SELECT COUNT(r) > 0 FROM Reservation r " +
           "WHERE r.userId = :userId " +
           "AND r.partnerId = :partnerId " +
           "AND r.status = :status")
    boolean existsCompletedReservation(
            @Param("userId") Long userId,
            @Param("partnerId") Long partnerId,
            @Param("status") Reservation.ReservationStatus status
    );

    /**
     * 파트너별 예약 목록 조회
     */
    List<Reservation> findByPartnerIdOrderByCreatedAtDesc(Long partnerId);

    /**
     * 반려동물별 완료된 예약 목록 조회 (진료 기록)
     */
    List<Reservation> findByPetIdAndStatusOrderByCreatedAtDesc(
            Long petId,
            Reservation.ReservationStatus status
    );
}
