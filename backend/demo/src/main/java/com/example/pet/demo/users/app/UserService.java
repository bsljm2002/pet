package com.example.pet.demo.users.app;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.pet.demo.users.api.dto.UserSignupReq;
import com.example.pet.demo.users.domain.User.UserStatus;
import com.example.pet.demo.users.domain.User.UserType;
import com.example.pet.demo.users.domain.UserRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional
public class UserService {
    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;

    public Long signup(UserSignupReq req) {
        // 1) 중복 검사
        if (users.existsByEmail(req.email())) {
            throw new IllegalArgumentException("DUPLICATE_EMAIL");
        }

        // 2) 비밀번호 해시
        String hashed = passwordEncoder.encode(req.password());

        // 3) 근무 요일 CSV 변환 (["월","화"] -> "월,화")
        String workingDaysCsv = toCsv(req.workingDays());

        // 4) userType별 필드 정리
        //    GENERAL은 파트너 전용 필드 무시(null), HOSPITAL/SITTER는 DTO에서 이미 유효성 검증했다고 가정
        UserType type = req.userType();
        String tin = null;
        User.CaCategorical caCat = null;
        User.VetSpecialty vet = null;
        User.PetsitterWork sitterWork = null;

        switch (type) {
            case GENERAL -> {
                // 파트너 전용 필드는 저장하지 않음
            }
            case HOSPITAL -> {
                tin = req.tin();
                caCat = req.caCategorical();
                vet = req.vetSpecialty();
            }
            case SITTER -> {
                tin = req.tin();
                caCat = req.caCategorical();
                sitterWork = req.petsitterWork();
            }
            // 필요 시 다른 타입(SELLER/GROOMING/CAFE)도 추가
        }

        // 5) 엔티티 생성
        User user = User.builder()
                .username(req.username())
                .email(req.email())
                .password(hashed)
                .gender(req.gender())
                .birthdate(req.birthdate())
                .address(req.address())
                .userType(type)                  // 기본값 GENERAL이지만 DTO에 맞춰 설정
                .status(UserStatus.ACTIVE)       // 기본 활성
                .tin(tin)
                .businessAddress(null)           // 필요 시 DTO에 추가해 매핑
                .caCategorical(caCat)
                .vetSpecialty(vet)
                .petsitterWork(sitterWork)
                .workingDays(workingDaysCsv)
                .workingStartHours(req.workingStartHours())
                .workingEndHours(req.workingEndHours())
                .build();

        // (선택) 근무시간 논리 검증이 필요하면 여기서 수행(HH:mm[:ss] 비교)

        // 6) 저장 및 ID 반환
        return users.save(user).getId();
    }

}
