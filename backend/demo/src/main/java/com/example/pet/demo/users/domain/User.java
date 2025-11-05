package com.example.pet.demo.users.domain;

import java.time.LocalDate;
import java.time.LocalDateTime;

import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

// 엔티티
@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@Builder
@EntityListeners(AuditingEntityListener.class)
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 20)
    private String username;

    @Column(nullable = false, length = 50)
    private String nickname;

    @Column(nullable = false, length = 255)
    private String email;

    @Column(nullable = false, length = 255)
    private String password;

    @Column(nullable = false, length = 10)
    private String gender;

    @Column(nullable = false)
    private LocalDate birthdate;

    @Column(nullable = false, length = 255)
    private String address;

    @Enumerated(EnumType.STRING)
    @Column(name = "user_type", nullable = false, length = 20)
    @Builder.Default
    private UserType userType = UserType.GENERAL;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private UserStatus status = UserStatus.ACTIVE;

    @Column(length = 50)
    private String tin; 

    @Enumerated(EnumType.STRING)
    @Column(name = "ca_categorical", length = 10)
    private CaCategorical caCategorical;

    @Enumerated(EnumType.STRING)
    @Column(name = "vet_specialty", length = 30)
    private VetSpecialty vetSpecialty;   

    @Enumerated(EnumType.STRING)
    @Column(name = "petsitter_work", length = 20)
    private PetsitterWork petsitterWork;

    @Column(name = "working_days")
    private String workingDays;

    @Column(name = "working_start_hours", length = 10)
    private String workingStartHours; 

    @Column(name = "working_end_hours", length = 10)
    private String workingEndHours; 

    @Column(name = "locked_until")
    private LocalDateTime lockedUntil;

    @Column(name = "last_login_at")
    private LocalDateTime lastLoginAt; 

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    public boolean isActive() { return this.status == UserStatus.ACTIVE; }
    public void markLastLoginNow() { this.lastLoginAt = LocalDateTime.now(); }
    public void lockUntil(LocalDateTime until) { this.status = UserStatus.LOCKED; this.lockedUntil = until; }

    public enum UserType { GENERAL, SELLER, HOSPITAL, GROOMING, SITTER, CAFE }

    public enum UserStatus { ACTIVE, LOCKED, DELETED }

    // 개/고양이/둘
    public enum CaCategorical { DOG, CAT, BOTH }

    // 진료과목 (스크린샷 기준의 한글 항목을 영문 코드로 정규화)
    public enum VetSpecialty {
        INTERNAL_MEDICINE,    // 내과
        SURGERY,              // 외과
        ORTHOPEDICS,          // 정형외과
        OPHTHALMOLOGY,        // 안과
        DENTISTRY,            // 치과
        DERMATOLOGY,          // 피부과
        EMERGENCY_MEDICINE,   // 응급의학과
        GENERAL               // 기타/전체
    }

    // 펫시터 업무: 산책/이동/위생관리/전체
    public enum PetsitterWork { WALK, TRANSPORT, HYGIENE, ALL }
}
