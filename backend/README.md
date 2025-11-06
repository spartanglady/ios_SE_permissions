# MFA Backend - Spring Boot Application

Multi-Factor Authentication backend service for iOS Secure Enclave testing.

## Features

- Device enrollment (Secure Enclave and SMS OTP methods)
- Challenge-response authentication using ECDSA signatures
- SMS OTP generation and verification (mock implementation)
- Device management
- H2 in-memory database for testing
- RESTful API

## Requirements

- Java 17 or higher
- Maven 3.6+

## Project Structure

```
backend/
├── src/
│   └── main/
│       ├── java/com/example/mfa/
│       │   ├── controller/         # REST API controllers
│       │   │   ├── EnrollmentController.java
│       │   │   ├── AuthenticationController.java
│       │   │   └── DeviceController.java
│       │   ├── service/            # Business logic
│       │   │   ├── CryptoService.java
│       │   │   └── SMSService.java
│       │   ├── model/              # JPA entities
│       │   │   ├── User.java
│       │   │   ├── Device.java
│       │   │   ├── Challenge.java
│       │   │   └── OTP.java
│       │   ├── repository/         # Data access
│       │   │   ├── UserRepository.java
│       │   │   ├── DeviceRepository.java
│       │   │   ├── ChallengeRepository.java
│       │   │   └── OTPRepository.java
│       │   ├── dto/                # Request/Response objects
│       │   └── MfaBackendApplication.java
│       └── resources/
│           └── application.properties
└── pom.xml
```

## Getting Started

### 1. Build the Project

```bash
cd backend
mvn clean install
```

### 2. Run the Application

```bash
mvn spring-boot:run
```

The application will start on `http://localhost:8080`

### 3. Access H2 Console

- URL: `http://localhost:8080/h2-console`
- JDBC URL: `jdbc:h2:mem:mfadb`
- Username: `sa`
- Password: (leave empty)

## API Endpoints

### Enrollment

#### Enroll Device
```http
POST /api/v1/mfa/enroll
Content-Type: application/json

{
  "username": "testuser",
  "phoneNumber": "+1234567890",
  "publicKey": "base64EncodedPublicKey",
  "method": "secureEnclave",
  "deviceId": "unique-device-id",
  "deviceModel": "iPhone 15 Pro"
}
```

#### Unenroll Device
```http
POST /api/v1/mfa/unenroll
Content-Type: application/json

{
  "username": "testuser",
  "deviceId": "unique-device-id"
}
```

#### Upgrade to Secure Enclave
```http
POST /api/v1/mfa/upgrade
Content-Type: application/json

{
  "username": "testuser",
  "deviceId": "unique-device-id",
  "publicKey": "base64EncodedPublicKey"
}
```

#### Downgrade to SMS OTP
```http
POST /api/v1/mfa/downgrade
Content-Type: application/json

{
  "username": "testuser",
  "deviceId": "unique-device-id"
}
```

### Authentication

#### Initiate Authentication
```http
POST /api/v1/auth/initiate
Content-Type: application/json

{
  "username": "testuser",
  "deviceId": "unique-device-id"
}
```

Response (Secure Enclave):
```json
{
  "method": "secureEnclave",
  "challenge": "base64EncodedNonce",
  "challengeId": "uuid",
  "expiresIn": 300
}
```

#### Verify Signature
```http
POST /api/v1/auth/verify-signature
Content-Type: application/json

{
  "username": "testuser",
  "deviceId": "unique-device-id",
  "challengeId": "uuid",
  "signature": "base64EncodedSignature"
}
```

#### Request OTP
```http
POST /api/v1/auth/request-otp
Content-Type: application/json

{
  "username": "testuser",
  "phoneNumber": "+1234567890"
}
```

#### Verify OTP
```http
POST /api/v1/auth/verify-otp
Content-Type: application/json

{
  "username": "testuser",
  "otp": "123456"
}
```

### Device Management

#### Get User Devices
```http
GET /api/v1/devices/{username}
```

#### Get Device Status
```http
GET /api/v1/device/{deviceId}/status
```

## Testing with curl

### Example: Complete Enrollment and Authentication Flow

1. **Enroll a device:**
```bash
curl -X POST http://localhost:8080/api/v1/mfa/enroll \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "phoneNumber": "+1234567890",
    "publicKey": "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...",
    "method": "secureEnclave",
    "deviceId": "test-device-123",
    "deviceModel": "iPhone 15"
  }'
```

2. **Request authentication challenge:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/initiate \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "deviceId": "test-device-123"
  }'
```

3. **Verify signature:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/verify-signature \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "deviceId": "test-device-123",
    "challengeId": "returned-challenge-id",
    "signature": "base64-encoded-signature"
  }'
```

## Implementation Details

### Cryptographic Operations

- **Algorithm**: ECDSA with P-256 curve
- **Hash**: SHA-256
- **Key Format**: X.509 for public keys

### Challenge-Response Flow

1. Client requests challenge
2. Server generates 32-byte random nonce
3. Server stores challenge with 5-minute expiration
4. Client signs challenge with private key
5. Server verifies signature using stored public key
6. Challenge marked as used (one-time use)

### SMS OTP (Mock)

- Generates 6-digit codes
- 5-minute expiration
- One-time use
- Logs OTP to console (production would use Twilio/AWS SNS)

## Database Schema

### Users Table
- id (PK)
- username (unique)

### Devices Table
- deviceId (PK)
- user_id (FK)
- deviceModel
- method (SECURE_ENCLAVE | SMS_OTP)
- publicKey (BLOB)
- phoneNumber
- enrolledAt
- lastUsed

### Challenges Table
- challengeId (PK)
- username
- deviceId
- nonce (BLOB)
- createdAt
- expiresAt
- used (boolean)

### OTPs Table
- id (PK)
- username
- phoneNumber
- otp
- createdAt
- expiresAt
- used (boolean)

## Configuration

Edit `src/main/resources/application.properties` to configure:

- Server port
- Database settings
- Logging levels
- H2 console access

## Known Limitations

1. **In-Memory Database**: Data is lost on restart (use PostgreSQL for persistence)
2. **Mock SMS**: OTPs are only logged to console
3. **No JWT**: Simplified token generation (UUID-based)
4. **No Rate Limiting**: Production should implement rate limiting
5. **No TLS**: Uses HTTP (production should use HTTPS)

## Troubleshooting

### Port Already in Use
```bash
# Change port in application.properties
server.port=8081
```

### Signature Verification Fails
- Check public key is in X.509 format
- Verify Base64 encoding is correct
- Ensure challenge data matches what was signed

### H2 Console Won't Open
- Check `spring.h2.console.enabled=true` in application.properties
- Access at exactly `http://localhost:8080/h2-console`

## Production Considerations

For production use, you should:

1. Use PostgreSQL or MySQL instead of H2
2. Implement real SMS service (Twilio/AWS SNS)
3. Add proper JWT implementation with refresh tokens
4. Implement rate limiting
5. Add comprehensive error handling
6. Use HTTPS/TLS
7. Add request validation and sanitization
8. Implement audit logging
9. Add monitoring and alerting
10. Secure H2 console or disable it

## License

This is a reference implementation for learning and testing purposes.
