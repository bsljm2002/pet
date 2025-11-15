package com.example.pet.demo.reservation.infra.jpa;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.pet.demo.reservation.domain.Reservation;

public interface ReservationJpaRepository extends JpaRepository<Reservation, Long> {

}
