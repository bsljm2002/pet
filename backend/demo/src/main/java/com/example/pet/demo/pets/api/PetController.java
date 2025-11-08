package com.example.pet.demo.pets.api;

import java.net.URI;
import java.util.List;
import java.util.Map;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.util.UriComponentsBuilder;

import com.example.pet.demo.common.ApiResponse;
import com.example.pet.demo.media.FileStorageService;
import com.example.pet.demo.pets.api.dto.PetCreateReq;
import com.example.pet.demo.pets.app.PetService;
import com.example.pet.demo.pets.domain.Pet;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

@RestController
@RequestMapping("/api/v1/pets")
@RequiredArgsConstructor
@Validated
public class PetController {
    private final PetService petService;
    private final FileStorageService fileStorageService;

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Long>>> createPet(
            @Valid @RequestBody PetCreateReq req,
            UriComponentsBuilder uriBuilder) {
        Long id = petService.create(req);
        URI location = uriBuilder
                .path("/api/v1/pets/{id}")
                .buildAndExpand(id)
                .toUri();
        return ResponseEntity
                .created(location)
                .body(ApiResponse.ok(Map.of("id", id)));
    }

    @PostMapping(value = "/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<Map<String, String>>> uploadPetImage(
            @RequestParam("ownerId") Long ownerId,
            @RequestParam("file") MultipartFile file) throws Exception {
        String url = fileStorageService.savePetImage(ownerId, file);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("imageUrl", url)));
    }


    @GetMapping
    public ResponseEntity<ApiResponse<List<Pet>>> getPetsByOwner(@RequestParam("ownerId") Long ownerId) {
        return ResponseEntity.ok(
                ApiResponse.ok(petService.getPetsByOwner(ownerId)));
    }
}
