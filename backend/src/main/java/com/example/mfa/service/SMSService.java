package com.example.mfa.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Mock SMS Service
 * In production, this would integrate with Twilio, AWS SNS, or similar service
 * For testing, it just logs the OTP to console
 */
@Service
public class SMSService {

    private static final Logger log = LoggerFactory.getLogger(SMSService.class);

    /**
     * Send OTP via SMS (mock implementation - logs to console)
     *
     * @param phoneNumber The phone number to send to
     * @param otp         The one-time password to send
     */
    public void sendOTP(String phoneNumber, String otp) {
        // Mock implementation - just log
        log.info("📱 SMS to {}: Your OTP is {}", phoneNumber, otp);
        log.info("   (This is a mock SMS - in production, this would send via Twilio/AWS SNS)");

        // In production, you would integrate with an SMS gateway:
        // Example with Twilio:
        // twilioClient.messages.create(
        //     new PhoneNumber(phoneNumber),
        //     new PhoneNumber(fromNumber),
        //     "Your OTP is: " + otp
        // );
    }

    /**
     * Validate phone number format (basic validation)
     *
     * @param phoneNumber The phone number to validate
     * @return true if format is valid
     */
    public boolean isValidPhoneNumber(String phoneNumber) {
        if (phoneNumber == null || phoneNumber.isEmpty()) {
            return false;
        }
        // Basic validation: starts with + and has 10-15 digits
        return phoneNumber.matches("^\\+\\d{10,15}$");
    }
}
