package com.example.pet.demo.notification;

import java.io.InputStream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;

@Configuration
public class FirebaseConfig {
    
    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);
    
    @Bean
    public FirebaseApp firebaseApp() throws Exception {
        InputStream in = getClass().getClassLoader()
                .getResourceAsStream("firebase-service-account.json");
        
        if (in == null) {
            log.warn("⚠️ firebase-service-account.json 파일이 없습니다. Firebase 푸시 알림 기능이 비활성화됩니다.");
            return null;
        }
        
        try {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(in))
                    .build();
            log.info("✅ Firebase 초기화 성공");
            return FirebaseApp.initializeApp(options);
        } finally {
            in.close();
        }
    }
}
