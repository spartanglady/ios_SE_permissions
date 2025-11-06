package com.example.mfa.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Request DTO for verifying signature
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class VerifySignatureRequest {

    @NotBlank(message = "Username is required")
    private String username;

    @NotBlank(message = "Device ID is required")
    private String deviceId;

    @NotBlank(message = "Challenge ID is required")
    private String challengeId;

    @NotBlank(message = "Signature is required")
    private String signature;  // Base64 encoded
}
