package com.example.pet.demo.review.api.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

/**
 * 리뷰 수정 요청 DTO
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class ReviewUpdateReq {

    @NotNull(message = "평점은 필수입니다")
    @Min(value = 1, message = "평점은 1점 이상이어야 합니다")
    @Max(value = 5, message = "평점은 5점 이하여야 합니다")
    private Double rating;

    private String content;
}
