package com.example.mfa.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Response DTO for authentication operations
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {

    private boolean success;
    private String token;
    private String message;

    public AuthResponse(boolean success, String message) {
        this.success = success;
        this.message = message;
    }
}
