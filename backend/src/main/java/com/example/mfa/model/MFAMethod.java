package com.example.mfa.model;

/**
 * Enum representing the MFA authentication method
 */
public enum MFAMethod {
    SECURE_ENCLAVE,  // Biometric or passcode using Secure Enclave
    SMS_OTP          // SMS-based One-Time Password
}
