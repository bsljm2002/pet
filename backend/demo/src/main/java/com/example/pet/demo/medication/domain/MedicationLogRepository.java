package com.example.pet.demo.medication.domain;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface MedicationLogRepository extends JpaRepository<MedicationLog, Long> {

    // 특정 예약의 모든 복용 기록 조회
    List<MedicationLog> findByReservationId(Long reservationId);

    // 특정 예약의 특정 복용 키 조회
    Optional<MedicationLog> findByReservationIdAndMedicationKey(Long reservationId, String medicationKey);

    // 사용자의 모든 복용 기록 조회
    List<MedicationLog> findByUserId(Long userId);

    // 반려동물의 모든 복용 기록 조회
    List<MedicationLog> findByPetId(Long petId);

    // 특정 예약의 복용 키 목록만 조회
    @Query("SELECT m.medicationKey FROM MedicationLog m WHERE m.reservationId = :reservationId")
    List<String> findMedicationKeysByReservationId(@Param("reservationId") Long reservationId);
}
