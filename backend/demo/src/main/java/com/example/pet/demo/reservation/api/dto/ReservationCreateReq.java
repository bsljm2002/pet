package com.example.pet.demo.reservation.api.dto;

import java.time.OffsetDateTime;
import java.util.List;

import com.example.pet.demo.users.domain.User.PetsitterWork;
import com.example.pet.demo.users.domain.User.UserType;
import com.example.pet.demo.users.domain.User.VetSpecialty;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record ReservationCreateReq (
    @NotNull @JsonProperty("partner_id") Long partnerId,
    
    @NotNull @JsonProperty("user_id") 
    Long userId,
    
    @NotNull @JsonProperty("user_type") 
    UserType userType,

    @JsonProperty("vet_specialties")
    List<VetSpecialty> vetSpecialties,  // 병원 예약: ["DENTISTRY","DERMATOLOGY"]

    @JsonProperty("petsitter_works")
    List<PetsitterWork> petsitterWorks,

    @NotNull @JsonProperty("pets_id") 
    Long petId,
    
    @NotNull
    @JsonProperty("created_at")
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss.SSSX")
    OffsetDateTime createdAt,
    
    // @Size(max = 2048) @JsonProperty("resv_url") 
    // String reservationImageUrl,

    @JsonProperty("resv_urls")
    List<String> reservationImageUrls,
    
    @NotBlank @Size(max = 2000) @JsonProperty("resv_content") String reservationContent
    ) {
    @AssertTrue(message = "vet_specialties는 HOSPITAL 예약에서 필수입니다.")
    private boolean hospitalRequiresVetSpecialties() {
        return userType != UserType.HOSPITAL || (vetSpecialties != null && !vetSpecialties.isEmpty());
    }

    @AssertTrue(message = "petsitter_works는 SITTER 예약에서 필수입니다.")
    private boolean sitterRequiresPetsitterWorks() {
        return userType != UserType.SITTER || (petsitterWorks != null && !petsitterWorks.isEmpty());
    }
}
