package com.example.pet.demo.reservation.infra.jpa;

import java.util.Optional;

import org.springframework.stereotype.Repository;

import com.example.pet.demo.reservation.domain.Reservation;
import com.example.pet.demo.reservation.domain.port.ReservationPersistencePort;

import lombok.RequiredArgsConstructor;

@Repository
@RequiredArgsConstructor
public class ReservationJpaAdapter implements ReservationPersistencePort {

    private final ReservationJpaRepository reservationJpaRepository;

    @Override
    public Reservation save(Reservation reservation) {
        return reservationJpaRepository.save(reservation);
    }

    @Override
    public Optional<Reservation> findById(Long id) {
        return reservationJpaRepository.findById(id);
    }
}
