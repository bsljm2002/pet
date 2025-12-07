package com.example.pet.demo.reservation.api.dto;

import java.util.List;

public record AIDiagnosisDto(
    String id,
    String imagePath,
    String diagnosisDate,
    String petName,
    String petId,
    String diagnosis,
    String description,
    String severity,
    List<String> symptoms,
    List<String> recommendations,
    Double confidence,
    String diseaseStatus
) {}
