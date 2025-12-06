package com.example.pet.demo.disease.app;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.pet.demo.disease.api.dto.DiseaseExamCreateReq;
import com.example.pet.demo.disease.api.dto.DiseaseExamRes;
import com.example.pet.demo.disease.domain.DiseaseExam;
import com.example.pet.demo.disease.domain.DiseaseExamRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DiseaseExamService {

    private final DiseaseExamRepository diseaseExamRepository;
    private final ObjectMapper objectMapper;

    /**
     * AI 진단 결과 저장
     */
    @Transactional
    public DiseaseExamRes createDiseaseExam(DiseaseExamCreateReq request) {
        // diseaseResult를 JSON 문자열로 변환
        String diseaseResultJson;
        try {
            diseaseResultJson = objectMapper.writeValueAsString(request.diseaseResult());
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to serialize disease result", e);
        }

        DiseaseExam exam = DiseaseExam.builder()
                .userId(request.userId())
                .petId(request.petId())
                .requestedType(request.toDomainRequestedType())
                .summaryLabel(request.toDomainSummaryLabel())
                .diseaseResult(diseaseResultJson)
                .imageUrl(request.imageUrl())
                .createdAt(LocalDateTime.now())
                .build();

        DiseaseExam saved = diseaseExamRepository.save(exam);
        return DiseaseExamRes.from(saved);
    }

    /**
     * 사용자의 모든 AI 진단 기록 조회
     */
    public List<DiseaseExamRes> getDiseaseExamsByUserId(Long userId) {
        return diseaseExamRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(DiseaseExamRes::from)
                .collect(Collectors.toList());
    }

    /**
     * 반려동물의 모든 AI 진단 기록 조회
     */
    public List<DiseaseExamRes> getDiseaseExamsByPetId(Long petId) {
        return diseaseExamRepository.findByPetIdOrderByCreatedAtDesc(petId)
                .stream()
                .map(DiseaseExamRes::from)
                .collect(Collectors.toList());
    }

    /**
     * 특정 진단 유형의 기록 조회
     */
    public List<DiseaseExamRes> getDiseaseExamsByPetIdAndType(Long petId, String requestedType) {
        DiseaseExam.RequestedType type = DiseaseExam.RequestedType.valueOf(requestedType.toUpperCase());
        return diseaseExamRepository.findByPetIdAndRequestedType(petId, type)
                .stream()
                .map(DiseaseExamRes::from)
                .collect(Collectors.toList());
    }

    /**
     * 특정 AI 진단 기록 조회
     */
    public DiseaseExamRes getDiseaseExamById(Long id) {
        DiseaseExam exam = diseaseExamRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("DiseaseExam not found: " + id));
        return DiseaseExamRes.from(exam);
    }

    /**
     * AI 진단 기록 삭제 (소프트 삭제)
     */
    @Transactional
    public void deleteDiseaseExam(Long id) {
        DiseaseExam exam = diseaseExamRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("DiseaseExam not found: " + id));

        // 소프트 삭제 처리는 엔티티에 deletedAt 설정하는 방식으로 구현 가능
        // 현재는 하드 삭제
        diseaseExamRepository.delete(exam);
    }
}
