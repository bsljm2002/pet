package com.example.pet.demo.pets.app;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.pet.demo.pets.api.dto.PetCreateReq;
import com.example.pet.demo.pets.domain.port.PetPersistencePort;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional
public class PetService {
    private final PetPersistencePort pets;

    public Long create(PetCreateReq req) {
        // Normalize simple fields
        String species = req.species().toUpperCase();
        String name = req.name().trim();
        String abit = req.abitTypeCode().toUpperCase();

        return pets.create(
                req.userId(),
                species,
                req.birthdate(),
                req.weight(),
                abit,
                req.imageUrl(),
                name);
    }
}
