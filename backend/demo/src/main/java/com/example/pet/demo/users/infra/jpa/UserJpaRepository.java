package com.example.pet.demo.users.infra.jpa;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import com.example.pet.demo.users.domain.User;

public interface UserJpaRepository extends JpaRepository<User, Long> {
    boolean existsByEmail(String email);
    boolean existsByUsername(String username);
    Optional<User> findByEmail(String email);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("update User u set u.lastLoginAt = CURRENT_TIMESTAMP where u.id = :id")
    int touchLastLogin(Long id);
}