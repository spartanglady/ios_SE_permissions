package com.example.mfa.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Request DTO for initiating authentication
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AuthInitiateRequest {

    @NotBlank(message = "Username is required")
    private String username;

    @NotBlank(message = "Device ID is required")
    private String deviceId;
}
