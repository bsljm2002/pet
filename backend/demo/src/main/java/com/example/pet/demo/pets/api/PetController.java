package com.example.pet.demo.pets.api;

import java.net.URI;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.util.UriComponentsBuilder;

import com.example.pet.demo.common.ApiResponse;
import com.example.pet.demo.pets.api.dto.PetCreateReq;
import com.example.pet.demo.pets.app.PetService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;


@RestController
@RequestMapping("/api/v1/pets")
@RequiredArgsConstructor
@Validated
public class PetController {
    private final PetService petService;

    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Long>>> createPet(
        @Valid @RequestBody PetCreateReq req,
        UriComponentsBuilder uriBuilder 
    ) {
        Long id = petService.create(req);
        URI location = uriBuilder
                .path("/api/v1/pets/{id}")
                .buildAndExpand(id)
                .toUri();
        return ResponseEntity
                .created(location)
                .body(ApiResponse.ok(Map.of("id", id)));
    }
    
}
