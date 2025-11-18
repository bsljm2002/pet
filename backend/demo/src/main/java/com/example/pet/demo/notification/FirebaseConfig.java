package com.example.pet.demo.notification;

import java.io.InputStream;

import org.springframework.boot.autoconfigure.condition.ConditionalOnResource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;

@Configuration
public class FirebaseConfig {
    @Bean
    @ConditionalOnResource(resources = "classpath:firebase/dogfootcatfoot-1f17f-firebase-adminsdk-fbsvc-a66a1ddefe.json")
    public FirebaseApp firebaseApp() throws Exception {
        try (InputStream in = getClass().getClassLoader()
                .getResourceAsStream("firebase/dogfootcatfoot-1f17f-firebase-adminsdk-fbsvc-a66a1ddefe.json")) {
            if (in == null) {
                System.out.println("⚠️ Firebase 인증 파일을 찾을 수 없습니다. Firebase 기능이 비활성화됩니다.");
                return null;
            }
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(in))
                    .build();
            System.out.println("✅ Firebase 초기화 완료");
            return FirebaseApp.initializeApp(options);
        }
    }
}
