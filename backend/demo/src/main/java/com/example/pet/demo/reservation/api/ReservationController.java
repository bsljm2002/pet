package com.example.pet.demo.reservation.api;

import java.util.List;
import java.util.Map;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import com.example.pet.demo.common.ApiResponse;
import com.example.pet.demo.media.FileStorageService;
import com.example.pet.demo.reservation.api.dto.CompletedReservationRes;
import com.example.pet.demo.reservation.api.dto.MyReservationRes;
import com.example.pet.demo.reservation.api.dto.ReservationCreateReq;
import com.example.pet.demo.reservation.app.ReservationService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/reservations")
@RequiredArgsConstructor
@Validated
public class ReservationController {
    private final ReservationService reservationService;
    private final FileStorageService fileStorageService;
    @PostMapping
    public ResponseEntity<ApiResponse<?>> createReservation(
        @Valid @RequestBody ReservationCreateReq req
    ) {
        Long reservationId = reservationService.create(req);
        return ResponseEntity.ok(ApiResponse.ok(java.util.Map.of("reservation_id", reservationId)));
    }

    @PostMapping(value = "/{id}/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<Map<String, String>>> uploadReservationImage(
            @PathVariable("id") Long reservationId,
            @RequestParam("file") org.springframework.web.multipart.MultipartFile file
    ) throws Exception {
        String relative = fileStorageService.saveReservationImage(reservationId, file);
        String imageUrl = ServletUriComponentsBuilder.fromCurrentContextPath()
                .path(relative)
                .toUriString();
        reservationService.updateReservationImage(reservationId, imageUrl);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("imageUrl", imageUrl)));
    }

    @PatchMapping("/{id}/accept")
    public ResponseEntity<ApiResponse<Map<String, Long>>> acceptReservation(
        @PathVariable("id") Long reservationId,
        @RequestParam("partner_id") Long partnerId
    ) {
        reservationService.accept(reservationId, partnerId);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("reservation_id", reservationId)));
    }

    @GetMapping("/mine")
    public ResponseEntity<ApiResponse<List<MyReservationRes>>> getMyReservations(
            @RequestParam("userId") Long userId,
            @RequestParam(value = "serviceType", required = false) String serviceType // "HOSPITAL"/"SITTER" 필터
    ) {
        return ResponseEntity.ok(ApiResponse.ok(
                reservationService.getMyReservations(userId, serviceType)
        ));
    }

    /**
     * 수의사(병원)에서 받은 진료 내역 조회
     * GET /api/v1/reservations/completed/hospital?userId={userId}
     */
    @GetMapping("/completed/hospital")
    public ResponseEntity<ApiResponse<List<CompletedReservationRes>>> getCompletedHospitalReservations(
            @RequestParam("userId") Long userId
    ) {
        List<CompletedReservationRes> reservations = reservationService.getCompletedHospitalReservations(userId);
        return ResponseEntity.ok(ApiResponse.ok(reservations));
    }

    /**
     * 펫시터에게 받은 도움 내역 조회
     * GET /api/v1/reservations/completed/sitter?userId={userId}
     */
    @GetMapping("/completed/sitter")
    public ResponseEntity<ApiResponse<List<CompletedReservationRes>>> getCompletedSitterReservations(
            @RequestParam("userId") Long userId
    ) {
        List<CompletedReservationRes> reservations = reservationService.getCompletedSitterReservations(userId);
        return ResponseEntity.ok(ApiResponse.ok(reservations));
    }

    /**
     * 파트너가 받은 예약 목록 조회
     * GET /api/v1/reservations/partner?partnerId={partnerId}
     */
    @GetMapping("/partner")
    public ResponseEntity<ApiResponse<List<MyReservationRes>>> getPartnerReservations(
            @RequestParam("partnerId") Long partnerId
    ) {
        List<MyReservationRes> reservations = reservationService.getPartnerReservations(partnerId);
        return ResponseEntity.ok(ApiResponse.ok(reservations));
    }

    /**
     * 예약 거절
     * PATCH /api/v1/reservations/{id}/reject
     */
    @PatchMapping("/{id}/reject")
    public ResponseEntity<ApiResponse<Map<String, Long>>> rejectReservation(
        @PathVariable("id") Long reservationId,
        @RequestParam("partnerId") Long partnerId,
        @RequestParam(value = "reason", required = false) String reason
    ) {
        reservationService.reject(reservationId, partnerId, reason);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("reservation_id", reservationId)));
    }

    /**
     * 작업 시작 (체크인)
     * PATCH /api/v1/reservations/{id}/checkin
     */
    @PatchMapping("/{id}/checkin")
    public ResponseEntity<ApiResponse<Map<String, Long>>> checkinReservation(
        @PathVariable("id") Long reservationId,
        @RequestParam("partnerId") Long partnerId
    ) {
        reservationService.checkin(reservationId, partnerId);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("reservation_id", reservationId)));
    }

    /**
     * 진료/서비스 완료
     * PATCH /api/v1/reservations/{id}/complete
     */
    @PatchMapping("/{id}/complete")
    public ResponseEntity<ApiResponse<Map<String, Long>>> completeReservation(
        @PathVariable("id") Long reservationId,
        @RequestParam("partnerId") Long partnerId
    ) {
        reservationService.complete(reservationId, partnerId);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("reservation_id", reservationId)));
    }

    /**
     * 예약 취소 (사용자)
     * PATCH /api/v1/reservations/{id}/cancel
     */
    @PatchMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<Map<String, Long>>> cancelReservation(
        @PathVariable("id") Long reservationId,
        @RequestParam("userId") Long userId
    ) {
        reservationService.cancel(reservationId, userId);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("reservation_id", reservationId)));
    }

}
