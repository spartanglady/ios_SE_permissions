package com.example.mfa.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Response DTO containing authentication challenge
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChallengeResponse {

    private String method;  // "secureEnclave" or "smsOTP"
    private String challenge;  // Base64 encoded nonce
    private String challengeId;  // UUID
    private int expiresIn;  // Seconds until expiration
}
