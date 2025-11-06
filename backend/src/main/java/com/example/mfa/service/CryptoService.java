package com.example.mfa.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.security.*;
import java.security.spec.X509EncodedKeySpec;

/**
 * Service for cryptographic operations:
 * - Signature verification (ECDSA with SHA-256)
 * - Challenge generation (secure random nonce)
 * - OTP generation (6-digit code)
 */
@Service
public class CryptoService {

    private static final Logger log = LoggerFactory.getLogger(CryptoService.class);
    private final SecureRandom secureRandom = new SecureRandom();

    /**
     * Verify ECDSA signature using the provided public key
     *
     * @param publicKeyBytes The public key in X.509 format
     * @param data          The data that was signed
     * @param signature     The signature to verify
     * @return true if signature is valid, false otherwise
     */
    public boolean verifySignature(byte[] publicKeyBytes, byte[] data, byte[] signature) {
        try {
            // Reconstruct EC public key from raw bytes
            KeyFactory keyFactory = KeyFactory.getInstance("EC");
            X509EncodedKeySpec keySpec = new X509EncodedKeySpec(publicKeyBytes);
            PublicKey publicKey = keyFactory.generatePublic(keySpec);

            // Verify signature
            Signature sig = Signature.getInstance("SHA256withECDSA");
            sig.initVerify(publicKey);
            sig.update(data);

            boolean isValid = sig.verify(signature);
            log.debug("Signature verification result: {}", isValid);
            return isValid;

        } catch (Exception e) {
            log.error("Signature verification failed: {}", e.getMessage(), e);
            return false;
        }
    }

    /**
     * Generate a cryptographically secure random challenge (nonce)
     *
     * @return 32 bytes of random data
     */
    public byte[] generateChallenge() {
        byte[] challenge = new byte[32];
        secureRandom.nextBytes(challenge);
        log.debug("Generated challenge: {} bytes", challenge.length);
        return challenge;
    }

    /**
     * Generate a 6-digit One-Time Password
     *
     * @return 6-digit OTP as a string
     */
    public String generateOTP() {
        int otp = 100000 + secureRandom.nextInt(900000);
        String otpString = String.valueOf(otp);
        log.debug("Generated OTP: {}", otpString);
        return otpString;
    }
}
