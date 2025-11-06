package com.example.mfa.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.LocalDateTime;

/**
 * Entity representing an authentication challenge
 */
@Entity
@Table(name = "challenges")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Challenge {

    @Id
    private String challengeId;

    @Column(nullable = false)
    private String username;

    @Column(nullable = false)
    private String deviceId;

    @Lob
    @Column(columnDefinition = "BLOB", nullable = false)
    private byte[] nonce;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime expiresAt;

    @Column(nullable = false)
    private boolean used = false;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (expiresAt == null) {
            expiresAt = createdAt.plusMinutes(5);  // 5-minute expiration
        }
    }

    public boolean isExpired() {
        return LocalDateTime.now().isAfter(expiresAt);
    }
}
