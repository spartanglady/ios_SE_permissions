package com.example.mfa.repository;

import com.example.mfa.model.OTP;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Repository for OTP entity
 */
@Repository
public interface OTPRepository extends JpaRepository<OTP, Long> {

    Optional<OTP> findTopByUsernameOrderByCreatedAtDesc(String username);

    Optional<OTP> findByUsernameAndOtpAndUsedFalse(String username, String otp);

    List<OTP> findByExpiresAtBefore(LocalDateTime dateTime);

    void deleteByExpiresAtBefore(LocalDateTime dateTime);
}
