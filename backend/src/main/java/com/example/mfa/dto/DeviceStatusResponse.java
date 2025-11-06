package com.example.mfa.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * Response DTO for device status
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DeviceStatusResponse {

    private String deviceId;
    private boolean enrolled;
    private String method;
    private boolean hasPublicKey;
    private String phoneNumber;
    private String enrolledAt;
    private String lastUsed;
}
