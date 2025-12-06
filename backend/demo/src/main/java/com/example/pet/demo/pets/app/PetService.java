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
        String species = req.species() != null ? req.species().toUpperCase() : null;
        String name = req.name() != null ? req.name().trim() : null;
        String gender = req.gender() != null ? req.gender().toUpperCase() : null;
        String speciesDetail = req.speciesDetail() == null ? null : req.speciesDetail().trim();
        String disease = req.disease() == null ? null : req.disease().trim();

        // Use default placeholder if imageUrl is null (for database NOT NULL constraint)
        String imageUrl = req.imageUrl() != null ? req.imageUrl() : "/media/default/pet-placeholder.png";

        return pets.create(
                req.userId(),
                species,
                req.birthdate(),
                req.weight(),
                imageUrl,
                name,
                gender,
                speciesDetail,
                disease);
    }

    @Transactional(readOnly = true)
    public List<Pet> getPetsByOwner(Long ownerId) {
        return pets.findByOwnerId(ownerId);
    }
    @Transactional(readOnly = true)
    public Pet getPetById(Long id) {
        return pets.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Pet not found with id:" + id));
    }

    public void update(Long id, PetCreateReq req) {
        // 펫이 존재하는지 확인
        Pet pet = pets.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Pet not found with id: " + id));

        // Use existing values if not provided (PATCH behavior)
        String species = req.species() != null ? req.species().toUpperCase() : pet.getSpecies().name();
        String name = req.name() != null ? req.name().trim() : pet.getName();
        String gender = req.gender() != null ? req.gender().toUpperCase() : pet.getGender().name();
        String speciesDetail = req.speciesDetail() != null ? req.speciesDetail().trim() : pet.getSpeciesDetail();
        String disease = req.disease() != null ? req.disease().trim() : pet.getDisease();
        String imageUrl = req.imageUrl() != null ? req.imageUrl() : pet.getImageUrl();

        java.time.LocalDate birthdate = req.birthdate() != null ? req.birthdate() : pet.getBirthdate();
        java.math.BigDecimal weight = req.weight() != null ? req.weight() : pet.getWeight();

        // Update pet
        pets.update(
                id,
                species,
                birthdate,
                weight,
                imageUrl,
                name,
                gender,
                speciesDetail,
                disease);
    }

    public void delete(Long id) {
        try {
            // 펫이 존재하는지 확인
            Pet pet = pets.findById(id)
                    .orElseThrow(() -> new IllegalArgumentException("Pet not found with id: " + id));

            System.out.println("삭제 대상 Pet: ID=" + pet.getId() + ", Name=" + pet.getName());

            // 삭제 수행
            pets.deleteById(id);

            System.out.println("Pet 삭제 완료: ID=" + id);
        } catch (Exception e) {
            System.err.println("Pet 삭제 중 오류 발생: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Pet 삭제 실패: " + e.getMessage(), e);
        }
    }

}
