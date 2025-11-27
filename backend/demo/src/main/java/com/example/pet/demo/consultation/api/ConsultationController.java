package com.example.pet.demo.consultation.api;

import com.example.pet.demo.common.ApiResponse;
import com.example.pet.demo.consultation.api.dto.ConsultationAnswerReq;
import com.example.pet.demo.consultation.api.dto.ConsultationCreateReq;
import com.example.pet.demo.consultation.api.dto.ConsultationRes;
import com.example.pet.demo.consultation.app.ConsultationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Consultation Controller
 * 상담 관련 API 엔드포인트
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/consultations")
@RequiredArgsConstructor
public class ConsultationController {

    private final ConsultationService consultationService;

    /**
     * 상담 생성
     * POST /api/v1/consultations
     */
    @PostMapping
    public ResponseEntity<ApiResponse<ConsultationRes>> createConsultation(
            @Valid @RequestBody ConsultationCreateReq req
    ) {
        ConsultationRes consultation = consultationService.createConsultation(req);
        return ResponseEntity.ok(ApiResponse.ok(consultation));
    }

    /**
     * 특정 사용자의 상담 목록 조회
     * GET /api/v1/consultations/user/{userId}
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<ConsultationRes>>> getConsultationsByUserId(
            @PathVariable("userId") Long userId
    ) {
        List<ConsultationRes> consultations = consultationService.getConsultationsByUserId(userId);
        return ResponseEntity.ok(ApiResponse.ok(consultations));
    }

    /**
     * 특정 파트너의 상담 목록 조회
     * GET /api/v1/consultations/partner/{partnerId}
     */
    @GetMapping("/partner/{partnerId}")
    public ResponseEntity<ApiResponse<List<ConsultationRes>>> getConsultationsByPartnerId(
            @PathVariable("partnerId") Long partnerId
    ) {
        List<ConsultationRes> consultations = consultationService.getConsultationsByPartnerId(partnerId);
        return ResponseEntity.ok(ApiResponse.ok(consultations));
    }

    /**
     * 상담 상세 조회
     * GET /api/v1/consultations/{consultationId}
     */
    @GetMapping("/{consultationId}")
    public ResponseEntity<ApiResponse<ConsultationRes>> getConsultation(
            @PathVariable("consultationId") Long consultationId
    ) {
        ConsultationRes consultation = consultationService.getConsultation(consultationId);
        return ResponseEntity.ok(ApiResponse.ok(consultation));
    }

    /**
     * 상담 답변 작성 (파트너용)
     * POST /api/v1/consultations/{consultationId}/answer
     */
    @PostMapping("/{consultationId}/answer")
    public ResponseEntity<ApiResponse<ConsultationRes>> answerConsultation(
            @PathVariable("consultationId") Long consultationId,
            @Valid @RequestBody ConsultationAnswerReq req
    ) {
        ConsultationRes consultation = consultationService.answerConsultation(consultationId, req.getAnswer());
        return ResponseEntity.ok(ApiResponse.ok(consultation));
    }

    /**
     * 상담 취소 (고객용)
     * DELETE /api/v1/consultations/{consultationId}
     */
    @DeleteMapping("/{consultationId}")
    public ResponseEntity<ApiResponse<Void>> cancelConsultation(
            @PathVariable("consultationId") Long consultationId
    ) {
        consultationService.cancelConsultation(consultationId);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }
}
