package com.example.pet.demo.users.api.dto;

import com.example.pet.demo.users.domain.User;

public record UserLoginRes(
    Long id,
    String username,
    String nickname,
    String email,
    String gender,
    String userType
) {
    // User 엔티티를 UserLoginRes로 변환하는 정적 팩토리 메서드
    public static UserLoginRes from(User user){
        return new UserLoginRes(
            user.getId(),
            user.getUsername(),
            user.getNickname(),
            user.getEmail(),
            user.getGender(),
            user.getUserType().name()
        );
    }
    
}
