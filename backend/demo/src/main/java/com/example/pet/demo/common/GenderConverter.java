package com.example.pet.demo.common;

import com.example.pet.demo.users.domain.User;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

/**
 * User Gender Enum 컨버터
 * 데이터베이스에 저장된 소문자 값(male, female)을
 * Java Enum(MALE, FEMALE)으로 자동 변환
 */
@Converter(autoApply = false)
public class GenderConverter implements AttributeConverter<User.Gender, String> {

    @Override
    public String convertToDatabaseColumn(User.Gender attribute) {
        if (attribute == null) {
            return null;
        }
        // Java Enum -> DB: 대문자로 저장 (MALE, FEMALE)
        return attribute.name();
    }

    @Override
    public User.Gender convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.trim().isEmpty()) {
            return null;
        }
        // DB -> Java Enum: 대소문자 무시하고 변환
        try {
            return User.Gender.valueOf(dbData.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException(
                "Invalid gender value in database: " + dbData +
                ". Expected: MALE or FEMALE (case-insensitive)", e);
        }
    }
}
