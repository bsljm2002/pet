package com.example.pet.demo.diary.api;

import com.example.pet.demo.diary.app.DiaryService;
import com.example.pet.demo.diary.domain.Diary;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/diaries")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class DiaryController {

    private final DiaryService diaryService;

    /**
     * 특정 날짜의 일기 조회
     * GET /api/diaries/{petId}/{date}
     */
    @GetMapping("/{petId}/{date}")
    public ResponseEntity<Map<String, Object>> getDiary(
            @PathVariable("petId") Long petId,
            @PathVariable("date") @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate date) {

        Diary diary = diaryService.getOrCreateDiary(petId, date);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("diary", convertToMap(diary));

        return ResponseEntity.ok(response);
    }

    /**
     * 일기 저장/수정
     * POST /api/diaries
     */
    @PostMapping
    public ResponseEntity<Map<String, Object>> saveDiary(@RequestBody DiaryRequest request) {
        Diary diary = diaryService.saveDiary(
                request.getPetId(),
                request.getDiaryDate(),
                request.getContent(),
                request.getWeight(),
                request.getHeartRate(),
                request.getStressLevel(),
                request.getDiseases()
        );

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "일기가 저장되었습니다.");
        response.put("diary", convertToMap(diary));

        return ResponseEntity.ok(response);
    }

    /**
     * 특정 펫의 모든 일기 조회
     * GET /api/diaries/pet/{petId}
     */
    @GetMapping("/pet/{petId}")
    public ResponseEntity<Map<String, Object>> getAllDiaries(@PathVariable Long petId) {
        List<Diary> diaries = diaryService.getAllDiariesByPet(petId);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("diaries", diaries.stream().map(this::convertToMap).toList());

        return ResponseEntity.ok(response);
    }

    /**
     * 특정 펫의 특정 기간 일기 조회
     * GET /api/diaries/pet/{petId}/range?startDate=yyyy-MM-dd&endDate=yyyy-MM-dd
     */
    @GetMapping("/pet/{petId}/range")
    public ResponseEntity<Map<String, Object>> getDiariesByRange(
            @PathVariable Long petId,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate startDate,
            @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd") LocalDate endDate) {

        List<Diary> diaries = diaryService.getDiariesByDateRange(petId, startDate, endDate);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("diaries", diaries.stream().map(this::convertToMap).toList());

        return ResponseEntity.ok(response);
    }

    /**
     * 특정 펫의 최근 30일 일기 조회
     * GET /api/diaries/pet/{petId}/recent
     */
    @GetMapping("/pet/{petId}/recent")
    public ResponseEntity<Map<String, Object>> getRecentDiaries(@PathVariable Long petId) {
        List<Diary> diaries = diaryService.getRecentDiaries(petId);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("diaries", diaries.stream().map(this::convertToMap).toList());

        return ResponseEntity.ok(response);
    }

    /**
     * 일기 삭제
     * DELETE /api/diaries/{diaryId}
     */
    @DeleteMapping("/{diaryId}")
    public ResponseEntity<Map<String, Object>> deleteDiary(@PathVariable Long diaryId) {
        diaryService.deleteDiary(diaryId);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "일기가 삭제되었습니다.");

        return ResponseEntity.ok(response);
    }

    // Diary 엔티티를 Map으로 변환
    private Map<String, Object> convertToMap(Diary diary) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", diary.getId());
        map.put("petId", diary.getPetId());
        map.put("diaryDate", diary.getDiaryDate().toString());
        map.put("content", diary.getContent());
        map.put("weight", diary.getWeight());
        map.put("heartRate", diary.getHeartRate());
        map.put("stressLevel", diary.getStressLevel());
        map.put("diseases", diary.getDiseases());
        map.put("createdAt", diary.getCreatedAt());
        map.put("updatedAt", diary.getUpdatedAt());
        return map;
    }

    // Request DTO
    @lombok.Data
    static class DiaryRequest {
        private Long petId;
        @DateTimeFormat(pattern = "yyyy-MM-dd")
        private LocalDate diaryDate;
        private String content;
        private Double weight;
        private Integer heartRate;
        private Integer stressLevel;
        private String diseases;
    }
}
