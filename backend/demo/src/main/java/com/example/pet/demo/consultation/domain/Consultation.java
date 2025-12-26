package com.example.pet.demo.consultation.domain;

import com.example.pet.demo.partner.domain.Partner;
import com.example.pet.demo.reservation.domain.Reservation;
import com.example.pet.demo.users.domain.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Consultation Entity (상담 엔티티)
 *
 * 파트너(수의사/펫시터)와 고객 간의 간편 상담을 관리합니다.
 */
@Entity
@Table(name = "consultations")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Consultation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * 상담 요청한 고객
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /**
     * 상담 대상 파트너
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "partner_id", nullable = false)
    private Partner partner;

    /**
     * 연결된 예약 (선택적)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reservation_id", nullable = true)
    private Reservation reservation;

    /**
     * 반려동물 종류 (예: "강아지", "고양이")
     */
    @Column(name = "pet_type", nullable = false, length = 20)
    private String petType;

    /**
     * 상담 제목
     */
    @Column(nullable = false, length = 100)
    private String subject;

    /**
     * 상담 내용
     */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    /**
     * 첨부 이미지 URL (선택적)
     */
    @Column(name = "image_url", length = 500)
    private String imageUrl;

    /**
     * 파트너의 답변 내용
     */
    @Column(columnDefinition = "TEXT")
    private String answer;

    /**
     * 답변 완료 일시
     */
    @Column(name = "answered_at")
    private LocalDateTime answeredAt;

    /**
     * 상담 상태
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private ConsultationStatus status = ConsultationStatus.PENDING;

    /**
     * 생성 일시
     */
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    /**
     * 답변 작성
     */
    public void addAnswer(String answer) {
        this.answer = answer;
        this.answeredAt = LocalDateTime.now();
        this.status = ConsultationStatus.ANSWERED;
    }

    /**
     * 상담 종료
     */
    public void close() {
        this.status = ConsultationStatus.CLOSED;
    }

    /**
     * 상담 취소
     */
    public void cancel() {
        this.status = ConsultationStatus.CANCELLED;
    }
}
