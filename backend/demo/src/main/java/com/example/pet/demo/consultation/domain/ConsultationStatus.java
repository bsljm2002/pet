package com.example.pet.demo.consultation.domain;

/**
 * 상담 상태 ENUM
 */
public enum ConsultationStatus {
    PENDING("대기중"),
    ANSWERED("답변완료"),
    CLOSED("종료"),
    CANCELLED("취소");

    private final String description;

    ConsultationStatus(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
