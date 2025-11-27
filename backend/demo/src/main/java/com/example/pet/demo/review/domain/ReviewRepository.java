package com.example.pet.demo.review.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Review Repository
 */
@Repository
public interface ReviewRepository extends JpaRepository<Review, Long> {

    /**
     * 파트너별 리뷰 목록 조회 (최신순)
     */
    List<Review> findByPartnerIdOrderByCreatedAtDesc(Long partnerId);

    /**
     * 파트너별 리뷰 개수 조회
     */
    Long countByPartnerId(Long partnerId);

    /**
     * 파트너별 평균 평점 조회
     */
    @Query("SELECT AVG(r.rating) FROM Review r WHERE r.partner.id = :partnerId")
    Double findAverageRatingByPartnerId(@Param("partnerId") Long partnerId);

    /**
     * 사용자별 리뷰 목록 조회
     */
    List<Review> findByUserIdOrderByCreatedAtDesc(Long userId);

    /**
     * 특정 파트너에 대한 특정 사용자의 리뷰 존재 여부
     */
    boolean existsByPartnerIdAndUserId(Long partnerId, Long userId);

    /**
     * 특정 예약에 대한 리뷰 존재 여부 (예약당 리뷰 1개 제한)
     */
    boolean existsByReservationId(Long reservationId);
}
