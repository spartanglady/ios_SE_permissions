package com.example.mfa.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Request DTO for device enrollment
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class EnrollmentRequest {

    @NotBlank(message = "Username is required")
    private String username;

    private String phoneNumber;

    private String publicKey;  // Base64 encoded, required for secureEnclave method

    @NotBlank(message = "Method is required")
    private String method;  // "secureEnclave" or "smsOTP"

    @NotBlank(message = "Device ID is required")
    private String deviceId;

    private String deviceModel;
}
