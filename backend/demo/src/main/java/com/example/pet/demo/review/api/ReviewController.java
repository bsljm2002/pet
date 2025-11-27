package com.example.pet.demo.review.api;

import com.example.pet.demo.common.ApiResponse;
import com.example.pet.demo.review.api.dto.ReviewCreateReq;
import com.example.pet.demo.review.api.dto.ReviewRes;
import com.example.pet.demo.review.app.ReviewService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;

/**
 * Review Controller
 * 리뷰 관련 API 엔드포인트
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/reviews")
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;

    /**
     * 파트너별 리뷰 목록 조회
     * GET /api/v1/reviews/partner/{partnerId}
     */
    @GetMapping("/partner/{partnerId}")
    public ResponseEntity<ApiResponse<List<ReviewRes>>> getReviewsByPartnerId(
            @PathVariable("partnerId") Long partnerId
    ) {
        List<ReviewRes> reviews = reviewService.getReviewsByPartnerId(partnerId);
        return ResponseEntity.ok(ApiResponse.ok(reviews));
    }

    /**
     * 리뷰 상세 조회
     * GET /api/v1/reviews/{reviewId}
     */
    @GetMapping("/{reviewId}")
    public ResponseEntity<ApiResponse<ReviewRes>> getReview(
            @PathVariable("reviewId") Long reviewId
    ) {
        ReviewRes review = reviewService.getReview(reviewId);
        return ResponseEntity.ok(ApiResponse.ok(review));
    }

    /**
     * 리뷰 작성
     * POST /api/v1/reviews
     */
    @PostMapping
    public ResponseEntity<ApiResponse<ReviewRes>> createReview(
            @Valid @RequestBody ReviewCreateReq req
    ) {
        ReviewRes review = reviewService.createReview(req);
        return ResponseEntity.ok(ApiResponse.ok(review));
    }

    /**
     * 리뷰 삭제
     * DELETE /api/v1/reviews/{reviewId}
     */
    @DeleteMapping("/{reviewId}")
    public ResponseEntity<ApiResponse<Void>> deleteReview(
            @PathVariable("reviewId") Long reviewId
    ) {
        reviewService.deleteReview(reviewId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    /**
     * 사용자별 리뷰 목록 조회
     * GET /api/v1/reviews/user/{userId}
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<ReviewRes>>> getReviewsByUserId(
            @PathVariable("userId") Long userId
    ) {
        List<ReviewRes> reviews = reviewService.getReviewsByUserId(userId);
        return ResponseEntity.ok(ApiResponse.ok(reviews));
    }
}
