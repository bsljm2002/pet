package com.example.pet.demo.media;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Set;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class FileStorageService {
    @Value("${app.media.base-path:uploads}")
    private String basePath;

    private static final Set<String> ALLOWED = Set.of("jpg", "jpeg", "png");

    public enum ImageCategory {
        PETS("pets"),
        USERS("users"),
        ARTICLE("article"),
        DISEASES("diseases");

        private final String dir;

        ImageCategory(String dir) {
            this.dir = dir;
        }

        public String dir() {
            return dir;
        }
    }

    public String savePetImage(Long ownerId, MultipartFile file) throws IOException {
        return save(ImageCategory.PETS, ownerId, file);
    }

    public String saveUserImage(Long ownerId, MultipartFile file) throws IOException {
        return save(ImageCategory.USERS, ownerId, file);
    }

    public String saveArticleImage(Long ownerId, MultipartFile file) throws IOException {
        return save(ImageCategory.ARTICLE, ownerId, file);
    }

    public String saveDiseaseImage(Long ownerId, MultipartFile file) throws IOException {
        return save(ImageCategory.DISEASES, ownerId, file);
    }

    public String save(ImageCategory category, Long refId, MultipartFile file) throws IOException {
        if (refId == null)
            throw new IllegalArgumentException("refId is required");
        if (file == null || file.isEmpty())
            throw new IllegalArgumentException("file is empty");

        String ext = getExt(file.getOriginalFilename()).toLowerCase();
        if (!ALLOWED.contains(ext)) {
            throw new IllegalArgumentException("unsupport file type: " + ext);
        }

        String filename = UUID.randomUUID() + "." + ext;
        Path dir = Paths.get(basePath, category.dir(), String.valueOf(refId));
        Files.createDirectories(dir);

        Path dest = dir.resolve(filename);
        file.transferTo(dest.toFile());

        return "/media/" + category.dir() + "/" + refId + "/" + filename;
    }

    public boolean deleteByUrl(String url) {
        if (url == null || !url.startsWith("/media/")) return false;
        String relative = url.substring("/media/".length()); // e.g. pets/1/uuid.jpg
        Path path = Paths.get(basePath, relative.replace("/", File.separator));
        try {
            return Files.deleteIfExists(path);
        } catch (IOException e) {
            return false;
        }
    }

    private String getExt(String name) {
        if (name == null) return "";
        int i = name.lastIndexOf(".");
        return (i == -1) ? "" : name.substring(i + 1);
    }

}
