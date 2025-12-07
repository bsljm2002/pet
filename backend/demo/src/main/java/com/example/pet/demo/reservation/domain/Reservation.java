package com.example.pet.demo.reservation.domain;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;

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
import lombok.Setter;

@Entity
@Table(name = "reservation")
@Getter
@Setter
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
    @Column(name = "service_categorical", length = 20)
    private ServiceCategorical serviceCategorical; // HOSPITAL/GROOMING/CAFE/SITTER (상담 시 NULL)

    @Enumerated(EnumType.STRING)
    @Column(name = "user_type", length = 20)
    private UserType userType; // 파트너 타입과 동일하게 사용 (상담 시 NULL)

    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20)
    @Builder.Default
    private ReservationStatus status = ReservationStatus.WAITING;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    @Column(name = "visit_date_time")
    private OffsetDateTime visitDateTime; // 상담 시 NULL

    @Column(name = "canceled_at")
    private LocalDateTime canceledAt;

    @Column(name = "resv_url", length = 1024)
    private String reservationImageUrl;

    @Column(name = "resv_content", columnDefinition = "text")
    private String reservationContent;

    @Column(name = "pets_id")
    private Long petId; // 상담 시 NULL

    // MySQL SET 컬럼과 매핑: CSV 형태("DENTISTRY,DERMATOLOGY")
    @Column(name = "vet_specialty", length = 255)
    private String vetSpecialtyCsv;

    @Column(name = "petsitter_work", length = 255)
    private String petsitterWorkCsv;

    // 서비스 위치 정보 (펫시터 서비스용)
    @Column(name = "service_latitude")
    private Double serviceLatitude;

    @Column(name = "service_longitude")
    private Double serviceLongitude;

    @Column(name = "service_address", length = 512)
    private String serviceAddress;

    // 진료 정보 (병원 예약 완료 시)
    @Column(name = "diagnosis", columnDefinition = "text")
    private String diagnosis; // 진단 소견

    @Column(name = "prescription", length = 500)
    private String prescription; // 처방약

    @Column(name = "dosage_schedule", length = 50)
    private String dosageSchedule; // 복용 시간 (예: "MORNING,LUNCH,DINNER" 또는 "아침,점심,저녁")

    @Column(name = "dosage_days")
    private Integer dosageDays; // 복용 일수

    @Column(name = "medical_notes", columnDefinition = "text")
    private String medicalNotes; // 추가 안내사항

    // AI 진단 기록 연결
    @Column(name = "disease_exam_id")
    private Long diseaseExamId; // AI 진단 기록 ID (disease_exam 테이블 참조)

    // AI 진단 정보 (JSON 형태로 저장)
    @Column(name = "ai_diagnosis_data", columnDefinition = "text")
    private String aiDiagnosisData; // AI 진단 정보 목록 (JSON 배열)

    public enum ServiceCategorical {
        HOSPITAL, GROOMING, CAFE, SITTER
    }

    public enum ReservationStatus {
        WAITING, CONFIRMED, CHECKED_IN, COMPLETED,
        CANCELLED_BY_USER, CANCELLED_BY_BIZ
    }
}
