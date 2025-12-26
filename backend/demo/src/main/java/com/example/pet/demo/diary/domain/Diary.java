package com.example.pet.demo.diary.domain;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "diaries")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Diary {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long petId; // 반려동물 ID

    @Column(nullable = false)
    private LocalDate diaryDate; // 일기 날짜

    @Column(columnDefinition = "TEXT")
    private String content; // 일기 내용

    // 건강 데이터
    private Double weight; // 체중 (kg)
    private Integer heartRate; // 심박수 (bpm)
    private Integer stressLevel; // 스트레스 지수 (1-10)

    @Column(columnDefinition = "TEXT")
    private String diseases; // 질환 정보 (JSON 형태로 저장)

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt; // 생성 시간

    @Column(nullable = false)
    private LocalDateTime updatedAt; // 수정 시간

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
