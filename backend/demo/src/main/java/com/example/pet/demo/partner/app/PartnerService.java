package com.example.pet.demo.partner.app;

import com.example.pet.demo.partner.api.dto.PartnerCreateReq;
import com.example.pet.demo.partner.api.dto.PartnerListRes;
import com.example.pet.demo.partner.api.dto.PartnerRes;
import com.example.pet.demo.partner.api.dto.PartnerUpdateReq;
import com.example.pet.demo.partner.domain.Partner;
import com.example.pet.demo.partner.domain.PartnerRepository;
import com.example.pet.demo.partner.domain.PartnerType;
import com.example.pet.demo.users.domain.User;
import com.example.pet.demo.users.domain.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Partner Service
 * 수의사/펫시터 비즈니스 로직 처리
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PartnerService {

    private final PartnerRepository partnerRepository;
    private final UserRepository userRepository;

    /**
     * 파트너 목록 조회 (수의사 또는 펫시터)
     *
     * @param partnerType "HOSPITAL" 또는 "SITTER"
     * @param specialty 전문분야 필터 (선택)
     * @return 파트너 목록
     */
    public List<PartnerListRes> getPartners(String partnerType, String specialty) {
        PartnerType type = PartnerType.valueOf(partnerType);

        List<Partner> partners;
        if (specialty != null && !specialty.isEmpty()) {
            partners = partnerRepository.searchBySpecialty(type, specialty);
        } else {
            partners = partnerRepository.findByPartnerTypeAndIsOpen(type, true);
        }

        return partners.stream()
                .map(partner -> {
                    User user = null;
                    if (partner.getUserId() != null) {
                        user = userRepository.findById(partner.getUserId()).orElse(null);
                    }
                    return PartnerListRes.from(partner, user);
                })
                .collect(Collectors.toList());
    }

    /**
     * 파트너 상세 조회
     *
     * @param partnerId 파트너 ID
     * @return 파트너 상세 정보
     */
    public PartnerListRes getPartner(Long partnerId) {
        Partner partner = partnerRepository.findById(partnerId)
                .orElseThrow(() -> new IllegalArgumentException("파트너를 찾을 수 없습니다: " + partnerId));

        User user = null;
        if (partner.getUserId() != null) {
            user = userRepository.findById(partner.getUserId()).orElse(null);
        }

        return PartnerListRes.from(partner, user);
    }

    /**
     * 파트너 생성
     *
     * @param req 파트너 생성 요청
     * @return 생성된 파트너 ID
     */
    @Transactional
    public Long createPartner(PartnerCreateReq req) {
        Partner partner = req.toEntity();
        Partner saved = partnerRepository.save(partner);
        return saved.getId();
    }

    /**
     * 파트너 정보 업데이트
     *
     * @param partnerId 파트너 ID
     * @param name 이름
     * @param address 주소
     * @param phone 전화번호
     * @param description 설명
     */
    @Transactional
    public void updatePartner(Long partnerId, String name, String address, String phone, String description) {
        Partner partner = partnerRepository.findById(partnerId)
                .orElseThrow(() -> new IllegalArgumentException("파트너를 찾을 수 없습니다: " + partnerId));

        partner.updateInfo(name, address, phone, description);
    }

    /**
     * 파트너 위치 정보 업데이트
     *
     * @param partnerId 파트너 ID
     * @param latitude 위도
     * @param longitude 경도
     */
    @Transactional
    public void updateLocation(Long partnerId, Double latitude, Double longitude) {
        Partner partner = partnerRepository.findById(partnerId)
                .orElseThrow(() -> new IllegalArgumentException("파트너를 찾을 수 없습니다: " + partnerId));

        partner.updateLocation(latitude, longitude);
    }

    /**
     * 파트너 이미지 업데이트
     *
     * @param partnerId 파트너 ID
     * @param imageUrl 이미지 URL
     */
    @Transactional
    public void updateImage(Long partnerId, String imageUrl) {
        Partner partner = partnerRepository.findById(partnerId)
                .orElseThrow(() -> new IllegalArgumentException("파트너를 찾을 수 없습니다: " + partnerId));

        partner.updateImage(imageUrl);
    }

    /**
     * 파트너 영업 상태 토글
     *
     * @param partnerId 파트너 ID
     */
    @Transactional
    public void toggleOpen(Long partnerId) {
        Partner partner = partnerRepository.findById(partnerId)
                .orElseThrow(() -> new IllegalArgumentException("파트너를 찾을 수 없습니다: " + partnerId));

        partner.toggleOpen();
    }

    /**
     * 파트너 평점 업데이트
     *
     * @param partnerId 파트너 ID
     * @param rating 새로운 평점
     */
    @Transactional
    public void updateRating(Long partnerId, Double rating) {
        Partner partner = partnerRepository.findById(partnerId)
                .orElseThrow(() -> new IllegalArgumentException("파트너를 찾을 수 없습니다: " + partnerId));

        partner.updateRating(rating);
    }

    /**
     * 사용자의 파트너 목록 조회 (파트너 계정용)
     *
     * @param userId 사용자 ID
     * @return 파트너 목록
     */
    public List<PartnerListRes> getMyPartners(Long userId) {
        List<Partner> partners = partnerRepository.findByUserId(userId);
        User user = userRepository.findById(userId).orElse(null);

        return partners.stream()
                .map(partner -> PartnerListRes.from(partner, user))
                .collect(Collectors.toList());
    }

    /**
     * 파트너 프로필 전체 수정
     *
     * @param partnerId 파트너 ID
     * @param req 수정 요청
     */
    @Transactional
    public PartnerRes updatePartnerProfile(Long partnerId, PartnerUpdateReq req) {
        Partner partner = partnerRepository.findById(partnerId)
                .orElseThrow(() -> new IllegalArgumentException("파트너를 찾을 수 없습니다: " + partnerId));

        // 기본 정보 업데이트
        if (req.getName() != null) {
            partner.updateInfo(
                    req.getName(),
                    req.getAddress() != null ? req.getAddress() : partner.getAddress(),
                    req.getPhone() != null ? req.getPhone() : partner.getPhone(),
                    req.getDescription() != null ? req.getDescription() : partner.getDescription()
            );
        }

        // 위치 정보 업데이트
        if (req.getLatitude() != null && req.getLongitude() != null) {
            partner.updateLocation(req.getLatitude(), req.getLongitude());
        }

        // 이미지 업데이트
        if (req.getImageUrl() != null) {
            partner.updateImage(req.getImageUrl());
        }

        // 영업 상태 업데이트
        if (req.getIsOpen() != null && partner.getIsOpen() != req.getIsOpen()) {
            partner.toggleOpen();
        }

        // 프로필 상세 정보 업데이트 (진료과목, 시간, 자격증 등)
        partner.updateProfileDetails(
                req.getDoctorName(),
                req.joinList(req.getSpecialties()),
                req.joinList(req.getAvailableTimes()),
                req.joinList(req.getEducation()),
                req.getExperience(),
                req.joinList(req.getCertifications())
        );

        Partner updated = partnerRepository.saveAndFlush(partner);
        return PartnerRes.from(updated);
    }

    /**
     * 파트너 삭제
     *
     * @param partnerId 파트너 ID
     */
    @Transactional
    public void deletePartner(Long partnerId) {
        Partner partner = partnerRepository.findById(partnerId)
                .orElseThrow(() -> new IllegalArgumentException("파트너를 찾을 수 없습니다: " + partnerId));

        partnerRepository.delete(partner);
    }

    /**
     * 파트너 상세 조회 (PartnerRes로 반환)
     *
     * @param partnerId 파트너 ID
     * @return 파트너 상세 정보
     */
    public PartnerRes getPartnerDetail(Long partnerId) {
        Partner partner = partnerRepository.findById(partnerId)
                .orElseThrow(() -> new IllegalArgumentException("파트너를 찾을 수 없습니다: " + partnerId));

        return PartnerRes.from(partner);
    }
}
