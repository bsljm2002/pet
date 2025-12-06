package com.example.pet.demo.disease.api;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.pet.demo.common.ApiResponse;
import com.example.pet.demo.disease.api.dto.DiseaseExamCreateReq;
import com.example.pet.demo.disease.api.dto.DiseaseExamRes;
import com.example.pet.demo.disease.app.DiseaseExamService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/disease-exams")
@RequiredArgsConstructor
public class DiseaseExamController {

    private final DiseaseExamService diseaseExamService;

    /**
     * AI 진단 결과 저장
     * POST /api/v1/disease-exams
     */
    @PostMapping
    public ResponseEntity<ApiResponse<DiseaseExamRes>> createDiseaseExam(
            @Valid @RequestBody DiseaseExamCreateReq request) {
        DiseaseExamRes response = diseaseExamService.createDiseaseExam(request);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    /**
     * 사용자의 모든 AI 진단 기록 조회
     * GET /api/v1/disease-exams/user/{userId}
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<List<DiseaseExamRes>>> getDiseaseExamsByUserId(
            @PathVariable("userId") Long userId) {
        List<DiseaseExamRes> exams = diseaseExamService.getDiseaseExamsByUserId(userId);
        return ResponseEntity.ok(ApiResponse.ok(exams));
    }

    /**
     * 반려동물의 모든 AI 진단 기록 조회
     * GET /api/v1/disease-exams/pet/{petId}
     */
    @GetMapping("/pet/{petId}")
    public ResponseEntity<ApiResponse<List<DiseaseExamRes>>> getDiseaseExamsByPetId(
            @PathVariable("petId") Long petId) {
        List<DiseaseExamRes> exams = diseaseExamService.getDiseaseExamsByPetId(petId);
        return ResponseEntity.ok(ApiResponse.ok(exams));
    }

    /**
     * 반려동물의 특정 유형 AI 진단 기록 조회
     * GET /api/v1/disease-exams/pet/{petId}/type?requestedType=EYE
     */
    @GetMapping("/pet/{petId}/type")
    public ResponseEntity<ApiResponse<List<DiseaseExamRes>>> getDiseaseExamsByPetIdAndType(
            @PathVariable("petId") Long petId,
            @RequestParam("requestedType") String requestedType) {
        List<DiseaseExamRes> exams = diseaseExamService.getDiseaseExamsByPetIdAndType(petId, requestedType);
        return ResponseEntity.ok(ApiResponse.ok(exams));
    }

    /**
     * 특정 AI 진단 기록 조회
     * GET /api/v1/disease-exams/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<DiseaseExamRes>> getDiseaseExamById(
            @PathVariable("id") Long id) {
        DiseaseExamRes exam = diseaseExamService.getDiseaseExamById(id);
        return ResponseEntity.ok(ApiResponse.ok(exam));
    }

    /**
     * AI 진단 기록 삭제
     * DELETE /api/v1/disease-exams/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteDiseaseExam(
            @PathVariable("id") Long id) {
        diseaseExamService.deleteDiseaseExam(id);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }
}
