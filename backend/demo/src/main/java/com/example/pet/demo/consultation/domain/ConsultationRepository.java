package com.example.pet.demo.consultation.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Consultation Repository
 */
@Repository
public interface ConsultationRepository extends JpaRepository<Consultation, Long> {

    /**
     * 특정 사용자의 상담 목록 조회 (최신순)
     */
    @Query("SELECT c FROM Consultation c " +
           "JOIN FETCH c.partner " +
           "WHERE c.user.id = :userId " +
           "ORDER BY c.createdAt DESC")
    List<Consultation> findByUserIdOrderByCreatedAtDesc(@Param("userId") Long userId);

    /**
     * 특정 파트너의 상담 목록 조회 (최신순)
     */
    @Query("SELECT c FROM Consultation c " +
           "JOIN FETCH c.user " +
           "WHERE c.partner.id = :partnerId " +
           "ORDER BY c.createdAt DESC")
    List<Consultation> findByPartnerIdOrderByCreatedAtDesc(@Param("partnerId") Long partnerId);

    /**
     * 특정 예약과 연결된 상담 조회
     */
    List<Consultation> findByReservationId(Long reservationId);

    /**
     * 특정 사용자의 특정 상태 상담 목록 조회
     */
    @Query("SELECT c FROM Consultation c " +
           "JOIN FETCH c.partner " +
           "WHERE c.user.id = :userId " +
           "AND c.status = :status " +
           "ORDER BY c.createdAt DESC")
    List<Consultation> findByUserIdAndStatus(@Param("userId") Long userId,
                                              @Param("status") ConsultationStatus status);
}
