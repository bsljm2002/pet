package com.example.pet.demo.users.api;

import java.net.URI;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;
import org.springframework.web.util.UriComponentsBuilder;

import com.example.pet.demo.common.ApiResponse;
import com.example.pet.demo.media.FileStorageService;
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
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Validated
public class UserController {

        private final UserService userService;
        private final FileStorageService fileStorageService;

        @PostMapping
        public ResponseEntity<ApiResponse<Map<String, Long>>> signup(
                        @Valid @RequestBody UserSignupReq req,
                        UriComponentsBuilder uriBuilder) {
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
                        @Valid @RequestBody UserLoginReq req) {
                // 1. 로그인 처리(이메일 로그인)
                User user = userService.login(req.email(), req.password());

                // 2. User 엔티티를 DTO로 변환
                UserLoginRes response = UserLoginRes.from(user);

                // 3. 200은 성공 ,400은 실패
                return ResponseEntity.ok(ApiResponse.ok(response));

        }

        @GetMapping("/check-email")
        public ResponseEntity<ApiResponse<Map<String, Boolean>>> checkEmailDuplicate(
                        @RequestParam("email") String email) {
                boolean exists = userService.checkEmailExists(email);
                return ResponseEntity
                                .ok(ApiResponse.ok(Map.of("exists", exists)));
        }

        @GetMapping("/partners")
        public ResponseEntity<ApiResponse<Map<String, Object>>> getPartners(
                        @RequestParam("user_type") String userType) {
                UserType type;
                try {
                        type = UserType.valueOf(userType.toUpperCase());
                } catch (IllegalArgumentException e) {
                        throw new IllegalArgumentException("INVALID_USER_TYPE");
                }
                if (type != UserType.HOSPITAL && type != UserType.SITTER) {
                        throw new IllegalArgumentException("UNSUPPORTED_USER_TYPE");
                }

                List<User> users = userService.findByUserType(type);
                List<Map<String, Object>> result = users.stream().map(u -> {
                        Map<String, Object> row = new LinkedHashMap<>();
                        row.put("id", u.getId());
                        row.put("username", u.getUsername());

                        if (type == UserType.HOSPITAL) {
                                row.put("vet_specialty", u.getVetSpecialty() == null
                                                ? List.of()
                                                : List.of(u.getVetSpecialty().name()));
                                row.put("ca_categorical", u.getCaCategorical() == null
                                                ? null
                                                : u.getCaCategorical().name());
                                row.put("image_url", u.getProfileUrl());
                        } else {
                                row.put("petsitter", u.getPetsitterWork() == null
                                                ? List.of()
                                                : List.of(u.getPetsitterWork().name()));
                                row.put("image_url", u.getProfileUrl());
                        }

                        List<String> days = (u.getWorkingDays() == null || u.getWorkingDays().isBlank())
                                        ? List.of()
                                        : Arrays.stream(u.getWorkingDays().split(","))
                                                        .map(String::trim)
                                                        .filter(s -> !s.isEmpty())
                                                        .toList();
                        Map<String, Object> schedule = new LinkedHashMap<>();
                        schedule.put("working_days", days);
                        schedule.put("working_start_hours", u.getWorkingStartHours());
                        schedule.put("working_end_hours", u.getWorkingEndHours());
                        row.put("working_schedule", schedule);

                        row.put("image_url", u.getProfileUrl());
                        return row;
                }).toList();
                Map<String, Object> body = new LinkedHashMap<>();
                body.put("user_type", type.name());
                body.put("total", result.size());
                body.put("result", result);

                return ResponseEntity.ok(ApiResponse.ok(body));
        }

        @PostMapping(value = "/{id}/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
        public ResponseEntity<ApiResponse<Map<String, String>>> uploadUserImage(@PathVariable("id") Long userId,
                        @RequestParam("file") MultipartFile file) throws Exception {
                String relative = fileStorageService.saveUserImage(userId, file);
                String imageUrl = ServletUriComponentsBuilder
                        .fromCurrentContextPath()
                        .path(relative)
                        .toUriString();
                userService.updateProfileUrl(userId, imageUrl); // 여기서 DB 반영
                return ResponseEntity.ok(ApiResponse.ok(Map.of("imageUrl", imageUrl)));
        }

        @PatchMapping("/{id}/fcm-token")
        public ResponseEntity<ApiResponse<Map<String, Boolean>>> updateFcmToken(
                @PathVariable("id") Long userId,
                @RequestBody Map<String, String> body
        ) {
        String token = body.get("token");
        if (token == null || token.isBlank()) {
                throw new IllegalArgumentException("FCM_TOKEN_REQUIRED");
        }
        userService.updateFcmToken(userId, token);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("updated", true)));
        }

}
