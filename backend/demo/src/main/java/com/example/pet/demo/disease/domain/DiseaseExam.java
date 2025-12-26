package com.example.pet.demo.disease.domain;

import java.time.LocalDateTime;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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

@Entity
@Table(name = "disease_exam")
@Getter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
public class DiseaseExam {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Enumerated(EnumType.STRING)
    @Column(name = "requested_type", nullable = false)
    private RequestedType requestedType;

    @Enumerated(EnumType.STRING)
    @Column(name = "summary_label", nullable = false)
    private SummaryLabel summaryLabel;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "disease_result", nullable = false, columnDefinition = "json")
    private String diseaseResult; // JSON 문자열

    @Column(name = "d_image_url", nullable = false, length = 2048)
    private String imageUrl;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    public enum RequestedType {
        EYE, SKIN, OBESITY
    }

    public enum SummaryLabel {
        NORMAL,   // 정상
        SUSPECT,  // 질병 의심
        CAUTION   // 주의
    }
}
