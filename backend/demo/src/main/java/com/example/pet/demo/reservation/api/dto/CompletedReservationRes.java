package com.example.pet.demo.reservation.api.dto;

import com.example.pet.demo.reservation.domain.Reservation;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

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
                .build();
    }
}
