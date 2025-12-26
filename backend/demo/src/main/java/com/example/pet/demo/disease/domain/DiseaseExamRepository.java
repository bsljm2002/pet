package com.example.pet.demo.disease.domain;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface DiseaseExamRepository extends JpaRepository<DiseaseExam, Long> {

    // 사용자의 모든 AI 진단 기록 조회 (최신순)
    @Query("SELECT d FROM DiseaseExam d WHERE d.userId = :userId AND d.deletedAt IS NULL ORDER BY d.createdAt DESC")
    List<DiseaseExam> findByUserIdOrderByCreatedAtDesc(@Param("userId") Long userId);

    // 반려동물의 모든 AI 진단 기록 조회 (최신순)
    @Query("SELECT d FROM DiseaseExam d WHERE d.petId = :petId AND d.deletedAt IS NULL ORDER BY d.createdAt DESC")
    List<DiseaseExam> findByPetIdOrderByCreatedAtDesc(@Param("petId") Long petId);

    // 특정 진단 유형의 기록 조회
    @Query("SELECT d FROM DiseaseExam d WHERE d.petId = :petId AND d.requestedType = :requestedType AND d.deletedAt IS NULL ORDER BY d.createdAt DESC")
    List<DiseaseExam> findByPetIdAndRequestedType(
        @Param("petId") Long petId,
        @Param("requestedType") DiseaseExam.RequestedType requestedType
    );
}
