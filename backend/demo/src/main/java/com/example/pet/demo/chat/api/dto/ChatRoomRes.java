package com.example.pet.demo.chat.api.dto;

import java.time.OffsetDateTime;

public record ChatRoomRes(
    Long id,
    Long reservationId,
    Long userId,
    Long partnerId,
    String partnerName,
    String partnerImageUrl,
    String lastMessage,
    OffsetDateTime lastMessageTime,
    Integer unreadCount,
    String serviceType,
    OffsetDateTime createdAt,
    String reservationStatus  // WAITING, CONFIRMED, COMPLETED 등
) {}
