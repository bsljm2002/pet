package com.example.pet.demo.partner.api.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Partner Update Request DTO
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class PartnerUpdateReq {

    private String name;
    private String doctorName;
    private String address;
    private Double latitude;
    private Double longitude;
    private String phone;
    private String imageUrl;
    private List<String> galleryImages;
    private String description;
    private List<String> specialties;
    private List<String> availableTimes;
    private List<String> education;
    private String experience;
    private List<String> certifications;
    private Boolean isOpen;

    /**
     * Join list to comma-separated string
     */
    public String joinList(List<String> list) {
        if (list == null || list.isEmpty()) {
            return "";
        }
        return String.join(",", list);
    }
}
