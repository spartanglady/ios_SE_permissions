package com.example.mfa.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Response DTO for enrollment operations
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class EnrollmentResponse {

    private boolean success;
    private String deviceId;
    private String method;
    private String message;

    public EnrollmentResponse(boolean success, String message) {
        this.success = success;
        this.message = message;
    }
}
