package com.example.pet.demo.disease.api.dto;

import com.example.pet.demo.disease.domain.DiseaseExam;
import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.validation.constraints.NotNull;

/**
 * AI 진단 결과 저장 요청 DTO
 */
public record DiseaseExamCreateReq(
    @NotNull
    Long userId,

    @NotNull
    Long petId,

    @NotNull
    RequestedType requestedType,

    @NotNull
    SummaryLabel summaryLabel,

    @NotNull
    @JsonProperty("diseaseResult")
    DiseaseResultDto diseaseResult,

    @NotNull
    String imageUrl
) {
    public enum RequestedType {
        EYE, SKIN, OBESITY
    }

    public enum SummaryLabel {
        NORMAL, SUSPECT, CAUTION
    }

    /**
     * disease_result JSON 구조
     */
    public record DiseaseResultDto(
        String diagnosis,        // 진단명
        String description,      // 설명
        String severity,         // 심각도 (low, medium, high, none)
        Double confidence,       // 신뢰도 (0.0 ~ 1.0)
        java.util.List<String> symptoms,         // 증상 목록
        java.util.List<String> recommendations,  // 권장사항
        String diseaseStatus     // 질병 상태 (정상, 질병 의심)
    ) {}

    public DiseaseExam.RequestedType toDomainRequestedType() {
        return DiseaseExam.RequestedType.valueOf(requestedType.name());
    }

    public DiseaseExam.SummaryLabel toDomainSummaryLabel() {
        return DiseaseExam.SummaryLabel.valueOf(summaryLabel.name());
    }
}
