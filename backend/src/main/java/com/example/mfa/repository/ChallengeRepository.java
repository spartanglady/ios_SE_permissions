package com.example.mfa.repository;

import com.example.mfa.model.Challenge;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Repository for Challenge entity
 */
@Repository
public interface ChallengeRepository extends JpaRepository<Challenge, String> {

    Optional<Challenge> findByChallengeIdAndUsernameAndDeviceId(
        String challengeId, String username, String deviceId
    );

    List<Challenge> findByExpiresAtBefore(LocalDateTime dateTime);

    void deleteByExpiresAtBefore(LocalDateTime dateTime);
}
