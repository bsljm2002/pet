package com.example.pet.demo.reservation.api;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import com.example.pet.demo.common.ApiResponse;
import com.example.pet.demo.media.FileStorageService;
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
    public ResponseEntity<ApiResponse<String, String>>> uploadReservation(@PathVariable("id") Long reservationId,
        @RequestParam("file") MultipartFile file) throws Exception {
            String relative = fileStorageService.saveReservationImage(reservationId, file);
            String imageUrl = ServletUriComponentsBuilder
                .fromCurrentContextPath()
                .path(relative)
                .toUriString();
            reservationService.saveReservationImage(reservationId, imageUrl);

            return ResponseEntity.ok(ApiResponse.ok(Map.of("imageUrl", imageUrl)));
        }
}
