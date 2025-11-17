package com.example.pet.demo.reservation.api.dto;

import java.util.List;

public record MyReservationRes(
    Long reservationId,
    String serviceType,
    String slotLabel,
    String date,
    Integer hour,
    String partnerName,
    List<String> specialties,
    String status
) {}
