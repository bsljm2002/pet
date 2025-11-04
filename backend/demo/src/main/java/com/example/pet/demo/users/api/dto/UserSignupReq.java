package com.example.pet.demo.users.api.dto;

import java.time.LocalDate;
import java.util.List;

import com.example.pet.demo.users.domain.User.CaCategorical;
import com.example.pet.demo.users.domain.User.PetsitterWork;
import com.example.pet.demo.users.domain.User.UserType;
import com.example.pet.demo.users.domain.User.VetSpecialty;
import com.fasterxml.jackson.annotation.JsonFormat;


import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record UserSignupReq(
    @NotNull(message = "user_type은 필수입니다.")
    UserType userType,

    @NotBlank(message = "username은 필수입니다.")
    @Size(max = 20, message = "username은 20자 이하입니다.")
    String username,

    @NotBlank(message = "nickname은 필수입니다.")
    @Size(max = 50, message = "nickname은 50자 이하입니다.")
    String nickname,

    @NotBlank(message = "이메일은 필수입니다.")
    @Email(message = "올바른 이메일 형식이 아닙니다.")
    @Size(max = 255, message = "이메일은 255자 이하입니다.")
    String email,

    @NotBlank(message = "비밀번호는 필수입니다.")
    @Size(min = 8, max = 64, message = "비밀번호는 8~64자입니다.")
    // 필요한 경우 복잡도 정책 추가:
    // @Pattern(regexp="^(?=.*[A-Za-z])(?=.*\\d)(?=.*[!@#$%^&*()_+\\-={}\\[\\]|:;\"'<>,.?/]).{8,64}$",
    //          message="비밀번호는 문자/숫자/특수문자를 각각 1자 이상 포함해야 합니다.")
    String password,

    @NotBlank(message = "gender는 필수입니다.")
    @Size(max = 10, message = "gender는 최대 10자입니다.")
    String gender,

    @NotNull(message = "birthdate는 필수입니다.")
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    LocalDate birthdate,

    @Size(max = 255, message = "address는 최대 255자입니다.")
    String address,

    // 파트너 공통(둘 다 필수, GENERAL은 null 허용)
    @Size(max = 50, message = "tin은 최대 50자입니다.")
    String tin,

    CaCategorical caCategorical,                  // "dog" | "cat" | "both"

    // 병원 전용
    VetSpecialty vetSpecialty,                    // "surgery" 등

    // 펫시터 전용
    PetsitterWork petsitterWork,                  // "walk" 등

    // 근무 정보(선택)
    List<String> workingDays,

    @Pattern(regexp = "^\\d{2}:\\d{2}(:\\d{2})?$", message = "working_start_hours는 HH:mm 또는 HH:mm:ss 형식")
    String workingStartHours,

    @Pattern(regexp = "^\\d{2}:\\d{2}(:\\d{2})?$", message = "working_end_hours는 HH:mm 또는 HH:mm:ss 형식")
    String workingEndHours

) {
//     @AssertTrue(message = "HOSPITAL은 tin, ca_categorical, vet_specialty가 필수입니다.")
//     public boolean isHospitalValid() {
//         if (userType == UserType.HOSPITAL) {
//             return notBlank(tin) && caCategorical != null && vetSpecialty != null;
//         }
//         return true;
//     }
//     @AssertTrue(message = "SITTER는 tin, ca_categorical, petsitter_work가 필수입니다.")
//     public boolean isSitterValid() {
//         if (userType == UserType.SITTER) {
//             return notBlank(tin) && caCategorical != null && petsitterWork != null;
//         }
//         return true;
//     }

//     private boolean notBlank(String s) { return s != null && !s.isBlank(); }
}

