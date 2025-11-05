package com.example.pet.demo.users.app;

import java.util.List;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.pet.demo.users.api.dto.UserSignupReq;
import com.example.pet.demo.users.domain.User.UserStatus;
import com.example.pet.demo.users.domain.User.UserType;
import com.example.pet.demo.users.domain.port.UserPersistencePort;
import com.example.pet.demo.users.domain.User;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional
public class UserService {
    private final UserPersistencePort users;
    private final PasswordEncoder passwordEncoder;

    public Long signup(UserSignupReq req) {
        // 1) 중복 검사
        if (users.existsByEmail(req.email())) {
            throw new IllegalArgumentException("DUPLICATE_EMAIL");
        }

        // 2) 비밀번호 해시
        String hashed = passwordEncoder.encode(req.password());

        // 3) 근무 요일 CSV 변환 (["월","화"] -> "월,화")
        // 근무 요일 CSV 변환은 병원/펫시터에만 적용
        final String workingDaysCsv =
                (req.userType() == UserType.HOSPITAL || req.userType() == UserType.SITTER)
                ? toCsv(req.workingDays())
                : null;

        // 4) userType별 필드 정리
        //    GENERAL은 파트너 전용 필드 무시(null), HOSPITAL/SITTER는 DTO에서 이미 유효성 검증했다고 가정
        UserType type = req.userType();
        String tin = null;
        User.CaCategorical caCat = null;
        User.VetSpecialty vet = null;
        User.PetsitterWork sitterWork = null;
        String start = null;
        String end = null;

        switch (type) {
            case GENERAL -> {
                tin = null; caCat = null; vet = null; sitterWork = null;
                start = null; end = null; // 근무시간 저장 금지
            }
            case HOSPITAL -> {
                tin = req.tin();
                caCat = req.caCategorical();
                vet = req.vetSpecialty();
                start = req.workingStartHours();
                end = req.workingEndHours();
            }
            case SITTER -> {
                tin = req.tin();
                caCat = req.caCategorical();
                sitterWork = req.petsitterWork();
                start = req.workingStartHours();
                end = req.workingEndHours();
            }
            // 필요 시 다른 타입(SELLER/GROOMING/CAFE)도 추가
            case SELLER, GROOMING, CAFE -> {
                // 파트너 전용 필드 저장 금지
            }
        }

        // 5) 엔티티 생성
        User user = User.builder()
                .username(req.username())
                .nickname(req.nickname())
                .email(req.email())
                .password(hashed)
                .gender(req.gender())
                .birthdate(req.birthdate())
                .address(req.address())
                .userType(type)                  // 기본값 GENERAL이지만 DTO에 맞춰 설정
                .status(UserStatus.ACTIVE)       // 기본 활성
                .tin(tin)        
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
    public User login(String email, String password){
        //1. email로 사용자 찾기
        User user = users.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("이메일 또는 비밀번호가 일치하지 않습니다."));
        // 2. 비밀번호 확인
        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new IllegalArgumentException("이메일 또는 비밀번호가 일치하지 않습니다.");
        }

        // 3. 계정 상태 확인 (선택사항)
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new IllegalArgumentException("비활성화된 계정입니다.");
        }

        // 4. 로그인 성공 - User 엔티티 반환
        return user;
    }

    private String toCsv(List<String> days) {
        return (days == null || days.isEmpty()) ? null : String.join(",", days);
    }

    public boolean checkEmailExists(String email) {
        return users.existsByEmail(email);
    }

}
