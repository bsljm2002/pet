package com.example.pet.demo.partner.domain;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * Partner Entity (수의사/펫시터 통합 엔티티)
 *
 * 수의사와 펫시터 모두를 관리하는 통합 엔티티입니다.
 * PartnerType으로 구분됩니다.
 */
@Entity
@Table(name = "partners")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Partner {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * 파트너 유형 (HOSPITAL: 병원, SITTER: 시터)
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PartnerType partnerType;

    /**
     * 병원명 또는 시터 서비스명
     */
    @Column(nullable = false, length = 100)
    private String name;

    /**
     * 담당 의사명 또는 시터명
     */
    @Column(length = 50)
    private String doctorName;

    /**
     * 주소
     */
    @Column(nullable = false, length = 200)
    private String address;

    /**
     * 위도
     */
    @Column
    private Double latitude;

    /**
     * 경도
     */
    @Column
    private Double longitude;

    /**
     * 전화번호
     */
    @Column(nullable = false, length = 20)
    private String phone;

    /**
     * 평점 (0.0 ~ 5.0)
     */
    @Column
    @Builder.Default
    private Double rating = 0.0;

    /**
     * 거리 (km) - 계산된 값, 저장하지 않음
     */
    @Transient
    private Double distance;

    /**
     * 현재 영업 여부 (또는 서비스 가능 여부)
     */
    @Column
    @Builder.Default
    private Boolean isOpen = true;

    /**
     * 프로필 이미지 URL
     */
    @Column(length = 500)
    private String imageUrl;

    /**
     * 갤러리 이미지 URL들 (최대 8개, JSON 또는 콤마 구분)
     */
    @Column(columnDefinition = "TEXT")
    private String galleryImages;

    /**
     * 소개글
     */
    @Column(columnDefinition = "TEXT")
    private String description;

    /**
     * 전문 분야 (JSON 또는 콤마 구분 문자열)
     * 병원: "내과,외과,피부과"
     * 시터: "산책 서비스,방문 돌봄,목욕/미용"
     */
    @Column(length = 500)
    private String specialties;

    /**
     * 예약 가능 시간 (JSON 또는 콤마 구분 문자열)
     * 예: "09:00,10:30,14:00,16:30"
     */
    @Column(length = 500)
    private String availableTimes;

    /**
     * 학력 및 자격 사항 (병원용, JSON 또는 콤마 구분)
     */
    @Column(columnDefinition = "TEXT")
    private String education;

    /**
     * 경력 (시터용)
     */
    @Column(length = 50)
    private String experience;

    /**
     * 자격증 (시터용, JSON 또는 콤마 구분)
     */
    @Column(length = 500)
    private String certifications;

    /**
     * 사용자 ID (파트너 계정)
     */
    @Column
    private Long userId;

    // 비즈니스 로직 메서드

    /**
     * 평점 업데이트
     */
    public void updateRating(Double newRating) {
        if (newRating >= 0.0 && newRating <= 5.0) {
            this.rating = newRating;
        }
    }

    /**
     * 영업 상태 변경
     */
    public void toggleOpen() {
        this.isOpen = !this.isOpen;
    }

    /**
     * 정보 업데이트
     */
    public void updateInfo(String name, String address, String phone, String description) {
        if (name != null) this.name = name;
        if (address != null) this.address = address;
        if (phone != null) this.phone = phone;
        if (description != null) this.description = description;
    }

    /**
     * 위치 정보 업데이트
     */
    public void updateLocation(Double latitude, Double longitude) {
        this.latitude = latitude;
        this.longitude = longitude;
    }

    /**
     * 이미지 업데이트
     */
    public void updateImage(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    /**
     * 갤러리 이미지 업데이트
     */
    public void updateGalleryImages(String galleryImages) {
        this.galleryImages = galleryImages;
    }

    /**
     * 거리 설정 (계산된 값)
     */
    public void setDistance(Double distance) {
        this.distance = distance;
    }

    /**
     * 프로필 상세 정보 업데이트 (진료과목, 시간, 자격증 등)
     */
    public void updateProfileDetails(
            String doctorName,
            String specialties,
            String availableTimes,
            String education,
            String experience,
            String certifications
    ) {
        if (doctorName != null) this.doctorName = doctorName;
        if (specialties != null) this.specialties = specialties;
        if (availableTimes != null) this.availableTimes = availableTimes;
        if (education != null) this.education = education;
        if (experience != null) this.experience = experience;
        if (certifications != null) this.certifications = certifications;
    }
}
