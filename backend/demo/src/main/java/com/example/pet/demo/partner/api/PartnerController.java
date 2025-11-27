package com.example.pet.demo.partner.api;

import com.example.pet.demo.common.ApiResponse;
import com.example.pet.demo.partner.api.dto.PartnerCreateReq;
import com.example.pet.demo.partner.api.dto.PartnerListRes;
import com.example.pet.demo.partner.api.dto.PartnerRes;
import com.example.pet.demo.partner.api.dto.PartnerUpdateReq;
import com.example.pet.demo.partner.app.PartnerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Partner Controller
 * 수의사/펫시터 관련 API 엔드포인트
 */
@RestController
@RequestMapping("/api/v1/partners")
@RequiredArgsConstructor
@Validated
public class PartnerController {

    private final PartnerService partnerService;

    /**
     * 파트너 목록 조회
     *
     * GET /api/v1/partners?type=HOSPITAL&specialty=내과
     *
     * @param type 파트너 유형 ("HOSPITAL" 또는 "SITTER")
     * @param specialty 전문분야 필터 (선택)
     * @return 파트너 목록
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<PartnerListRes>>> getPartners(
            @RequestParam("type") String type,
            @RequestParam(value = "specialty", required = false) String specialty
    ) {
        List<PartnerListRes> partners = partnerService.getPartners(type, specialty);
        return ResponseEntity.ok(ApiResponse.ok(partners));
    }

    /**
     * 파트너 상세 조회
     *
     * GET /api/v1/partners/{partnerId}
     *
     * @param partnerId 파트너 ID
     * @return 파트너 상세 정보
     */
    @GetMapping("/{partnerId}")
    public ResponseEntity<ApiResponse<PartnerListRes>> getPartner(
            @PathVariable("partnerId") Long partnerId
    ) {
        PartnerListRes partner = partnerService.getPartner(partnerId);
        return ResponseEntity.ok(ApiResponse.ok(partner));
    }

    /**
     * 파트너 생성
     *
     * POST /api/v1/partners
     *
     * @param req 파트너 생성 요청
     * @return 생성된 파트너 ID
     */
    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Long>>> createPartner(
            @Valid @RequestBody PartnerCreateReq req
    ) {
        Long partnerId = partnerService.createPartner(req);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("partnerId", partnerId)));
    }

    /**
     * 파트너 정보 수정
     *
     * PUT /api/v1/partners/{partnerId}
     *
     * @param partnerId 파트너 ID
     * @param name 이름
     * @param address 주소
     * @param phone 전화번호
     * @param description 설명
     * @return 성공 응답
     */
    @PutMapping("/{partnerId}")
    public ResponseEntity<ApiResponse<Map<String, String>>> updatePartner(
            @PathVariable("partnerId") Long partnerId,
            @RequestParam(value = "name", required = false) String name,
            @RequestParam(value = "address", required = false) String address,
            @RequestParam(value = "phone", required = false) String phone,
            @RequestParam(value = "description", required = false) String description
    ) {
        partnerService.updatePartner(partnerId, name, address, phone, description);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("message", "파트너 정보가 수정되었습니다.")));
    }

    /**
     * 파트너 위치 정보 수정
     *
     * PATCH /api/v1/partners/{partnerId}/location
     *
     * @param partnerId 파트너 ID
     * @param latitude 위도
     * @param longitude 경도
     * @return 성공 응답
     */
    @PatchMapping("/{partnerId}/location")
    public ResponseEntity<ApiResponse<Map<String, String>>> updateLocation(
            @PathVariable("partnerId") Long partnerId,
            @RequestParam("latitude") Double latitude,
            @RequestParam("longitude") Double longitude
    ) {
        partnerService.updateLocation(partnerId, latitude, longitude);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("message", "위치 정보가 수정되었습니다.")));
    }

    /**
     * 파트너 이미지 수정
     *
     * PATCH /api/v1/partners/{partnerId}/image
     *
     * @param partnerId 파트너 ID
     * @param imageUrl 이미지 URL
     * @return 성공 응답
     */
    @PatchMapping("/{partnerId}/image")
    public ResponseEntity<ApiResponse<Map<String, String>>> updateImage(
            @PathVariable("partnerId") Long partnerId,
            @RequestParam("imageUrl") String imageUrl
    ) {
        partnerService.updateImage(partnerId, imageUrl);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("message", "이미지가 수정되었습니다.")));
    }

    /**
     * 파트너 영업 상태 토글
     *
     * PATCH /api/v1/partners/{partnerId}/toggle-open
     *
     * @param partnerId 파트너 ID
     * @return 성공 응답
     */
    @PatchMapping("/{partnerId}/toggle-open")
    public ResponseEntity<ApiResponse<Map<String, String>>> toggleOpen(
            @PathVariable("partnerId") Long partnerId
    ) {
        partnerService.toggleOpen(partnerId);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("message", "영업 상태가 변경되었습니다.")));
    }

    /**
     * 사용자의 파트너 목록 조회 (파트너 계정용)
     *
     * GET /api/v1/partners/my?userId=123
     *
     * @param userId 사용자 ID
     * @return 파트너 목록
     */
    @GetMapping("/my")
    public ResponseEntity<ApiResponse<List<PartnerListRes>>> getMyPartners(
            @RequestParam("userId") Long userId
    ) {
        List<PartnerListRes> partners = partnerService.getMyPartners(userId);
        return ResponseEntity.ok(ApiResponse.ok(partners));
    }

    /**
     * 파트너 프로필 전체 수정
     *
     * PUT /api/v1/partners/{partnerId}/profile
     *
     * @param partnerId 파트너 ID
     * @param req 수정 요청
     * @return 수정된 파트너 정보
     */
    @PutMapping("/{partnerId}/profile")
    public ResponseEntity<ApiResponse<PartnerRes>> updatePartnerProfile(
            @PathVariable("partnerId") Long partnerId,
            @Valid @RequestBody PartnerUpdateReq req
    ) {
        PartnerRes partner = partnerService.updatePartnerProfile(partnerId, req);
        return ResponseEntity.ok(ApiResponse.ok(partner));
    }

    /**
     * 파트너 삭제
     *
     * DELETE /api/v1/partners/{partnerId}
     *
     * @param partnerId 파트너 ID
     * @return 성공 응답
     */
    @DeleteMapping("/{partnerId}")
    public ResponseEntity<ApiResponse<Map<String, String>>> deletePartner(
            @PathVariable("partnerId") Long partnerId
    ) {
        partnerService.deletePartner(partnerId);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("message", "파트너가 삭제되었습니다.")));
    }

    /**
     * 파트너 상세 조회 (PartnerRes 반환)
     *
     * GET /api/v1/partners/{partnerId}/detail
     *
     * @param partnerId 파트너 ID
     * @return 파트너 상세 정보
     */
    @GetMapping("/{partnerId}/detail")
    public ResponseEntity<ApiResponse<PartnerRes>> getPartnerDetail(
            @PathVariable("partnerId") Long partnerId
    ) {
        PartnerRes partner = partnerService.getPartnerDetail(partnerId);
        return ResponseEntity.ok(ApiResponse.ok(partner));
    }
}
