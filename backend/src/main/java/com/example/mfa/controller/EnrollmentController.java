package com.example.mfa.controller;

import com.example.mfa.dto.*;
import com.example.mfa.model.*;
import com.example.mfa.repository.*;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Base64;

/**
 * Controller for device enrollment operations
 */
@RestController
@RequestMapping("/api/v1/mfa")
@CrossOrigin(origins = "*")  // Allow CORS for local iOS testing
public class EnrollmentController {

    private static final Logger log = LoggerFactory.getLogger(EnrollmentController.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DeviceRepository deviceRepository;

    /**
     * Enroll a new device for MFA
     * POST /api/v1/mfa/enroll
     */
    @PostMapping("/enroll")
    public ResponseEntity<EnrollmentResponse> enroll(@Valid @RequestBody EnrollmentRequest request) {
        try {
            log.info("Enrollment request for user: {}, device: {}, method: {}",
                    request.getUsername(), request.getDeviceId(), request.getMethod());

            // Validate method
            MFAMethod method;
            try {
                method = MFAMethod.valueOf(request.getMethod().toUpperCase().replace("ENCLAVE", "_ENCLAVE"));
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest()
                        .body(new EnrollmentResponse(false, "Invalid method. Use 'secureEnclave' or 'smsOTP'"));
            }

            // Validate public key for Secure Enclave method
            if (method == MFAMethod.SECURE_ENCLAVE && (request.getPublicKey() == null || request.getPublicKey().isEmpty())) {
                return ResponseEntity.badRequest()
                        .body(new EnrollmentResponse(false, "Public key is required for Secure Enclave method"));
            }

            // Find or create user
            User user = userRepository.findByUsername(request.getUsername())
                    .orElseGet(() -> {
                        User newUser = new User(request.getUsername());
                        return userRepository.save(newUser);
                    });

            // Check if device already exists
            if (deviceRepository.existsByDeviceId(request.getDeviceId())) {
                // Update existing device
                Device existingDevice = deviceRepository.findById(request.getDeviceId()).orElseThrow();
                existingDevice.setMethod(method);
                existingDevice.setDeviceModel(request.getDeviceModel());
                existingDevice.setPhoneNumber(request.getPhoneNumber());

                if (method == MFAMethod.SECURE_ENCLAVE && request.getPublicKey() != null) {
                    existingDevice.setPublicKey(Base64.getDecoder().decode(request.getPublicKey()));
                }

                deviceRepository.save(existingDevice);
                log.info("Updated existing device: {}", request.getDeviceId());

                return ResponseEntity.ok(new EnrollmentResponse(
                        true,
                        request.getDeviceId(),
                        method.toString(),
                        "Device updated successfully"
                ));
            }

            // Create new device
            Device device = new Device();
            device.setDeviceId(request.getDeviceId());
            device.setUser(user);
            device.setDeviceModel(request.getDeviceModel() != null ? request.getDeviceModel() : "Unknown");
            device.setMethod(method);
            device.setPhoneNumber(request.getPhoneNumber());
            device.setEnrolledAt(LocalDateTime.now());

            // Store public key if provided
            if (method == MFAMethod.SECURE_ENCLAVE && request.getPublicKey() != null) {
                try {
                    device.setPublicKey(Base64.getDecoder().decode(request.getPublicKey()));
                } catch (IllegalArgumentException e) {
                    return ResponseEntity.badRequest()
                            .body(new EnrollmentResponse(false, "Invalid Base64 encoding for public key"));
                }
            }

            deviceRepository.save(device);
            log.info("Device enrolled successfully: {}", request.getDeviceId());

            return ResponseEntity.ok(new EnrollmentResponse(
                    true,
                    request.getDeviceId(),
                    method.toString(),
                    "Device enrolled successfully"
            ));

        } catch (Exception e) {
            log.error("Enrollment failed: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new EnrollmentResponse(false, "Enrollment failed: " + e.getMessage()));
        }
    }

    /**
     * Unenroll a device
     * POST /api/v1/mfa/unenroll
     */
    @PostMapping("/unenroll")
    public ResponseEntity<EnrollmentResponse> unenroll(@Valid @RequestBody UnenrollRequest request) {
        try {
            log.info("Unenrollment request for user: {}, device: {}", request.getUsername(), request.getDeviceId());

            // Find device
            Device device = deviceRepository.findByDeviceIdAndUser_Username(request.getDeviceId(), request.getUsername())
                    .orElse(null);

            if (device == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new EnrollmentResponse(false, "Device not found"));
            }

            // Delete device
            deviceRepository.delete(device);
            log.info("Device unenrolled successfully: {}", request.getDeviceId());

            return ResponseEntity.ok(new EnrollmentResponse(true, "Device unenrolled successfully"));

        } catch (Exception e) {
            log.error("Unenrollment failed: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new EnrollmentResponse(false, "Unenrollment failed: " + e.getMessage()));
        }
    }

    /**
     * Upgrade device to Secure Enclave method
     * POST /api/v1/mfa/upgrade
     */
    @PostMapping("/upgrade")
    public ResponseEntity<EnrollmentResponse> upgrade(@Valid @RequestBody EnrollmentRequest request) {
        try {
            log.info("Upgrade request for user: {}, device: {}", request.getUsername(), request.getDeviceId());

            // Find device
            Device device = deviceRepository.findByDeviceIdAndUser_Username(request.getDeviceId(), request.getUsername())
                    .orElse(null);

            if (device == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new EnrollmentResponse(false, "Device not found"));
            }

            // Validate public key
            if (request.getPublicKey() == null || request.getPublicKey().isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(new EnrollmentResponse(false, "Public key is required for upgrade"));
            }

            // Update to Secure Enclave method
            device.setMethod(MFAMethod.SECURE_ENCLAVE);
            device.setPublicKey(Base64.getDecoder().decode(request.getPublicKey()));
            deviceRepository.save(device);

            log.info("Device upgraded to Secure Enclave: {}", request.getDeviceId());

            return ResponseEntity.ok(new EnrollmentResponse(
                    true,
                    request.getDeviceId(),
                    "SECURE_ENCLAVE",
                    "Upgraded to Secure Enclave MFA"
            ));

        } catch (Exception e) {
            log.error("Upgrade failed: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new EnrollmentResponse(false, "Upgrade failed: " + e.getMessage()));
        }
    }

    /**
     * Downgrade device to SMS OTP method
     * POST /api/v1/mfa/downgrade
     */
    @PostMapping("/downgrade")
    public ResponseEntity<EnrollmentResponse> downgrade(@Valid @RequestBody UnenrollRequest request) {
        try {
            log.info("Downgrade request for user: {}, device: {}", request.getUsername(), request.getDeviceId());

            // Find device
            Device device = deviceRepository.findByDeviceIdAndUser_Username(request.getDeviceId(), request.getUsername())
                    .orElse(null);

            if (device == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new EnrollmentResponse(false, "Device not found"));
            }

            // Update to SMS OTP method
            device.setMethod(MFAMethod.SMS_OTP);
            device.setPublicKey(null);  // Remove public key
            deviceRepository.save(device);

            log.info("Device downgraded to SMS OTP: {}", request.getDeviceId());

            return ResponseEntity.ok(new EnrollmentResponse(
                    true,
                    request.getDeviceId(),
                    "SMS_OTP",
                    "Downgraded to SMS OTP"
            ));

        } catch (Exception e) {
            log.error("Downgrade failed: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new EnrollmentResponse(false, "Downgrade failed: " + e.getMessage()));
        }
    }
}
