package com.example.pet.demo.partner.api.dto;

import com.example.pet.demo.partner.domain.Partner;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.Arrays;
import java.util.List;

/**
 * Partner Response DTO
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PartnerRes {

    private Long id;
    private String partnerType;
    private String name;
    private String doctorName;
    private String address;
    private Double latitude;
    private Double longitude;
    private String phone;
    private Double rating;
    private Boolean isOpen;
    private String imageUrl;
    private List<String> galleryImages;
    private String description;
    private List<String> specialties;
    private List<String> availableTimes;
    private List<String> education;
    private String experience;
    private List<String> certifications;
    private Long userId;

    /**
     * Entity to DTO conversion
     */
    public static PartnerRes from(Partner partner) {
        return PartnerRes.builder()
                .id(partner.getId())
                .partnerType(partner.getPartnerType().name())
                .name(partner.getName())
                .doctorName(partner.getDoctorName())
                .address(partner.getAddress())
                .latitude(partner.getLatitude())
                .longitude(partner.getLongitude())
                .phone(partner.getPhone())
                .rating(partner.getRating())
                .isOpen(partner.getIsOpen())
                .imageUrl(partner.getImageUrl())
                .galleryImages(splitString(partner.getGalleryImages()))
                .description(partner.getDescription())
                .specialties(splitString(partner.getSpecialties()))
                .availableTimes(splitString(partner.getAvailableTimes()))
                .education(splitString(partner.getEducation()))
                .experience(partner.getExperience())
                .certifications(splitString(partner.getCertifications()))
                .userId(partner.getUserId())
                .build();
    }

    /**
     * Split comma-separated string into list
     */
    private static List<String> splitString(String str) {
        if (str == null || str.trim().isEmpty()) {
            return List.of();
        }
        return Arrays.stream(str.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();
    }
}
