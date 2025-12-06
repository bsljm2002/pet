package com.example.pet.demo.medication.api;

import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.pet.demo.common.ApiResponse;
import com.example.pet.demo.medication.app.MedicationLogService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/medication-logs")
@RequiredArgsConstructor
public class MedicationLogController {

    private final MedicationLogService medicationLogService;

    /**
     * 약 복용 체크 토글
     */
    @PostMapping("/toggle")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> toggleMedication(
            @Valid @RequestBody MedicationToggleRequest request) {
        boolean isChecked = medicationLogService.toggleMedication(
                request.reservationId(),
                request.userId(),
                request.petId(),
                request.medicationKey()
        );
        return ResponseEntity.ok(ApiResponse.ok(Map.of("checked", isChecked)));
    }

    /**
     * 특정 예약의 체크된 복용 키 목록 조회
     */
    @GetMapping("/checked-keys")
    public ResponseEntity<ApiResponse<List<String>>> getCheckedKeys(
            @RequestParam("reservationId") Long reservationId) {
        List<String> checkedKeys = medicationLogService.getCheckedMedicationKeys(reservationId);
        return ResponseEntity.ok(ApiResponse.ok(checkedKeys));
    }

    public record MedicationToggleRequest(
            Long reservationId,
            Long userId,
            Long petId,
            String medicationKey
    ) {}
}
