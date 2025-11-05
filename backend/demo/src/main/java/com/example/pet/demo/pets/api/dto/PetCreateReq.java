package com.example.pet.demo.pets.api.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record PetCreateReq(
    @NotNull(message = "user_id는 필수입니다.")
    Long userId,

    @NotBlank(message = "species는 필수입니다.")
    @Pattern(regexp = "DOG|CAT", message = "species는 DOG 또는 CAT 이어야 합니다.")
    String species,

    @NotNull(message = "birthdate는 필수입니다.")
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    LocalDate birthdate,

    @NotNull(message = "weight는 필수입니다.")
    @DecimalMin(value = "0.0", inclusive = false, message = "weight는 0보다 커야 합니다.")
    @Digits(integer = 3, fraction = 1, message = "weight는 최대 정수 3자리, 소수 1자리입니다.")
    BigDecimal weight,

    @NotBlank(message = "abit_type_code는 필수입니다.")
    @Pattern(
        regexp = "ISTJ|ISFJ|INFJ|INTJ|ISTP|ISFP|INFP|INTP|ESTP|ESFP|ENFP|ENTP|ESTJ|ESFJ|ENFJ|ENTJ",
        message = "abit_type_code는 유효한 MBTI 코드여야 합니다."
    )

    @Size(max = 2048, message = "imageUrl은 최대 2048자입니다.")
    String imageUrl,

    String abitTypeCode,

    @NotBlank(message = "name은 필수입니다.")
    @Size(max = 20, message = "name은 최대 20자입니다.")
    String name
) {}
