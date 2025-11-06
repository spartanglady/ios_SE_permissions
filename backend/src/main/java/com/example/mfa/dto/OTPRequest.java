package com.example.mfa.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Request DTO for OTP operations
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class OTPRequest {

    @NotBlank(message = "Username is required")
    private String username;

    private String phoneNumber;  // Required for request, optional for verify
    private String otp;  // Required for verify, not needed for request
}
