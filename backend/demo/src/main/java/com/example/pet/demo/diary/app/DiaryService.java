package com.example.pet.demo.diary.app;

import com.example.pet.demo.diary.domain.Diary;
import com.example.pet.demo.diary.domain.DiaryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DiaryService {

    private final DiaryRepository diaryRepository;

    /**
     * 특정 날짜의 일기 조회 (없으면 생성)
     */
    @Transactional
    public Diary getOrCreateDiary(Long petId, LocalDate diaryDate) {
        return diaryRepository.findByPetIdAndDiaryDate(petId, diaryDate)
                .orElseGet(() -> {
                    Diary newDiary = Diary.builder()
                            .petId(petId)
                            .diaryDate(diaryDate)
                            .content("")
                            .build();
                    return diaryRepository.save(newDiary);
                });
    }

    /**
     * 일기 저장 또는 업데이트
     */
    @Transactional
    public Diary saveDiary(Long petId, LocalDate diaryDate, String content,
                           Double weight, Integer heartRate, Integer stressLevel, String diseases) {
        Diary diary = diaryRepository.findByPetIdAndDiaryDate(petId, diaryDate)
                .orElse(Diary.builder()
                        .petId(petId)
                        .diaryDate(diaryDate)
                        .build());

        diary.setContent(content);
        diary.setWeight(weight);
        diary.setHeartRate(heartRate);
        diary.setStressLevel(stressLevel);
        diary.setDiseases(diseases);

        return diaryRepository.save(diary);
    }

    /**
     * 특정 펫의 모든 일기 조회
     */
    public List<Diary> getAllDiariesByPet(Long petId) {
        return diaryRepository.findByPetIdOrderByDiaryDateDesc(petId);
    }

    /**
     * 특정 펫의 특정 기간 일기 조회
     */
    public List<Diary> getDiariesByDateRange(Long petId, LocalDate startDate, LocalDate endDate) {
        return diaryRepository.findByPetIdAndDateRange(petId, startDate, endDate);
    }

    /**
     * 특정 펫의 최근 30일 일기 조회
     */
    public List<Diary> getRecentDiaries(Long petId) {
        return diaryRepository.findTop30ByPetIdOrderByDiaryDateDesc(petId);
    }

    /**
     * 일기 삭제
     */
    @Transactional
    public void deleteDiary(Long diaryId) {
        diaryRepository.deleteById(diaryId);
    }
}
