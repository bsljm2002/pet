package com.example.pet.demo.reservation.domain;

import java.time.LocalDateTime;

import com.example.pet.demo.users.domain.User.UserType;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "reservation")
@Getter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
public class Reservation {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "partner_id", nullable = false)
    private Long partnerId;

    @Enumerated(EnumType.STRING)
    @Column(name = "service_categorical", nullable = false, length = 20)
    private ServiceCategorical serviceCategorical; // HOSPITAL/GROOMING/CAFE/SITTER

    @Enumerated(EnumType.STRING)
    @Column(name = "user_type", nullable = false, length = 20)
    private UserType userType; // 파트너 타입과 동일하게 사용

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private ReservationStatus status = ReservationStatus.WAITING;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "canceled_at")
    private LocalDateTime canceledAt;

    @Column(name = "resv_url", length = 1024)
    private String reservationImageUrl;

    @Column(name = "resv_content", columnDefinition = "text")
    private String reservationContent;

    @Column(name = "pets_id", nullable = false)
    private Long petId;

    // MySQL SET 컬럼과 매핑: CSV 형태("DENTISTRY,DERMATOLOGY")
    @Column(name = "vet_specialty", length = 255)
    private String vetSpecialtyCsv;

    @Column(name = "petsitter_work", length = 255)
    private String petsitterWorkCsv;

    public enum ServiceCategorical {
        HOSPITAL, GROOMING, CAFE, SITTER
    }

    public enum ReservationStatus {
        WAITING, CONFIRMED, CHECKED_IN, COMPLETED,
        CANCELLED_BY_USER, CANCELLED_BY_BIZ
    }
}
