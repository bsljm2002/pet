package com.example.pet.demo.notification;

import java.io.InputStream;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;

@Configuration
public class FirebaseConfig {
    @Bean
    public FirebaseApp firebaseApp() throws Exception {
        InputStream in = getClass().getClassLoader()
                .getResourceAsStream("firebase-service-account.json");
        
        if (in == null) {
            System.out.println("⚠️ firebase-service-account.json not found. Firebase notifications will be disabled.");
            return null;
        }
        
        try {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(in))
                    .build();
            return FirebaseApp.initializeApp(options);
        } finally {
            in.close();
        }
    }
}
