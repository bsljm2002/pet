package com.example.pet.demo.diary.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface DiaryRepository extends JpaRepository<Diary, Long> {

    // 특정 펫의 특정 날짜 일기 조회
    Optional<Diary> findByPetIdAndDiaryDate(Long petId, LocalDate diaryDate);

    // 특정 펫의 모든 일기 조회 (최신순)
    List<Diary> findByPetIdOrderByDiaryDateDesc(Long petId);

    // 특정 펫의 특정 기간 일기 조회
    @Query("SELECT d FROM Diary d WHERE d.petId = :petId AND d.diaryDate BETWEEN :startDate AND :endDate ORDER BY d.diaryDate DESC")
    List<Diary> findByPetIdAndDateRange(
        @Param("petId") Long petId,
        @Param("startDate") LocalDate startDate,
        @Param("endDate") LocalDate endDate
    );

    // 특정 펫의 최근 N개 일기 조회
    List<Diary> findTop30ByPetIdOrderByDiaryDateDesc(Long petId);
}
