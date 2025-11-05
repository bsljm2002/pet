package com.example.pet.demo.pets.domain.port;

import java.math.BigDecimal;
import java.time.LocalDate;

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
}
