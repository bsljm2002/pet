package com.example.pet.demo.pets.domain.port;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import com.example.pet.demo.pets.domain.Pet;

public interface PetPersistencePort {
    Long create(
            Long userId,
            String species,
            LocalDate birthdate,
            BigDecimal weight,
            String abitTypeCode,
            String imageUrl,
            String name
    );
    List<Pet> findByOwnerId(Long ownerId);
}
