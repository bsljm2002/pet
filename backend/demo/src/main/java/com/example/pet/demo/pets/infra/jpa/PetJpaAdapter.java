package com.example.pet.demo.pets.infra.jpa;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import com.example.pet.demo.pets.domain.Pet;
import com.example.pet.demo.pets.domain.port.PetPersistencePort;
import com.example.pet.demo.users.domain.User;

import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;

@Repository
@RequiredArgsConstructor
public class PetJpaAdapter implements PetPersistencePort {
    private final PetJpaRepository jpa;
    private final EntityManager em;

    @Override
    public Long create(Long userId,
            String species,
            LocalDate birthdate,
            BigDecimal weight,
            String abitTypeCode,
            String imageUrl,
            String name,
            String gender,
            String speciesDetail) {

        User ownerRef = em.getReference(User.class, userId);

        Pet pet = Pet.builder()
                .owner(ownerRef)
                .species(Pet.Species.valueOf(species))
                .birthdate(birthdate)
                .weight(weight)
                .abitTypeCode(Pet.AbitTypeCode.valueOf(abitTypeCode))
                .imageUrl(imageUrl)
                .name(name)
                .gender(Pet.Gender.valueOf(gender))
                .speciesDetail(speciesDetail)
                .build();

        return jpa.save(pet).getId();
    }

    @Override
    @Transactional(readOnly = true)
    public List<Pet> findByOwnerId(Long ownerId){
        return jpa.findByOwner_Id(ownerId);
    }
    @Override
    @Transactional(readOnly = true)
    public Optional<Pet> findById(Long id) {
        return jpa.findById(id);
}
    

}
