package com.example.pet.demo.review.api.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

/**
 * 리뷰 작성 요청 DTO
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class ReviewCreateReq {

    @NotNull(message = "파트너 ID는 필수입니다")
    private Long partnerId;

    @NotNull(message = "사용자 ID는 필수입니다")
    private Long userId;

    @NotNull(message = "예약 ID는 필수입니다")
    private Long reservationId;

    @NotNull(message = "평점은 필수입니다")
    @Min(value = 1, message = "평점은 1점 이상이어야 합니다")
    @Max(value = 5, message = "평점은 5점 이하여야 합니다")
    private Double rating;

    private String content;
}
