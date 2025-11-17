package com.example.pet.demo.users.domain.port;

import java.util.List;
import java.util.Optional;

import com.example.pet.demo.users.domain.User;
import com.example.pet.demo.users.domain.User.UserType;

public interface UserPersistencePort {
    boolean existsByEmail(String email);
    Optional<User> findByEmail(String email);
    Optional<User> findById(Long id); 
    User save(User user);
    void touchLastLogin(Long id); // 선택
    List<User> findByUserType(UserType type);
    void updateProfileUrl(Long id, String url);
    void updateFcmToken(Long id, String token); 
}
