package com.example.pet.demo.reservation.app;

import java.util.Collection;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.pet.demo.reservation.api.dto.ReservationCreateReq;
import com.example.pet.demo.reservation.domain.Reservation;
import com.example.pet.demo.reservation.domain.Reservation.ReservationStatus;
import com.example.pet.demo.reservation.domain.Reservation.ServiceCategorical;
import com.example.pet.demo.reservation.domain.port.ReservationPersistencePort;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional
public class ReservationService {
    private final ReservationPersistencePort reservations;

    public Long create(ReservationCreateReq req) {
        Reservation reservation = Reservation.builder()
            .userId(req.userId())
            .partnerId(req.partnerId())
            .serviceCategorical(ServiceCategorical.valueOf(req.userType().name()))
            .userType(req.userType())
            .status(ReservationStatus.WAITING)
            .createdAt(req.createdAt())
            .reservationImageUrl(req.reservationImageUrl())
            .reservationContent(req.reservationContent())
            .petId(req.petId())
            .vetSpecialtyCsv(toCsv(req.vetSpecialties()))
            .petsitterWorkCsv(toCsv(req.petsitterWorks()))
            .build();

        return reservations.save(reservation).getId();
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
}
