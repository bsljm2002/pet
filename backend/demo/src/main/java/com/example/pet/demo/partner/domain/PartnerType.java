package com.example.pet.demo.partner.domain;

/**
 * 파트너 유형을 구분하는 Enum
 * HOSPITAL: 수의사/동물병원
 * SITTER: 펫시터
 */
public enum PartnerType {
    HOSPITAL("동물병원"),
    SITTER("펫시터");

    private final String description;

    PartnerType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
