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
    
}
