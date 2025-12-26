package com.example.pet.demo.reservation.api.dto;

import com.example.pet.demo.reservation.domain.Reservation;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.List;

/**
 * 완료된 예약 응답 DTO (파트너 정보 포함)
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CompletedReservationRes {
    private Long reservationId;
    private Long partnerId;
    private String partnerName;
    private String partnerType; // HOSPITAL/SITTER
    private OffsetDateTime createdAt;
    private String serviceCategorical;
    private String reservationContent;
    private boolean hasReview; // 리뷰 작성 여부

    // 진료 정보 (병원 예약인 경우)
    private String diagnosis;          // 진단 소견
    private String prescription;       // 처방약
    private String dosageSchedule;     // 복용 시간
    private Integer dosageDays;        // 복용 일수
    private String medicalNotes;       // 추가 안내사항
    private List<String> checkedMedicationKeys; // 체크된 복용 키 목록

    public static CompletedReservationRes from(
            Reservation reservation,
            String partnerName,
            String partnerType,
            boolean hasReview
    ) {
        return CompletedReservationRes.builder()
                .reservationId(reservation.getId())
                .partnerId(reservation.getPartnerId())
                .partnerName(partnerName)
                .partnerType(partnerType)
                .createdAt(reservation.getCreatedAt())
                .serviceCategorical(reservation.getServiceCategorical().name())
                .reservationContent(reservation.getReservationContent())
                .hasReview(hasReview)
                .diagnosis(reservation.getDiagnosis())
                .prescription(reservation.getPrescription())
                .dosageSchedule(reservation.getDosageSchedule())
                .dosageDays(reservation.getDosageDays())
                .medicalNotes(reservation.getMedicalNotes())
                .checkedMedicationKeys(List.of()) // 기본값
                .build();
    }

    public static CompletedReservationRes from(
            Reservation reservation,
            String partnerName,
            String partnerType,
            boolean hasReview,
            List<String> checkedMedicationKeys
    ) {
        return CompletedReservationRes.builder()
                .reservationId(reservation.getId())
                .partnerId(reservation.getPartnerId())
                .partnerName(partnerName)
                .partnerType(partnerType)
                .createdAt(reservation.getCreatedAt())
                .serviceCategorical(reservation.getServiceCategorical().name())
                .reservationContent(reservation.getReservationContent())
                .hasReview(hasReview)
                .diagnosis(reservation.getDiagnosis())
                .prescription(reservation.getPrescription())
                .dosageSchedule(reservation.getDosageSchedule())
                .dosageDays(reservation.getDosageDays())
                .medicalNotes(reservation.getMedicalNotes())
                .checkedMedicationKeys(checkedMedicationKeys)
                .build();
    }
}
