package com.example.pet.demo.reservation.api.dto;

/**
 * 예약에 대한 상담 요청 DTO
 */
public record ConsultationRequestDto(
    String subject,   // 상담 제목
    String content    // 상담 내용
) {}
