package com.example.pet.demo.reservation.domain.port;

import java.util.List;
import java.util.Optional;

import com.example.pet.demo.reservation.domain.Reservation;

public interface ReservationPersistencePort {
    Reservation save(Reservation reservation);
    Optional<Reservation> findById(Long id);
    List<Reservation> findByUserId(Long userId);
}
