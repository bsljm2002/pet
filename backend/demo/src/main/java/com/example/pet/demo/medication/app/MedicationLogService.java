package com.example.pet.demo.medication.app;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.pet.demo.medication.domain.MedicationLog;
import com.example.pet.demo.medication.domain.MedicationLogRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MedicationLogService {

    private final MedicationLogRepository medicationLogRepository;

    /**
     * 약 복용 기록 토글 (체크/해제)
     * @param reservationId 예약 ID
     * @param userId 사용자 ID
     * @param petId 반려동물 ID
     * @param medicationKey 복용 키 (예: "1-아침")
     * @return true if checked, false if unchecked
     */
    @Transactional
    public boolean toggleMedication(Long reservationId, Long userId, Long petId, String medicationKey) {
        var existing = medicationLogRepository.findByReservationIdAndMedicationKey(reservationId, medicationKey);

        if (existing.isPresent()) {
            // 이미 체크되어 있으면 삭제 (체크 해제)
            medicationLogRepository.delete(existing.get());
            return false;
        } else {
            // 체크되어 있지 않으면 생성 (체크)
            MedicationLog log = MedicationLog.builder()
                    .reservationId(reservationId)
                    .userId(userId)
                    .petId(petId)
                    .medicationKey(medicationKey)
                    .takenAt(LocalDateTime.now())
                    .build();
            medicationLogRepository.save(log);
            return true;
        }
    }

    /**
     * 특정 예약의 복용 체크된 키 목록 조회
     */
    public List<String> getCheckedMedicationKeys(Long reservationId) {
        return medicationLogRepository.findMedicationKeysByReservationId(reservationId);
    }

    /**
     * 특정 예약의 모든 복용 기록 조회
     */
    public List<MedicationLog> getMedicationLogs(Long reservationId) {
        return medicationLogRepository.findByReservationId(reservationId);
    }
}
