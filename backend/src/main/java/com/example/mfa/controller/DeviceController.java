package com.example.mfa.controller;

import com.example.mfa.dto.DeviceStatusResponse;
import com.example.mfa.model.Device;
import com.example.mfa.repository.DeviceRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Controller for device management operations
 */
@RestController
@RequestMapping("/api/v1")
@CrossOrigin(origins = "*")
public class DeviceController {

    private static final Logger log = LoggerFactory.getLogger(DeviceController.class);

    @Autowired
    private DeviceRepository deviceRepository;

    /**
     * Get all devices for a user
     * GET /api/v1/devices/{username}
     */
    @GetMapping("/devices/{username}")
    public ResponseEntity<List<DeviceStatusResponse>> getUserDevices(@PathVariable String username) {
        try {
            log.info("Getting devices for user: {}", username);

            List<Device> devices = deviceRepository.findByUser_Username(username);

            List<DeviceStatusResponse> response = devices.stream()
                    .map(device -> new DeviceStatusResponse(
                            device.getDeviceId(),
                            true,
                            device.getMethod().toString(),
                            device.getPublicKey() != null,
                            device.getPhoneNumber(),
                            device.getEnrolledAt() != null ? device.getEnrolledAt().toString() : null,
                            device.getLastUsed() != null ? device.getLastUsed().toString() : null
                    ))
                    .collect(Collectors.toList());

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Failed to get devices: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Get device status
     * GET /api/v1/device/{deviceId}/status
     */
    @GetMapping("/device/{deviceId}/status")
    public ResponseEntity<DeviceStatusResponse> getDeviceStatus(@PathVariable String deviceId) {
        try {
            log.info("Getting status for device: {}", deviceId);

            Device device = deviceRepository.findById(deviceId).orElse(null);

            if (device == null) {
                // Device not enrolled
                return ResponseEntity.ok(new DeviceStatusResponse(
                        deviceId,
                        false,
                        null,
                        false,
                        null,
                        null,
                        null
                ));
            }

            DeviceStatusResponse response = new DeviceStatusResponse(
                    device.getDeviceId(),
                    true,
                    device.getMethod().toString(),
                    device.getPublicKey() != null,
                    device.getPhoneNumber(),
                    device.getEnrolledAt() != null ? device.getEnrolledAt().toString() : null,
                    device.getLastUsed() != null ? device.getLastUsed().toString() : null
            );

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            log.error("Failed to get device status: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
