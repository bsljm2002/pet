package com.example.pet.demo.consultation.api.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 상담 답변 추가 요청 DTO
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class AnswerCreateReq {
    private String answer;
}
