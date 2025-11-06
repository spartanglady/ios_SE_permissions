package com.example.mfa.controller;

import com.example.mfa.dto.*;
import com.example.mfa.model.*;
import com.example.mfa.repository.*;
import com.example.mfa.service.CryptoService;
import com.example.mfa.service.SMSService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Base64;
import java.util.UUID;

/**
 * Controller for authentication operations
 */
@RestController
@RequestMapping("/api/v1/auth")
@CrossOrigin(origins = "*")
public class AuthenticationController {

    private static final Logger log = LoggerFactory.getLogger(AuthenticationController.class);

    @Autowired
    private DeviceRepository deviceRepository;

    @Autowired
    private ChallengeRepository challengeRepository;

    @Autowired
    private OTPRepository otpRepository;

    @Autowired
    private CryptoService cryptoService;

    @Autowired
    private SMSService smsService;

    /**
     * Initiate authentication - returns challenge or triggers OTP
     * POST /api/v1/auth/initiate
     */
    @PostMapping("/initiate")
    public ResponseEntity<ChallengeResponse> initiateAuthentication(@Valid @RequestBody AuthInitiateRequest request) {
        try {
            log.info("Authentication initiation for user: {}, device: {}", request.getUsername(), request.getDeviceId());

            // Find device
            Device device = deviceRepository.findByDeviceIdAndUser_Username(request.getDeviceId(), request.getUsername())
                    .orElse(null);

            if (device == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ChallengeResponse("error", null, null, 0));
            }

            // Check method
            if (device.getMethod() == MFAMethod.SECURE_ENCLAVE) {
                // Generate challenge for Secure Enclave authentication
                byte[] nonce = cryptoService.generateChallenge();
                String challengeId = UUID.randomUUID().toString();

                // Save challenge
                Challenge challenge = new Challenge();
                challenge.setChallengeId(challengeId);
                challenge.setUsername(request.getUsername());
                challenge.setDeviceId(request.getDeviceId());
                challenge.setNonce(nonce);
                challenge.setCreatedAt(LocalDateTime.now());
                challenge.setExpiresAt(LocalDateTime.now().plusMinutes(5));
                challenge.setUsed(false);
                challengeRepository.save(challenge);

                log.info("Challenge generated: {}", challengeId);

                return ResponseEntity.ok(new ChallengeResponse(
                        "secureEnclave",
                        Base64.getEncoder().encodeToString(nonce),
                        challengeId,
                        300  // 5 minutes
                ));

            } else {
                // SMS OTP method
                log.info("SMS OTP method - sending OTP");
                return ResponseEntity.ok(new ChallengeResponse(
                        "smsOTP",
                        null,
                        null,
                        300
                ));
            }

        } catch (Exception e) {
            log.error("Authentication initiation failed: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ChallengeResponse("error", null, null, 0));
        }
    }

    /**
     * Verify signature for Secure Enclave authentication
     * POST /api/v1/auth/verify-signature
     */
    @PostMapping("/verify-signature")
    public ResponseEntity<AuthResponse> verifySignature(@Valid @RequestBody VerifySignatureRequest request) {
        try {
            log.info("Signature verification for user: {}, device: {}, challenge: {}",
                    request.getUsername(), request.getDeviceId(), request.getChallengeId());

            // Find challenge
            Challenge challenge = challengeRepository.findByChallengeIdAndUsernameAndDeviceId(
                    request.getChallengeId(),
                    request.getUsername(),
                    request.getDeviceId()
            ).orElse(null);

            if (challenge == null) {
                log.warn("Challenge not found: {}", request.getChallengeId());
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new AuthResponse(false, "Challenge not found"));
            }

            // Check if already used
            if (challenge.isUsed()) {
                log.warn("Challenge already used: {}", request.getChallengeId());
                return ResponseEntity.badRequest()
                        .body(new AuthResponse(false, "Challenge already used"));
            }

            // Check if expired
            if (challenge.isExpired()) {
                log.warn("Challenge expired: {}", request.getChallengeId());
                return ResponseEntity.badRequest()
                        .body(new AuthResponse(false, "Challenge expired"));
            }

            // Find device
            Device device = deviceRepository.findById(request.getDeviceId()).orElse(null);
            if (device == null || device.getPublicKey() == null) {
                log.warn("Device not found or no public key: {}", request.getDeviceId());
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new AuthResponse(false, "Device not found or not enrolled"));
            }

            // Decode signature
            byte[] signature;
            try {
                signature = Base64.getDecoder().decode(request.getSignature());
            } catch (IllegalArgumentException e) {
                log.error("Invalid Base64 signature");
                return ResponseEntity.badRequest()
                        .body(new AuthResponse(false, "Invalid signature encoding"));
            }

            // Verify signature
            boolean isValid = cryptoService.verifySignature(
                    device.getPublicKey(),
                    challenge.getNonce(),
                    signature
            );

            if (isValid) {
                // Mark challenge as used
                challenge.setUsed(true);
                challengeRepository.save(challenge);

                // Update device last used
                device.setLastUsed(LocalDateTime.now());
                deviceRepository.save(device);

                // Generate token (simplified - just a UUID)
                String token = "token_" + UUID.randomUUID().toString();

                log.info("Authentication successful for device: {}", request.getDeviceId());

                return ResponseEntity.ok(new AuthResponse(true, token, "Authentication successful"));

            } else {
                log.warn("Invalid signature for device: {}", request.getDeviceId());
                return ResponseEntity.badRequest()
                        .body(new AuthResponse(false, "Invalid signature"));
            }

        } catch (Exception e) {
            log.error("Signature verification failed: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new AuthResponse(false, "Verification failed: " + e.getMessage()));
        }
    }

    /**
     * Request OTP via SMS
     * POST /api/v1/auth/request-otp
     */
    @PostMapping("/request-otp")
    public ResponseEntity<AuthResponse> requestOTP(@Valid @RequestBody OTPRequest request) {
        try {
            log.info("OTP request for user: {}", request.getUsername());

            // Validate phone number
            if (request.getPhoneNumber() == null || !smsService.isValidPhoneNumber(request.getPhoneNumber())) {
                return ResponseEntity.badRequest()
                        .body(new AuthResponse(false, "Valid phone number is required"));
            }

            // Generate OTP
            String otp = cryptoService.generateOTP();

            // Save OTP
            OTP otpEntity = new OTP();
            otpEntity.setUsername(request.getUsername());
            otpEntity.setPhoneNumber(request.getPhoneNumber());
            otpEntity.setOtp(otp);
            otpEntity.setCreatedAt(LocalDateTime.now());
            otpEntity.setExpiresAt(LocalDateTime.now().plusMinutes(5));
            otpEntity.setUsed(false);
            otpRepository.save(otpEntity);

            // Send OTP via SMS (mock)
            smsService.sendOTP(request.getPhoneNumber(), otp);

            log.info("OTP sent to {}", request.getPhoneNumber());

            return ResponseEntity.ok(new AuthResponse(
                    true,
                    null,
                    String.format("OTP sent to %s", request.getPhoneNumber())
            ));

        } catch (Exception e) {
            log.error("OTP request failed: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new AuthResponse(false, "OTP request failed: " + e.getMessage()));
        }
    }

    /**
     * Verify OTP
     * POST /api/v1/auth/verify-otp
     */
    @PostMapping("/verify-otp")
    public ResponseEntity<AuthResponse> verifyOTP(@Valid @RequestBody OTPRequest request) {
        try {
            log.info("OTP verification for user: {}", request.getUsername());

            if (request.getOtp() == null || request.getOtp().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(new AuthResponse(false, "OTP is required"));
            }

            // Find OTP
            OTP otpEntity = otpRepository.findByUsernameAndOtpAndUsedFalse(request.getUsername(), request.getOtp())
                    .orElse(null);

            if (otpEntity == null) {
                log.warn("OTP not found or already used for user: {}", request.getUsername());
                return ResponseEntity.badRequest()
                        .body(new AuthResponse(false, "Invalid or expired OTP"));
            }

            // Check if expired
            if (otpEntity.isExpired()) {
                log.warn("OTP expired for user: {}", request.getUsername());
                return ResponseEntity.badRequest()
                        .body(new AuthResponse(false, "OTP expired"));
            }

            // Mark OTP as used
            otpEntity.setUsed(true);
            otpRepository.save(otpEntity);

            // Generate token
            String token = "token_" + UUID.randomUUID().toString();

            log.info("OTP verification successful for user: {}", request.getUsername());

            return ResponseEntity.ok(new AuthResponse(true, token, "Authentication successful"));

        } catch (Exception e) {
            log.error("OTP verification failed: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new AuthResponse(false, "Verification failed: " + e.getMessage()));
        }
    }
}
