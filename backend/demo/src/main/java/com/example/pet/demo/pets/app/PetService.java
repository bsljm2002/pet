package com.example.pet.demo.pets.app;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.pet.demo.pets.api.dto.PetCreateReq;
import com.example.pet.demo.pets.domain.Pet;
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
        String gender = req.gender().toUpperCase();
        String speciesDetail = req.speciesDetail() == null ? null : req.speciesDetail().trim();


        return pets.create(
                req.userId(),
                species,
                req.birthdate(),
                req.weight(),
                abit,
                req.imageUrl(),
                name,
                gender,
                speciesDetail);
    }

    @Transactional(readOnly = true)
    public List<Pet> getPetsByOwner(Long ownerId) {
        return pets.findByOwnerId(ownerId);
    }
}
