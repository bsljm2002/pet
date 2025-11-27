package com.example.pet.demo.consultation.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 상담 생성 요청 DTO
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ConsultationCreateReq {

    @NotNull(message = "사용자 ID는 필수입니다.")
    private Long userId;

    @NotNull(message = "파트너 ID는 필수입니다.")
    private Long partnerId;

    // 예약 ID (선택적)
    private Long reservationId;

    @NotBlank(message = "반려동물 종류는 필수입니다.")
    @Size(max = 20, message = "반려동물 종류는 최대 20자입니다.")
    private String petType;

    @NotBlank(message = "상담 제목은 필수입니다.")
    @Size(max = 100, message = "상담 제목은 최대 100자입니다.")
    private String subject;

    @NotBlank(message = "상담 내용은 필수입니다.")
    private String content;

    // 이미지 URL (선택적)
    @Size(max = 500, message = "이미지 URL은 최대 500자입니다.")
    private String imageUrl;
}
