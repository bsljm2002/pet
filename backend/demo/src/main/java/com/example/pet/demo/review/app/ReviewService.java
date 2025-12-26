package com.example.pet.demo.review.app;

import com.example.pet.demo.partner.domain.Partner;
import com.example.pet.demo.partner.domain.PartnerRepository;
import com.example.pet.demo.review.api.dto.ReviewCreateReq;
import com.example.pet.demo.review.api.dto.ReviewRes;
import com.example.pet.demo.review.domain.Review;
import com.example.pet.demo.review.domain.ReviewRepository;
import com.example.pet.demo.users.domain.User;
import com.example.pet.demo.users.domain.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Review Service
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final PartnerRepository partnerRepository;
    private final UserRepository userRepository;

    /**
     * 파트너별 리뷰 목록 조회
     */
    public List<ReviewRes> getReviewsByPartnerId(Long partnerId) {
        return reviewRepository.findByPartnerIdOrderByCreatedAtDesc(partnerId)
                .stream()
                .map(ReviewRes::from)
                .collect(Collectors.toList());
    }

    /**
     * 리뷰 상세 조회
     */
    public ReviewRes getReview(Long reviewId) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new IllegalArgumentException("리뷰를 찾을 수 없습니다. ID: " + reviewId));
        return ReviewRes.from(review);
    }

    /**
     * 리뷰 작성
     */
    @Transactional
    public ReviewRes createReview(ReviewCreateReq req) {
        // 파트너 조회
        Partner partner = partnerRepository.findById(req.getPartnerId())
                .orElseThrow(() -> new IllegalArgumentException("파트너를 찾을 수 없습니다. ID: " + req.getPartnerId()));

        // 사용자 조회
        User user = userRepository.findById(req.getUserId())
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다. ID: " + req.getUserId()));

        // 중복 리뷰 체크 (예약당 1개)
        if (reviewRepository.existsByReservationId(req.getReservationId())) {
            throw new IllegalStateException("이미 해당 예약에 대한 리뷰를 작성하셨습니다.");
        }

        // 리뷰 생성
        Review review = Review.builder()
                .partner(partner)
                .user(user)
                .reservationId(req.getReservationId())
                .rating(req.getRating())
                .content(req.getContent())
                .build();

        Review savedReview = reviewRepository.save(review);

        // 파트너 평점 업데이트
        updatePartnerRating(req.getPartnerId());

        return ReviewRes.from(savedReview);
    }

    /**
     * 리뷰 삭제
     */
    @Transactional
    public void deleteReview(Long reviewId) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new IllegalArgumentException("리뷰를 찾을 수 없습니다. ID: " + reviewId));

        Long partnerId = review.getPartner().getId();
        reviewRepository.delete(review);

        // 파트너 평점 업데이트
        updatePartnerRating(partnerId);
    }

    /**
     * 파트너 평점 업데이트
     */
    private void updatePartnerRating(Long partnerId) {
        Double averageRating = reviewRepository.findAverageRatingByPartnerId(partnerId);

        Partner partner = partnerRepository.findById(partnerId)
                .orElseThrow(() -> new IllegalArgumentException("파트너를 찾을 수 없습니다. ID: " + partnerId));

        if (averageRating != null) {
            // 소수점 첫째자리까지 반올림
            double roundedRating = Math.round(averageRating * 10.0) / 10.0;
            partner.updateRating(roundedRating);
        } else {
            partner.updateRating(0.0);
        }

        partnerRepository.save(partner);
    }

    /**
     * 사용자별 리뷰 목록 조회
     */
    public List<ReviewRes> getReviewsByUserId(Long userId) {
        return reviewRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(ReviewRes::from)
                .collect(Collectors.toList());
    }
}
