package com.example.pet.demo.users.infra.jpa;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.pet.demo.users.domain.User;
import com.example.pet.demo.users.domain.User.UserType;

public interface UserJpaRepository extends JpaRepository<User, Long> {
    boolean existsByEmail(String email);
    boolean existsByUsername(String username);
    Optional<User> findByEmail(String email);
    
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("update User u set u.lastLoginAt = CURRENT_TIMESTAMP where u.id = :id")
    int touchLastLogin(Long id);

    List<User> findByUserType(UserType type);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("update User u set u.profileUrl = :url where u.id = :id")
    int updateProfileUrl(@Param("id")Long id, @Param("url") String url);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("update User u set u.fcmToken = :token where u.id = :id")
    int updateFcmToken(Long id, String token);
}