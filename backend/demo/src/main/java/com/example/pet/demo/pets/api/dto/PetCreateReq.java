package com.example.pet.demo.pets.api.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record PetCreateReq(
    Long userId,

    @Pattern(regexp = "DOG|CAT", message = "species는 DOG 또는 CAT 이어야 합니다.")
    String species,

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    LocalDate birthdate,

    @DecimalMin(value = "0.0", inclusive = false, message = "weight는 0보다 커야 합니다.")
    @Digits(integer = 3, fraction = 1, message = "weight는 최대 정수 3자리, 소수 1자리입니다.")
    BigDecimal weight,

    @Size(max = 2048, message = "imageUrl은 최대 2048자입니다.")
    String imageUrl,

    @Size(max = 20, message = "name은 최대 20자입니다.")
    String name,

    @Pattern(regexp = "MALE|FEMALE", message = "gender는 MALE 또는 FEMALE 이어야 합니다.")
    String gender,

    @Size(max = 30, message = "speciesDetail은 최대 30자입니다.")
    String speciesDetail,

    @Size(max = 500, message = "disease는 최대 500자입니다.")
    String disease
) {}
