package com.example.pet.demo.users.infra.jpa;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Repository;

import com.example.pet.demo.users.domain.User;
import com.example.pet.demo.users.domain.User.UserType;
import com.example.pet.demo.users.domain.port.UserPersistencePort;

import lombok.RequiredArgsConstructor;

@Repository
@RequiredArgsConstructor
public class UserJpaAdapter implements UserPersistencePort  {
    private final UserJpaRepository jpa;

    @Override public boolean existsByEmail(String email) { return jpa.existsByEmail(email); }
    @Override public Optional<User> findByEmail(String email) { return jpa.findByEmail(email); }
    @Override public Optional<User> findById(Long id) { return jpa.findById(id); } 
    @Override public User save(User user) { return jpa.save(user); }
    @Override public void touchLastLogin(Long id) { jpa.touchLastLogin(id); }
    @Override public List<User> findByUserType(UserType type) { return jpa.findByUserType(type); }
    @Override public void updateProfileUrl(Long id, String url) {jpa.updateProfileUrl(id, url);}
    @Override public void updateFcmToken(Long id, String token) { jpa.updateFcmToken(id, token); }
}
