package com.example.pet.demo.consultation.api.dto;

import com.example.pet.demo.consultation.domain.Consultation;
import com.example.pet.demo.consultation.domain.ConsultationStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 상담 응답 DTO
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ConsultationRes {
    private Long id;
    private Long userId;
    private String userName;
    private Long partnerId;
    private String partnerName;
    private Long reservationId;
    private String petType;
    private String subject;
    private String content;
    private String imageUrl;
    private String answer;
    private LocalDateTime answeredAt;
    private ConsultationStatus status;
    private String statusDescription;
    private LocalDateTime createdAt;

    /**
     * Entity to DTO 변환
     */
    public static ConsultationRes from(Consultation consultation) {
        return ConsultationRes.builder()
                .id(consultation.getId())
                .userId(consultation.getUser().getId())
                .userName(consultation.getUser().getNickname())
                .partnerId(consultation.getPartner().getId())
                .partnerName(consultation.getPartner().getName())
                .reservationId(consultation.getReservation() != null ?
                        consultation.getReservation().getId() : null)
                .petType(consultation.getPetType())
                .subject(consultation.getSubject())
                .content(consultation.getContent())
                .imageUrl(consultation.getImageUrl())
                .answer(consultation.getAnswer())
                .answeredAt(consultation.getAnsweredAt())
                .status(consultation.getStatus())
                .statusDescription(consultation.getStatus().getDescription())
                .createdAt(consultation.getCreatedAt())
                .build();
    }
}
