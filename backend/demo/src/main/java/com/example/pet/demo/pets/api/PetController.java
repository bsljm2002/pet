package com.example.pet.demo.pets.api;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.pet.demo.common.ApiResponse;
import com.example.pet.demo.pets.app.PetService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;


@RestController
@RequestMapping("/api/v1/pet")
@Validated
public class PetController {
    // private final PetService petService;

    // @PostMapping
    // public ResponseEntity <ApiResponse<Map<String, Long>>> createPet {
    //     //TODO: process POST request
        
    //     return entity;
    // }
    
}
