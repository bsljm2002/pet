package com.example.pet.demo.partner.api.dto;

import com.example.pet.demo.partner.domain.Partner;
import com.example.pet.demo.users.domain.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 파트너 목록 조회 응답 DTO
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PartnerListRes {
    private Long id;
    private String partnerType;
    private String name;
    private String doctorName;
    private String address;
    private Double latitude;
    private Double longitude;
    private String phone;
    private Double rating;
    private Double distance;
    private Boolean isOpen;
    private String imageUrl;
    private List<String> galleryImages;
    private String description;
    private List<String> specialties;
    private List<String> availableTimes;
    private List<String> education;
    private String experience;
    private List<String> certifications;
    private List<String> workingDays;
    private String workingStartHours;
    private String workingEndHours;

    /**
     * Entity to DTO 변환
     */
    public static PartnerListRes from(Partner partner) {
        return PartnerListRes.builder()
                .id(partner.getId())
                .partnerType(partner.getPartnerType().name())
                .name(partner.getName())
                .doctorName(partner.getDoctorName())
                .address(partner.getAddress())
                .latitude(partner.getLatitude())
                .longitude(partner.getLongitude())
                .phone(partner.getPhone())
                .rating(partner.getRating())
                .distance(partner.getDistance())
                .isOpen(partner.getIsOpen())
                .imageUrl(partner.getImageUrl())
                .galleryImages(parseCommaSeparated(partner.getGalleryImages()))
                .description(partner.getDescription())
                .specialties(convertSpecialtiesToKorean(parseCommaSeparated(partner.getSpecialties())))
                .availableTimes(parseCommaSeparated(partner.getAvailableTimes()))
                .education(parseCommaSeparated(partner.getEducation()))
                .experience(partner.getExperience())
                .certifications(parseCommaSeparated(partner.getCertifications()))
                .build();
    }

    /**
     * Entity to DTO 변환 (User 정보 포함)
     */
    public static PartnerListRes from(Partner partner, User user) {
        return PartnerListRes.builder()
                .id(partner.getId())
                .partnerType(partner.getPartnerType().name())
                .name(partner.getName())
                .doctorName(partner.getDoctorName())
                .address(partner.getAddress())
                .latitude(partner.getLatitude())
                .longitude(partner.getLongitude())
                .phone(partner.getPhone())
                .rating(partner.getRating())
                .distance(partner.getDistance())
                .isOpen(partner.getIsOpen())
                .imageUrl(partner.getImageUrl())
                .galleryImages(parseCommaSeparated(partner.getGalleryImages()))
                .description(partner.getDescription())
                .specialties(convertSpecialtiesToKorean(parseCommaSeparated(partner.getSpecialties())))
                .availableTimes(parseCommaSeparated(partner.getAvailableTimes()))
                .education(parseCommaSeparated(partner.getEducation()))
                .experience(partner.getExperience())
                .certifications(parseCommaSeparated(partner.getCertifications()))
                .workingDays(user != null ? parseCommaSeparated(user.getWorkingDays()) : List.of())
                .workingStartHours(user != null ? user.getWorkingStartHours() : null)
                .workingEndHours(user != null ? user.getWorkingEndHours() : null)
                .build();
    }

    /**
     * 콤마 구분 문자열을 리스트로 파싱
     */
    private static List<String> parseCommaSeparated(String value) {
        if (value == null || value.trim().isEmpty()) {
            return List.of();
        }
        return Arrays.stream(value.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());
    }

    /**
     * VetSpecialty enum 값을 한글로 변환
     */
    private static List<String> convertSpecialtiesToKorean(List<String> specialties) {
        return specialties.stream()
                .map(PartnerListRes::convertSpecialtyToKorean)
                .collect(Collectors.toList());
    }

    /**
     * 단일 VetSpecialty enum 값을 한글로 변환
     */
    private static String convertSpecialtyToKorean(String specialty) {
        switch (specialty) {
            case "INTERNAL_MEDICINE": return "내과";
            case "SURGERY": return "외과";
            case "DENTISTRY": return "치과";
            case "DERMATOLOGY": return "피부과";
            case "OPHTHALMOLOGY": return "안과";
            case "ORTHOPEDICS": return "정형외과";
            case "NEUROLOGY": return "신경과";
            case "ONCOLOGY": return "종양학";
            case "CARDIOLOGY": return "심장학";
            case "EMERGENCY_MEDICINE": return "응급의료";
            case "VACCINATION": return "예방접종";
            case "GENERAL": return "일반진료";
            default: return specialty; // 알 수 없는 경우 원본 반환
        }
    }
}
