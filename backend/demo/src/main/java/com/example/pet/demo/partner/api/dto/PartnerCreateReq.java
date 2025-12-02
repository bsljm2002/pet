package com.example.pet.demo.partner.api.dto;

import com.example.pet.demo.partner.domain.Partner;
import com.example.pet.demo.partner.domain.PartnerType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 파트너 생성 요청 DTO
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class PartnerCreateReq {

    @NotNull(message = "파트너 유형은 필수입니다")
    private String partnerType; // "HOSPITAL" or "SITTER"

    @NotBlank(message = "이름은 필수입니다")
    private String name;

    private String doctorName;

    @NotBlank(message = "주소는 필수입니다")
    private String address;

    private Double latitude;
    private Double longitude;

    @NotBlank(message = "전화번호는 필수입니다")
    private String phone;

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
     * DTO to Entity 변환
     */
    public Partner toEntity() {
        return Partner.builder()
                .partnerType(PartnerType.valueOf(partnerType))
                .name(name)
                .doctorName(doctorName)
                .address(address)
                .latitude(latitude)
                .longitude(longitude)
                .phone(phone)
                .imageUrl(imageUrl)
                .galleryImages(joinList(galleryImages))
                .description(description)
                .specialties(joinList(specialties))
                .availableTimes(joinList(availableTimes))
                .education(joinList(education))
                .experience(experience)
                .certifications(joinList(certifications))
                .userId(userId)
                .rating(0.0)
                .isOpen(true)
                .build();
    }

    /**
     * 리스트를 콤마 구분 문자열로 변환
     */
    private String joinList(List<String> list) {
        if (list == null || list.isEmpty()) {
            return "";
        }
        return String.join(",", list);
    }
}
