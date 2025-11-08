package com.example.pet.demo;

import java.nio.file.Paths;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import org.springframework.beans.factory.annotation.Value;

@Configuration
public class StaticMediaConfig implements WebMvcConfigurer {
    @Value("${app.media.base-path:uploads}")
    private String basePath;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String location = Paths.get(basePath).toAbsolutePath().toUri().toString();
        registry.addResourceHandler("/media/**")
        .addResourceLocations(location);
    }
} 
