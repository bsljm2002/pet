package com.example.pet.demo.reservation.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * 진료 완료 요청 DTO
 */
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CompleteDiagnosisReq {
    private String diagnosis;        // 진단 소견
    private String prescription;     // 처방약
    private String dosageSchedule;   // 복용 시간 (예: "아침,점심,저녁")
    private Integer dosageDays;      // 복용 일수
    private String medicalNotes;     // 추가 안내사항
}
