package com.example.pet.demo.pets.infra.jpa;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.pet.demo.pets.domain.Pet;

public interface PetJpaRepository extends JpaRepository<Pet, Long> {
    boolean existsByOwner_IdAndName(Long ownerId, String name);
    List<Pet> findByOwner_Id(Long ownerId);
}
