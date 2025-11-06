package com.example.mfa.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.LocalDateTime;

/**
 * Entity representing a device enrolled for MFA
 */
@Entity
@Table(name = "devices")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Device {

    @Id
    private String deviceId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String deviceModel;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private MFAMethod method;

    @Lob
    @Column(columnDefinition = "BLOB")
    private byte[] publicKey;  // Only for SECURE_ENCLAVE method

    private String phoneNumber;

    @Column(nullable = false)
    private LocalDateTime enrolledAt;

    private LocalDateTime lastUsed;

    @PrePersist
    protected void onCreate() {
        if (enrolledAt == null) {
            enrolledAt = LocalDateTime.now();
        }
    }
}
