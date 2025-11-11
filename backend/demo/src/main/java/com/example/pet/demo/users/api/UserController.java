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
import com.example.pet.demo.users.api.dto.UserLoginReq;   
import com.example.pet.demo.users.api.dto.UserLoginRes;
import com.example.pet.demo.users.app.UserService;
import com.example.pet.demo.users.domain.User;
import com.example.pet.demo.users.domain.User.UserType;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;


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
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<UserLoginRes>> login(
        @Valid @RequestBody UserLoginReq req
        ) {
                //1. 로그인 처리(이메일 로그인)
                User user = userService.login(req.email(), req.p        assword());

                //2. User 엔티티를 DTO로 변환
                UserLoginRes response = UserLoginRes.from(user);

                //3. 200은 성공 ,400은 실패
                return ResponseEntity.ok(ApiResponse.ok(response));
        
        
    }
    

    @GetMapping("/check-email")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> checkEmailDuplicate(
            @RequestParam("email") String email
    ) {
        boolean exists = userService.checkEmailExists(email);
        return ResponseEntity
                .ok(ApiResponse.ok(Map.of("exists", exists)));
    }

    @GetMapping("/partners")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPartners(@RequestParam("user_type") String userType) {
        UserType type;
        try {
                type = UserType.valueOf(userType.toUpperCase());
        } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("INVALID_USER_TYPE");
        }
        if (type != UserType.HOSPITAL && type != UserType.SITTER) {
                throw new IllegalArgumentException("UNSUPPORTED_USER_TYPE");
        }

        return 
    }
    

}
