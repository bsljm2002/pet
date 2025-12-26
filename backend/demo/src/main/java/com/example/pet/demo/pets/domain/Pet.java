package com.example.pet.demo.pets.domain;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import com.example.pet.demo.users.domain.User;
import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@Builder
@EntityListeners(AuditingEntityListener.class)
@Table(name = "pets")
public class Pet {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // FK: users.id
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    @JsonIgnore
    private User owner;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private Species species; // DOG | CAT

    @Column(name = "p_birthdate", nullable = false)
    private LocalDate birthdate;

    @Column(precision = 4, scale = 1, nullable = false)
    private BigDecimal weight;

    @Column(name = "p_image_url", length = 2048)
    private String imageUrl;

    @Column(name = "p_name", nullable = false, length = 20)
    private String name;

    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private Gender gender;

    @Column(name = "species_detail", length = 30)
    private String speciesDetail; // 품종

    @Column(name = "disease", length = 500)
    private String disease; // 질병 정보

    // JSON 직렬화를 위한 userId getter 추가
    public Long getUserId() {
        return owner != null ? owner.getId() : null;
    }

    // 생년월일에서 나이 계산
    public Integer getAge() {
        if (birthdate == null) return null;
        return java.time.Period.between(birthdate, java.time.LocalDate.now()).getYears();
    }

    // 펫 정보 업데이트 메서드
    public void update(
            Species species,
            LocalDate birthdate,
            BigDecimal weight,
            String imageUrl,
            String name,
            Gender gender,
            String speciesDetail,
            String disease) {
        this.species = species;
        this.birthdate = birthdate;
        this.weight = weight;
        this.imageUrl = imageUrl;
        this.name = name;
        this.gender = gender;
        this.speciesDetail = speciesDetail;
        this.disease = disease;
    }

    // 의료 정보만 업데이트하는 메서드 (의사용)
    public void updateMedicalInfo(BigDecimal weight, String disease) {
        if (weight != null) {
            this.weight = weight;
        }
        if (disease != null) {
            this.disease = disease;
        }
    }


    public enum Species {
        DOG, CAT
    }

    public enum Gender {
        MALE, FEMALE
    }
}
