package com.example.pet.demo.review.domain;

import com.example.pet.demo.partner.domain.Partner;
import com.example.pet.demo.users.domain.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Review Entity (리뷰 엔티티)
 *
 * 파트너(수의사/펫시터)에 대한 사용자 리뷰를 관리합니다.
 */
@Entity
@Table(name = "reviews")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * 리뷰 대상 파트너
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partner_id", nullable = false)
    private Partner partner;

    /**
     * 리뷰 작성자
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /**
     * 예약 ID (어느 예약에 대한 리뷰인지)
     */
    @Column(name = "reservation_id")
    private Long reservationId;

    /**
     * 평점 (1.0 ~ 5.0)
     */
    @Column(nullable = false)
    private Double rating;

    /**
     * 리뷰 내용
     */
    @Column(columnDefinition = "TEXT")
    private String content;

    /**
     * 작성일시
     */
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
