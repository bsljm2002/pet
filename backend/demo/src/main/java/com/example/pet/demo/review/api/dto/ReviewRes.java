package com.example.pet.demo.review.api.dto;

import com.example.pet.demo.review.domain.Review;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 리뷰 조회 응답 DTO
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewRes {
    private Long id;
    private Long partnerId;
    private String partnerName;
    private Long userId;
    private String userName;
    private Double rating;
    private String content;
    private LocalDateTime createdAt;

    /**
     * Entity to DTO 변환
     */
    public static ReviewRes from(Review review) {
        return ReviewRes.builder()
                .id(review.getId())
                .partnerId(review.getPartner().getId())
                .partnerName(review.getPartner().getName())
                .userId(review.getUser().getId())
                .userName(review.getUser().getNickname())
                .rating(review.getRating())
                .content(review.getContent())
                .createdAt(review.getCreatedAt())
                .build();
    }
}
