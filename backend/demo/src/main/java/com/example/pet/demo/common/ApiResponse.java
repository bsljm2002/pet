package com.example.pet.demo.common;

public record ApiResponse<T>(
    boolean ok,
    T data,
    String error,
    String message
) {
    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, null, null);
    }
    public static <T> ApiResponse<T> error(String code, String message) {
        return new ApiResponse<>(false, null, code, message);
    }
}
