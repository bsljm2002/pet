package com.example.pet.demo.users.domain.port;

import java.util.Optional;

import com.example.pet.demo.users.domain.User;

public interface UserPersistencePort {
    boolean existsByEmail(String email);
    Optional<User> findByEmail(String email);
    User save(User user);
    void touchLastLogin(Long id); // 선택
}
