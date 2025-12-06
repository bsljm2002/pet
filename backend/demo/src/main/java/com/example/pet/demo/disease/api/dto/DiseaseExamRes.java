package com.example.pet.demo.disease.api.dto;

import java.time.LocalDateTime;

import com.example.pet.demo.disease.domain.DiseaseExam;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * AI 진단 결과 응답 DTO
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DiseaseExamRes {
    private Long id;
    private Long userId;
    private Long petId;
    private String requestedType;
    private String summaryLabel;
    private DiseaseResultDto diseaseResult;
    private String imageUrl;
    private LocalDateTime createdAt;

    /**
     * disease_result JSON 구조
     */
    @Getter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DiseaseResultDto {
        private String diagnosis;
        private String description;
        private String severity;
        private Double confidence;
        private java.util.List<String> symptoms;
        private java.util.List<String> recommendations;
        private String diseaseStatus;
    }

    public static DiseaseExamRes from(DiseaseExam exam) {
        ObjectMapper mapper = new ObjectMapper();
        DiseaseResultDto resultDto = null;

        try {
            resultDto = mapper.readValue(exam.getDiseaseResult(), DiseaseResultDto.class);
        } catch (JsonProcessingException e) {
            // JSON 파싱 실패 시 빈 객체 반환
            resultDto = new DiseaseResultDto();
        }

        return DiseaseExamRes.builder()
                .id(exam.getId())
                .userId(exam.getUserId())
                .petId(exam.getPetId())
                .requestedType(exam.getRequestedType().name())
                .summaryLabel(exam.getSummaryLabel().name())
                .diseaseResult(resultDto)
                .imageUrl(exam.getImageUrl())
                .createdAt(exam.getCreatedAt())
                .build();
    }
}
