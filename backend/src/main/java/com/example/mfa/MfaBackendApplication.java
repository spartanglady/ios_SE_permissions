package com.example.mfa;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Main Spring Boot Application for MFA Backend
 *
 * This application provides REST API endpoints for:
 * - Device enrollment (Secure Enclave and SMS OTP methods)
 * - Challenge-response authentication
 * - OTP generation and verification
 * - Device management
 */
@SpringBootApplication
public class MfaBackendApplication {

    private static final Logger log = LoggerFactory.getLogger(MfaBackendApplication.class);

    public static void main(String[] args) {
        log.info("Starting MFA Backend Application...");
        SpringApplication.run(MfaBackendApplication.class, args);
        log.info("MFA Backend Application started successfully!");
        log.info("H2 Console available at: http://localhost:8080/h2-console");
        log.info("API Base URL: http://localhost:8080/api/v1");
    }

    /**
     * Configure CORS to allow requests from iOS app during local development
     */
    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")
                        .allowedOrigins("*")
                        .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                        .allowedHeaders("*")
                        .maxAge(3600);
            }
        };
    }
}
