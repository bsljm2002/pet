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
import com.example.pet.demo.reservation.api.dto.CompletedReservationRes;
import com.example.pet.demo.reservation.api.dto.MyReservationRes;
import com.example.pet.demo.reservation.api.dto.ReservationCreateReq;
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
            .build();

        return reservations.save(reservation).getId();
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
        hasReview
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
            false                    // hasReview - 파트너용 예약에서는 불필요
    );
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
     * 진료/서비스 완료
     */
    public void complete(Long reservationId, Long partnerId) {
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

        // 상태가 CONFIRMED인 경우만 완료 가능
        if (reservation.getStatus() != ReservationStatus.CONFIRMED) {
            throw new IllegalArgumentException("RESERVATION_NOT_CONFIRMED");
        }

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
