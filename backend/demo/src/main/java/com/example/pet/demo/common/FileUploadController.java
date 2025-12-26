package com.example.pet.demo.common;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/v1/files")
@RequiredArgsConstructor
public class FileUploadController {

    @Value("${file.upload.dir:uploads}")
    private String uploadDir;

    @Value("${file.upload.base-url:http://localhost:8080/uploads}")
    private String baseUrl;

    /**
     * 이미지 업로드
     * POST /api/v1/files/upload
     */
    @PostMapping("/upload")
    public ResponseEntity<ApiResponse<FileUploadResponse>> uploadFile(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "type", defaultValue = "disease") String type) {

        if (file.isEmpty()) {
            throw new IllegalArgumentException("File is empty");
        }

        try {
            // 업로드 디렉토리 생성
            Path uploadPath = Paths.get(uploadDir, type);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            // 고유한 파일명 생성
            String originalFilename = file.getOriginalFilename();
            String extension = originalFilename != null && originalFilename.contains(".")
                    ? originalFilename.substring(originalFilename.lastIndexOf("."))
                    : "";
            String uniqueFilename = UUID.randomUUID().toString() + extension;

            // 파일 저장
            Path filePath = uploadPath.resolve(uniqueFilename);
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

            // URL 생성
            String fileUrl = baseUrl + "/" + type + "/" + uniqueFilename;

            FileUploadResponse response = new FileUploadResponse(fileUrl, uniqueFilename);
            return ResponseEntity.ok(ApiResponse.ok(response));

        } catch (IOException e) {
            throw new RuntimeException("Failed to upload file", e);
        }
    }

    public record FileUploadResponse(
        String url,
        String filename
    ) {}
}
