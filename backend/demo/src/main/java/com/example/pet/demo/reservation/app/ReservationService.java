package com.example.pet.demo.reservation.app;

import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.pet.demo.notification.NotificationService;
import com.example.pet.demo.partner.domain.Partner;
import com.example.pet.demo.partner.domain.PartnerRepository;
import com.example.pet.demo.pets.domain.Pet;
import com.example.pet.demo.pets.app.PetService;
import com.example.pet.demo.reservation.api.dto.AIDiagnosisDto;
import com.example.pet.demo.reservation.api.dto.CompletedReservationRes;
import com.example.pet.demo.reservation.api.dto.MyReservationRes;
import com.example.pet.demo.reservation.api.dto.ReservationCreateReq;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.example.pet.demo.reservation.domain.Reservation;
import com.example.pet.demo.reservation.domain.Reservation.ReservationStatus;
import com.example.pet.demo.reservation.domain.Reservation.ServiceCategorical;
import com.example.pet.demo.reservation.domain.ReservationRepository;
import com.example.pet.demo.reservation.domain.port.ReservationPersistencePort;
import com.example.pet.demo.review.domain.ReviewRepository;
import com.example.pet.demo.users.app.UserService;
import com.example.pet.demo.users.domain.User;
import com.example.pet.demo.chat.domain.ChatRoom;
import com.example.pet.demo.chat.domain.ChatRoomRepository;
import com.example.pet.demo.medication.app.MedicationLogService;

import java.util.stream.Collectors;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional
public class ReservationService {
    private final ReservationPersistencePort reservations;
    private final ReservationRepository reservationRepository;
    private final PartnerRepository partnerRepository;
    private final ReviewRepository reviewRepository;
    private final NotificationService notificationService;
    private final UserService userService;
    private final PetService petService;
    private final ChatRoomRepository chatRoomRepository;
    private final MedicationLogService medicationLogService;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy.MM.dd");

    public Long create(ReservationCreateReq req) {
        // Partner ID로부터 실제 User ID 조회
        Partner partner = partnerRepository.findById(req.partnerId())
            .orElseThrow(() -> new IllegalArgumentException("PARTNER_NOT_FOUND"));

        Long partnerUserId = partner.getUserId();
        if (partnerUserId == null) {
            throw new IllegalArgumentException("PARTNER_USER_ID_NOT_FOUND");
        }

        String imageCsv = toCsv(req.reservationImageUrls());

        // AI 진단 정보를 JSON으로 변환
        String aiDiagnosisJson = null;
        if (req.aiDiagnoses() != null && !req.aiDiagnoses().isEmpty()) {
            try {
                aiDiagnosisJson = objectMapper.writeValueAsString(req.aiDiagnoses());
            } catch (Exception e) {
                System.out.println("⚠️ AI 진단 정보 JSON 변환 실패: " + e.getMessage());
            }
        }

        Reservation reservation = Reservation.builder()
            .userId(req.userId())
            .partnerId(partnerUserId)  // Partner의 User ID 사용
            .serviceCategorical(ServiceCategorical.valueOf(req.userType().name()))
            .userType(req.userType())
            .status(ReservationStatus.WAITING)
            .createdAt(OffsetDateTime.now())  // 현재 시간을 예약 생성 시간으로
            .visitDateTime(req.visitDateTime())  // 사용자가 선택한 방문 시간
            .reservationImageUrl(imageCsv)
            .reservationContent(req.reservationContent())
            .petId(req.petId())
            .vetSpecialtyCsv(toCsv(req.vetSpecialties()))
            .petsitterWorkCsv(toCsv(req.petsitterWorks()))
            .aiDiagnosisData(aiDiagnosisJson)  // AI 진단 정보 저장
            .build();

        Reservation savedReservation = reservations.save(reservation);

        // 채팅방 즉시 생성 (펫시터 예약인 경우)
        if (req.userType() == com.example.pet.demo.users.domain.User.UserType.SITTER) {
            try {
                createChatRoomForReservation(savedReservation);
                System.out.println("✅ 예약 생성과 함께 채팅방 생성 완료: reservationId=" + savedReservation.getId());
            } catch (Exception e) {
                System.out.println("⚠️ 채팅방 생성 실패 (테이블 미생성 가능성): " + e.getMessage());
                // 채팅방 생성 실패해도 예약 생성은 계속 진행
            }
        }

        return savedReservation.getId();
    }

    public void updateReservationImage(Long reservationId, String imageUrl) {
        Reservation reservation = reservations.findById(reservationId)
            .orElseThrow(() -> new IllegalArgumentException("RESERVATION_NOT_FOUND"));
        reservation.setReservationImageUrl(imageUrl);
        reservations.save(reservation);
    }

    private String toCsv(Collection<?> values) {
        return (values == null || values.isEmpty())
                ? null
                : values.stream()
                        .map(Object::toString)
                        .map(String::trim)
                        .filter(s -> !s.isEmpty())
                        .reduce((a, b) -> a + "," + b)
                        .orElse(null);
    }

    @Transactional(readOnly = true)
    public Reservation get(Long reservationId) {
        return reservations.findById(reservationId)
                .orElseThrow(() -> new IllegalArgumentException("RESERVATION_NOT_FOUND"));
    }

    public void accept(Long reservationId, Long partnerId) {
        Reservation reservation = get(reservationId);

        // Partner ID로부터 User ID 조회
        Partner partner = partnerRepository.findById(partnerId)
            .orElseThrow(() -> new IllegalArgumentException("PARTNER_NOT_FOUND"));

        Long partnerUserId = partner.getUserId();
        if (partnerUserId == null) {
            throw new IllegalArgumentException("PARTNER_USER_ID_NOT_FOUND");
        }

        // 파트너 검증 (User ID 비교)
        if (!reservation.getPartnerId().equals(partnerUserId)) {
            throw new IllegalArgumentException("PARTNER_NOT_MATCHED");
        }

        // 상태 변경
        reservation.setStatus(ReservationStatus.CONFIRMED);
        reservations.save(reservation);

        // 채팅방 자동 생성 (예약 확정 시) - 채팅방 테이블이 있을 때만 실행
        try {
            createChatRoomForReservation(reservation);
        } catch (Exception e) {
            System.out.println("⚠️ 채팅방 생성 실패 (테이블 미생성 가능성): " + e.getMessage());
            // 채팅방 생성 실패해도 예약 확정은 계속 진행
        }

        try {
            User user = userService.get(reservation.getUserId());
            String token = user.getFcmToken();
            if (token != null && !token.isBlank()) {
                notificationService.sendReservationAccepted(token, reservationId);
            }
        } catch (Exception e) {
            // 알림 실패는 로깅만 하고 흐름 유지
        }
    }

    /**
     * 예약에 대한 채팅방 생성
     * 예약이 확정(CONFIRMED)되면 자동으로 호출됨
     */
    private void createChatRoomForReservation(Reservation reservation) {
        // 이미 채팅방이 존재하는지 확인
        if (chatRoomRepository.existsByReservationId(reservation.getId())) {
            System.out.println("✅ 채팅방이 이미 존재합니다. reservationId=" + reservation.getId());
            return;
        }

        // 채팅방 생성
        ChatRoom chatRoom = ChatRoom.builder()
            .reservationId(reservation.getId())
            .userId(reservation.getUserId())
            .partnerId(reservation.getPartnerId())
            .serviceType(reservation.getServiceCategorical().name())
            .createdAt(OffsetDateTime.now())
            .isActive(true)
            .build();

        chatRoomRepository.save(chatRoom);
        System.out.println("✅ 채팅방 생성 완료: reservationId=" + reservation.getId() + ", chatRoomId=" + chatRoom.getId());
    }

    @Transactional(readOnly = true)
    public List<MyReservationRes> getMyReservations(Long userId, String serviceType) {
        List<Reservation> list = reservations.findByUserId(userId);
        return list.stream()
                // 상담 레코드 제외 (visitDateTime이 50년 이상 미래인 것 = 더미 데이터)
                .filter(r -> r.getVisitDateTime() != null &&
                        r.getVisitDateTime().isBefore(OffsetDateTime.now().plusYears(50)))
                .filter(r -> serviceType == null
                        || r.getServiceCategorical().name().equalsIgnoreCase(serviceType))
                .map(this::toRes)
                .toList();
    }

    private MyReservationRes toRes(Reservation r) {
        var dt = r.getVisitDateTime();             // 방문 시간 사용
        // 한국 시간대(Asia/Seoul)로 변환하여 로컬 시간 유지
        var local = dt.atZoneSameInstant(java.time.ZoneId.of("Asia/Seoul")).toLocalDateTime();
        String slotLabel = local.getHour() < 12 ? "오전 진료" : "오후 진료";
        String date = local.format(DATE_FMT);
        Integer hour = local.getHour();
        Integer minute = local.getMinute();  // 분 추출

        User partner = userService.get(r.getPartnerId()); // 파트너 이름 가져오기
        String partnerName = partner.getUsername();
        User user = userService.get(r.getUserId()); // 고객 이름 가져오기
        String userName = user.getUsername();

        // 반려동물 정보 가져오기
        Long petId = r.getPetId();
        String petName = null;
        if (petId != null) {
            try {
                Pet pet = petService.getPetById(petId);
                petName = pet.getName();
            } catch (Exception e) {
                System.out.println("⚠️ 반려동물 정보 조회 실패: " + e.getMessage());
            }
        }

        // 파트너 ID 조회 (User ID로부터)
        Long partnerId = null;
        try {
            List<Partner> partners = partnerRepository.findByUserId(r.getPartnerId());
            if (!partners.isEmpty()) {
                partnerId = partners.get(0).getId();
            }
        } catch (Exception e) {
            System.out.println("⚠️ 파트너 ID 조회 실패: " + e.getMessage());
        }

        List<String> specialties = r.getServiceCategorical() == Reservation.ServiceCategorical.HOSPITAL
                ? splitCsv(r.getVetSpecialtyCsv())
                : splitCsv(r.getPetsitterWorkCsv());

        // 리뷰 작성 여부 확인 (완료된 예약인 경우 예약 ID로 체크)
        Boolean hasReview = false;
        if (r.getStatus() == ReservationStatus.COMPLETED) {
            hasReview = reviewRepository.existsByReservationId(r.getId());
        }

        // AI 진단 이미지 URL 목록 파싱
        List<String> resvUrls = parseResvUrls(r.getReservationImageUrl());

        // AI 진단 정보 파싱
        List<AIDiagnosisDto> aiDiagnoses = parseAIDiagnosisData(r.getAiDiagnosisData());

        return new MyReservationRes(
        r.getId(),
        r.getUserId(),
        userName,
        petId,
        petName,
        r.getServiceCategorical().name(),
        slotLabel,
        date,
        hour,
        minute,  // 분 추가
        partnerId,
        partnerName,
        specialties,
        r.getStatus().name(),
        r.getReservationContent(),
        hasReview,
        resvUrls,  // AI 진단 이미지 URL 목록
        aiDiagnoses  // AI 진단 정보 목록
);
    }

    private List<String> splitCsv(String csv) {
        return (csv == null || csv.isBlank())
                ? List.of()
                : Arrays.stream(csv.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();
    }

    /**
     * 수의사(병원)에서 받은 진료 내역만 조회
     */
    @Transactional(readOnly = true)
    public List<CompletedReservationRes> getCompletedHospitalReservations(Long userId) {
        List<Reservation> completedReservations = reservationRepository
            .findByUserIdAndStatusOrderByCreatedAtDesc(userId, ReservationStatus.COMPLETED);

        return completedReservations.stream()
            .filter(r -> r.getServiceCategorical() == ServiceCategorical.HOSPITAL)
            .map(r -> {
                Partner partner = partnerRepository.findById(r.getPartnerId()).orElse(null);
                if (partner == null) return null;
                boolean hasReview = reviewRepository.existsByPartnerIdAndUserId(r.getPartnerId(), userId);
                return CompletedReservationRes.from(r, partner.getName(),
                    partner.getPartnerType().name(), hasReview);
            })
            .filter(res -> res != null)
            .collect(Collectors.toList());
    }

    /**
     * 펫시터에게 받은 도움 내역만 조회
     */
    @Transactional(readOnly = true)
    public List<CompletedReservationRes> getCompletedSitterReservations(Long userId) {
        List<Reservation> completedReservations = reservationRepository
            .findByUserIdAndStatusOrderByCreatedAtDesc(userId, ReservationStatus.COMPLETED);

        return completedReservations.stream()
            .filter(r -> r.getServiceCategorical() == ServiceCategorical.SITTER)
            .map(r -> {
                Partner partner = partnerRepository.findById(r.getPartnerId()).orElse(null);
                if (partner == null) return null;
                boolean hasReview = reviewRepository.existsByPartnerIdAndUserId(r.getPartnerId(), userId);
                return CompletedReservationRes.from(r, partner.getName(),
                    partner.getPartnerType().name(), hasReview);
            })
            .filter(res -> res != null)
            .collect(Collectors.toList());
    }

    /**
     * 반려동물의 진료 기록 조회
     */
    @Transactional(readOnly = true)
    public List<CompletedReservationRes> getPetMedicalRecords(Long petId) {
        System.out.println("📋 [DEBUG] 진료 기록 조회 요청 - petId: " + petId);

        List<Reservation> completedReservations = reservationRepository
            .findByPetIdAndStatusOrderByCreatedAtDesc(petId, ReservationStatus.COMPLETED);

        System.out.println("📋 [DEBUG] 조회된 COMPLETED 예약 수: " + completedReservations.size());
        completedReservations.forEach(r -> {
            System.out.println("  - 예약 ID: " + r.getId() + ", petId: " + r.getPetId() +
                ", 서비스: " + r.getServiceCategorical() + ", 상태: " + r.getStatus() +
                ", 진단: " + (r.getDiagnosis() != null ? "있음" : "없음"));
        });

        List<CompletedReservationRes> result = completedReservations.stream()
            .filter(r -> r.getServiceCategorical() == ServiceCategorical.HOSPITAL)
            // 완료된 병원 예약은 모두 표시 (진료 정보가 없어도 표시)
            .map(r -> {
                System.out.println("  🔍 예약 ID " + r.getId() + "의 Partner User ID: " + r.getPartnerId() + "로 Partner 조회");
                // Reservation의 partnerId는 실제로는 Partner의 userId
                // 예약 생성 시: Partner 테이블에서 조회 → userId를 Reservation.partnerId에 저장
                // 진료 기록 조회 시: Reservation.partnerId(userId)로 Partner 테이블에서 역조회
                List<Partner> partners = partnerRepository.findByUserId(r.getPartnerId());
                if (partners.isEmpty()) {
                    System.out.println("  ❌ Partner User ID " + r.getPartnerId() + "에 해당하는 Partner를 찾을 수 없음!");
                    return null;
                }
                Partner partner = partners.get(0);
                System.out.println("  ✅ Partner 찾음: " + partner.getName());

                // 체크된 복용 키 목록 조회
                List<String> checkedKeys = medicationLogService.getCheckedMedicationKeys(r.getId());

                // 진료 기록에는 리뷰 여부가 필요없으므로 false로 설정
                return CompletedReservationRes.from(r, partner.getName(),
                    partner.getPartnerType().name(), false, checkedKeys);
            })
            .filter(res -> res != null)
            .collect(Collectors.toList());

        System.out.println("📋 [DEBUG] 최종 반환 진료 기록 수: " + result.size());
        return result;
    }

    /**
     * 리뷰 작성 가능 여부 확인
     */
    @Transactional(readOnly = true)
    public boolean canWriteReview(Long userId, Long partnerId) {
        return reservationRepository.existsCompletedReservation(
            userId, partnerId, ReservationStatus.COMPLETED);
    }

    /**
     * 파트너가 받은 예약 목록 조회
     * @param partnerId Partner 엔티티의 ID (Partner 테이블의 ID)
     */
    @Transactional(readOnly = true)
    public List<MyReservationRes> getPartnerReservations(Long partnerId) {
        System.out.println("🔍 [DEBUG] getPartnerReservations 호출 - Partner ID: " + partnerId);

        // Partner ID로부터 User ID 조회
        Partner partner = partnerRepository.findById(partnerId)
            .orElseThrow(() -> new IllegalArgumentException("PARTNER_NOT_FOUND"));

        Long partnerUserId = partner.getUserId();
        System.out.println("🔍 [DEBUG] Partner의 User ID: " + partnerUserId);

        if (partnerUserId == null) {
            throw new IllegalArgumentException("PARTNER_USER_ID_NOT_FOUND");
        }

        // User ID로 예약 조회 (reservation.partner_id는 User ID를 참조)
        List<Reservation> list = reservationRepository.findByPartnerIdOrderByCreatedAtDesc(partnerUserId);
        System.out.println("✅ [DEBUG] 조회된 예약 수: " + list.size());

        return list.stream()
                // 상담 레코드 제외 (visitDateTime이 50년 이상 미래인 것 = 더미 데이터)
                .filter(r -> r.getVisitDateTime() != null &&
                        r.getVisitDateTime().isBefore(OffsetDateTime.now().plusYears(50)))
                .map(this::toPartnerRes)
                .toList();
    }

    private MyReservationRes toPartnerRes(Reservation r) {
    var dt = r.getVisitDateTime();  // 방문 시간 사용
    // 한국 시간대(Asia/Seoul)로 변환하여 로컬 시간 유지
    var local = dt.atZoneSameInstant(java.time.ZoneId.of("Asia/Seoul")).toLocalDateTime();
    String slotLabel = local.getHour() < 12 ? "오전" : "오후";
    String date = local.format(DATE_FMT);
    Integer hour = local.getHour();
    Integer minute = local.getMinute();  // 분 추출

    // 고객 정보 가져오기
    User user = userService.get(r.getUserId());
    String userName = user.getUsername();

    // 반려동물 정보 가져오기
    Long petId = r.getPetId();
    String petName = null;
    if (petId != null) {
        try {
            Pet pet = petService.getPetById(petId);
            petName = pet.getName();
        } catch (Exception e) {
            System.out.println("⚠️ 반려동물 정보 조회 실패: " + e.getMessage());
        }
    }

    List<String> specialties = r.getServiceCategorical() == Reservation.ServiceCategorical.HOSPITAL
            ? splitCsv(r.getVetSpecialtyCsv())
            : splitCsv(r.getPetsitterWorkCsv());

    // 파트너 이름 가져오기
    String partnerName = null;
    try {
        User partnerUser = userService.get(r.getPartnerId());
        partnerName = partnerUser.getUsername();
    } catch (Exception e) {
        System.out.println("⚠️ 파트너 이름 조회 실패: " + e.getMessage());
    }

    // AI 진단 이미지 URL 목록 파싱
    List<String> resvUrls = parseResvUrls(r.getReservationImageUrl());

    // AI 진단 정보 파싱
    List<AIDiagnosisDto> aiDiagnoses = parseAIDiagnosisData(r.getAiDiagnosisData());

    return new MyReservationRes(
            r.getId(),
            r.getUserId(),
            userName,
            petId,
            petName,
            r.getServiceCategorical().name(),
            slotLabel,
            date,
            hour,
            minute,                  // 분 추가
            null,                    // partnerId - 파트너용 예약에서는 불필요
            partnerName,
            specialties,
            r.getStatus().name(),
            r.getReservationContent(),
            false,                   // hasReview - 파트너용 예약에서는 불필요
            resvUrls,                // AI 진단 이미지 URL 목록
            aiDiagnoses              // AI 진단 정보 목록
    );
}

/**
 * 예약 이미지 URL 문자열을 리스트로 파싱
 * JSON 배열 형태 또는 쉼표로 구분된 문자열을 리스트로 변환
 */
private List<String> parseResvUrls(String reservationImageUrl) {
    if (reservationImageUrl == null || reservationImageUrl.trim().isEmpty()) {
        return List.of();
    }

    String trimmed = reservationImageUrl.trim();

    // JSON 배열 형태인 경우 ("[url1", "url2"]")
    if (trimmed.startsWith("[") && trimmed.endsWith("]")) {
        try {
            // 간단한 JSON 파싱 (ObjectMapper 사용 가능하지만 간단하게 처리)
            String content = trimmed.substring(1, trimmed.length() - 1);
            if (content.trim().isEmpty()) {
                return List.of();
            }
            return java.util.Arrays.stream(content.split(","))
                    .map(String::trim)
                    .map(s -> s.replaceAll("^\"|\"$", ""))  // 앞뒤 따옴표 제거
                    .filter(s -> !s.isEmpty())
                    .toList();
        } catch (Exception e) {
            System.out.println("⚠️ JSON 배열 파싱 실패: " + e.getMessage());
            return List.of();
        }
    }

    // 쉼표로 구분된 문자열인 경우
    if (trimmed.contains(",")) {
        return java.util.Arrays.stream(trimmed.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();
    }

    // 단일 URL인 경우
    return List.of(trimmed);
}

/**
 * AI 진단 데이터 JSON 문자열을 리스트로 파싱
 */
private List<AIDiagnosisDto> parseAIDiagnosisData(String aiDiagnosisData) {
    if (aiDiagnosisData == null || aiDiagnosisData.trim().isEmpty()) {
        return List.of();
    }

    try {
        // JSON 배열을 AIDiagnosisDto 리스트로 파싱
        return objectMapper.readValue(
            aiDiagnosisData,
            new TypeReference<List<AIDiagnosisDto>>() {}
        );
    } catch (Exception e) {
        System.out.println("⚠️ AI 진단 데이터 파싱 실패: " + e.getMessage());
        return List.of();
    }
}

    /**
     * 예약 거절
     */
    public void reject(Long reservationId, Long partnerId, String reason) {
        Reservation reservation = get(reservationId);

        // Partner ID로부터 User ID 조회
        Partner partner = partnerRepository.findById(partnerId)
            .orElseThrow(() -> new IllegalArgumentException("PARTNER_NOT_FOUND"));

        Long partnerUserId = partner.getUserId();
        if (partnerUserId == null) {
            throw new IllegalArgumentException("PARTNER_USER_ID_NOT_FOUND");
        }

        // 파트너 검증 (User ID 비교)
        if (!reservation.getPartnerId().equals(partnerUserId)) {
            throw new IllegalArgumentException("PARTNER_NOT_MATCHED");
        }

        // 상태 변경
        reservation.setStatus(ReservationStatus.CANCELLED_BY_BIZ);
        reservation.setCanceledAt(LocalDateTime.now());

        // 거절 사유를 reservationContent에 추가 (또는 별도 필드 생성)
        if (reason != null && !reason.isBlank()) {
            String currentContent = reservation.getReservationContent();
            String updatedContent = currentContent != null
                ? currentContent + "\n[거절 사유] " + reason
                : "[거절 사유] " + reason;
            reservation.setReservationContent(updatedContent);
        }

        reservations.save(reservation);

        // 고객에게 알림 전송
        try {
            User user = userService.get(reservation.getUserId());
            String token = user.getFcmToken();
            if (token != null && !token.isBlank()) {
                notificationService.sendReservationRejected(token, reservationId, reason);
            }
        } catch (Exception e) {
            System.out.println("⚠️ 예약 거절 알림 전송 실패: " + e.getMessage());
            // 알림 실패는 로깅만 하고 흐름 유지
        }
    }

    /**
     * 작업 시작 (체크인)
     * CONFIRMED → CHECKED_IN
     */
    public void checkin(Long reservationId, Long partnerId) {
        Reservation reservation = get(reservationId);

        // Partner ID로부터 User ID 조회
        Partner partner = partnerRepository.findById(partnerId)
            .orElseThrow(() -> new IllegalArgumentException("PARTNER_NOT_FOUND"));

        Long partnerUserId = partner.getUserId();
        if (partnerUserId == null) {
            throw new IllegalArgumentException("PARTNER_USER_ID_NOT_FOUND");
        }

        // 파트너 검증 (User ID 비교)
        if (!reservation.getPartnerId().equals(partnerUserId)) {
            throw new IllegalArgumentException("PARTNER_NOT_MATCHED");
        }

        // 상태가 CONFIRMED인 경우만 체크인 가능
        if (reservation.getStatus() != ReservationStatus.CONFIRMED) {
            throw new IllegalArgumentException("RESERVATION_NOT_CONFIRMED");
        }

        // 상태 변경
        reservation.setStatus(ReservationStatus.CHECKED_IN);
        reservations.save(reservation);

        System.out.println("✅ 예약 체크인 완료: reservationId=" + reservationId);
    }

    /**
     * 진료/서비스 완료
     * CHECKED_IN → COMPLETED
     */
    public void complete(Long reservationId, Long partnerId, String diagnosis, String prescription,
                        String dosageSchedule, Integer dosageDays, String medicalNotes) {
        Reservation reservation = get(reservationId);

        // Partner ID로부터 User ID 조회
        Partner partner = partnerRepository.findById(partnerId)
            .orElseThrow(() -> new IllegalArgumentException("PARTNER_NOT_FOUND"));

        Long partnerUserId = partner.getUserId();
        if (partnerUserId == null) {
            throw new IllegalArgumentException("PARTNER_USER_ID_NOT_FOUND");
        }

        // 파트너 검증 (User ID 비교)
        if (!reservation.getPartnerId().equals(partnerUserId)) {
            throw new IllegalArgumentException("PARTNER_NOT_MATCHED");
        }

        // 상태가 CHECKED_IN인 경우만 완료 가능
        if (reservation.getStatus() != ReservationStatus.CHECKED_IN) {
            throw new IllegalArgumentException("RESERVATION_NOT_CHECKED_IN");
        }

        // 진료 정보 저장
        reservation.setDiagnosis(diagnosis);
        reservation.setPrescription(prescription);
        reservation.setDosageSchedule(dosageSchedule);
        reservation.setDosageDays(dosageDays);
        reservation.setMedicalNotes(medicalNotes);

        // 상태 변경
        reservation.setStatus(ReservationStatus.COMPLETED);
        reservations.save(reservation);

        // 고객에게 알림 전송
        try {
            User user = userService.get(reservation.getUserId());
            String token = user.getFcmToken();
            if (token != null && !token.isBlank()) {
                notificationService.sendReservationCompleted(token, reservationId);
            }
        } catch (Exception e) {
            System.out.println("⚠️ 예약 완료 알림 전송 실패: " + e.getMessage());
            // 알림 실패는 로깅만 하고 흐름 유지
        }
    }

    /**
     * 예약 취소 (사용자)
     */
    public void cancel(Long reservationId, Long userId) {
        Reservation reservation = get(reservationId);

        // 사용자 검증
        if (!reservation.getUserId().equals(userId)) {
            throw new IllegalArgumentException("USER_NOT_MATCHED");
        }

        // 대기중이거나 확정된 예약만 취소 가능
        if (reservation.getStatus() != ReservationStatus.WAITING &&
            reservation.getStatus() != ReservationStatus.CONFIRMED) {
            throw new IllegalArgumentException("RESERVATION_CANNOT_BE_CANCELLED");
        }

        // 상태 변경
        reservation.setStatus(ReservationStatus.CANCELLED_BY_USER);
        reservation.setCanceledAt(LocalDateTime.now());
        reservations.save(reservation);

        // 파트너에게 알림 전송
        try {
            Long partnerUserId = reservation.getPartnerId();
            if (partnerUserId != null) {
                User partnerUser = userService.get(partnerUserId);
                String token = partnerUser.getFcmToken();
                if (token != null && !token.isBlank()) {
                    notificationService.sendReservationCancelled(token, reservationId);
                }
            }
        } catch (Exception e) {
            System.out.println("⚠️ 예약 취소 알림 전송 실패: " + e.getMessage());
            // 알림 실패는 로깅만 하고 흐름 유지
        }
    }


}
