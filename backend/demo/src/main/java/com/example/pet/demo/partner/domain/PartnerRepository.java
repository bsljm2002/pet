package com.example.pet.demo.partner.domain;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Partner Repository
 */
@Repository
public interface PartnerRepository extends JpaRepository<Partner, Long> {

    /**
     * 파트너 유형으로 조회
     */
    List<Partner> findByPartnerType(PartnerType partnerType);

    /**
     * 파트너 유형과 영업 상태로 조회
     */
    List<Partner> findByPartnerTypeAndIsOpen(PartnerType partnerType, Boolean isOpen);

    /**
     * 사용자 ID로 조회
     */
    List<Partner> findByUserId(Long userId);

    /**
     * 이름으로 검색 (LIKE)
     */
    @Query("SELECT p FROM Partner p WHERE p.partnerType = :partnerType AND p.name LIKE %:name%")
    List<Partner> searchByName(@Param("partnerType") PartnerType partnerType, @Param("name") String name);

    /**
     * 전문분야로 검색 (LIKE)
     */
    @Query("SELECT p FROM Partner p WHERE p.partnerType = :partnerType AND p.specialties LIKE %:specialty%")
    List<Partner> searchBySpecialty(@Param("partnerType") PartnerType partnerType, @Param("specialty") String specialty);
}
