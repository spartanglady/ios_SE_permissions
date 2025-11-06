package com.example.mfa.repository;

import com.example.mfa.model.Device;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repository for Device entity
 */
@Repository
public interface DeviceRepository extends JpaRepository<Device, String> {

    List<Device> findByUser_Username(String username);

    Optional<Device> findByDeviceIdAndUser_Username(String deviceId, String username);

    boolean existsByDeviceId(String deviceId);
}
