package com.example.pet.demo.consultation.api.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 상담 답변 요청 DTO
 */
@Getter
@NoArgsConstructor
public class ConsultationAnswerReq {

    @NotBlank(message = "답변 내용은 필수입니다")
    private String answer;
}
