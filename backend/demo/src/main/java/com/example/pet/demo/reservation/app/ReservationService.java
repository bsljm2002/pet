package com.example.pet.demo.reservation.app;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.pet.demo.notification.NotificationService;
import com.example.pet.demo.reservation.api.dto.MyReservationRes;
import com.example.pet.demo.reservation.api.dto.ReservationCreateReq;
import com.example.pet.demo.reservation.domain.Reservation;
import com.example.pet.demo.reservation.domain.Reservation.ReservationStatus;
import com.example.pet.demo.reservation.domain.Reservation.ServiceCategorical;
import com.example.pet.demo.reservation.domain.port.ReservationPersistencePort;
import com.example.pet.demo.users.app.UserService;
import com.example.pet.demo.users.domain.User;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional
public class ReservationService {
    private final ReservationPersistencePort reservations;
    private final NotificationService notificationService;
    private final UserService userService;
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy.MM.dd");

    public Long create(ReservationCreateReq req) {
        String imageCsv = toCsv(req.reservationImageUrls());
        Reservation reservation = Reservation.builder()
            .userId(req.userId())
            .partnerId(req.partnerId())
            .serviceCategorical(ServiceCategorical.valueOf(req.userType().name()))
            .userType(req.userType())
            .status(ReservationStatus.WAITING)
            .createdAt(req.createdAt())
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
        // ... 파트너 검증/상태 변경 ...
        reservations.save(reservation);

        try {
            User user = userService.get(reservation.getUserId()); // get 메서드는 직접 추가
            String token = user.getFcmToken();
            if (token != null && !token.isBlank()) {
                notificationService.sendReservationAccepted(token, reservationId);
            }
        } catch (Exception e) {
            // 알림 실패는 로깅만 하고 흐름 유지
        }
    }

    @Transactional(readOnly = true)
    public List<MyReservationRes> getMyReservations(Long userId, String serviceType) {
        List<Reservation> list = reservations.findByUserId(userId);
        return list.stream()
                .filter(r -> serviceType == null
                        || r.getServiceCategorical().name().equalsIgnoreCase(serviceType))
                .map(this::toRes)
                .toList();
    }

    private MyReservationRes toRes(Reservation r) {
        var dt = r.getCreatedAt();                 // OffsetDateTime
        var local = dt.toLocalDateTime();          // LocalDateTime으로 변환
        String slotLabel = local.getHour() < 12 ? "오전 진료" : "오후 진료";
        String date = local.format(DATE_FMT);
        Integer hour = local.getHour();
        
        User partner = userService.get(r.getPartnerId()); // 파트너 이름 가져오기
        String partnerName = partner.getUsername();

        List<String> specialties = r.getServiceCategorical() == Reservation.ServiceCategorical.HOSPITAL
                ? splitCsv(r.getVetSpecialtyCsv())
                : splitCsv(r.getPetsitterWorkCsv());

        return new MyReservationRes(
                r.getId(),
                r.getServiceCategorical().name(),
                slotLabel,
                date,
                hour,
                partnerName,
                specialties,
                r.getStatus().name()
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

}
