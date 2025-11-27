package com.example.pet.demo.reservation.api.dto;

import java.util.List;

public record MyReservationRes(
    Long reservationId,
    Long userId,
    String userName,
    Long petId,
    String petName,
    String serviceType,
    String slotLabel,
    String date,
    Integer hour,
    Integer minute,  // 분 추가
    Long partnerId,
    String partnerName,
    List<String> specialties,
    String status,
    String reservationContent,
    Boolean hasReview  // 리뷰 작성 여부
) {}
