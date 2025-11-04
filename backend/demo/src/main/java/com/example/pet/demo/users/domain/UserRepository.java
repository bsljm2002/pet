package com.example.pet.demo.users.domain;

import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long>{
    boolean existsByEmail(String email);
}
