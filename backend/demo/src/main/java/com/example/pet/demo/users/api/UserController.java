package com.example.pet.demo.users.api;

import java.net.URI;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.util.UriComponentsBuilder;

import com.example.pet.demo.common.ApiResponse;
import com.example.pet.demo.users.api.dto.UserSignupReq;
import com.example.pet.demo.users.app.UserService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;


@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Validated
public class UserController {
    private final UserService userService;

    @PostMapping
     public ResponseEntity<ApiResponse<Map<String, Long>>> signup(
            @Valid @RequestBody UserSignupReq req,
            UriComponentsBuilder uriBuilder
    ) {
        Long id = userService.signup(req);
        URI location = uriBuilder
                .path("/api/v1/users/{id}")
                .buildAndExpand(id)
                .toUri();
        return ResponseEntity
                .created(location)
                .body(ApiResponse.ok(Map.of("id", id)));
    }
    
}
