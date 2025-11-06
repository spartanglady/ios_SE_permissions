# iOS MFA Testing Project - Complete Specification

## Project Overview

Build a complete iOS application with Spring Boot backend to test Multi-Factor Authentication (MFA) using Secure Enclave key pairs, biometric authentication, and SMS OTP fallback.

**Goal**: Demonstrate and test all possible authentication flows including user acceptance/decline of biometrics, device security changes, and graceful fallback mechanisms.

---

## Project Structure

```
mfa-testing-project/
├── ios-app/
│   ├── MFATestApp/
│   │   ├── Models/
│   │   ├── ViewModels/
│   │   ├── Views/
│   │   ├── Services/
│   │   ├── Utilities/
│   │   └── Resources/
│   └── MFATestApp.xcodeproj
│
└── backend/
    ├── src/main/java/com/example/mfa/
    │   ├── controller/
    │   ├── service/
    │   ├── model/
    │   ├── repository/
    │   └── config/
    └── pom.xml
```

---

## iOS Application Requirements

### Technology Stack
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Minimum iOS**: 15.0
- **Target Devices**: iPhone only
- **Architecture**: MVVM

### Core Features

#### 1. **Enrollment Flow**
User can enroll in MFA with multiple paths:

**Flow A: Biometrics Available**
```
1. App detects Face ID/Touch ID available
2. Show option: "Use Face ID" or "Use Passcode Only"
3. If "Use Face ID" selected:
   - Create Secure Enclave key with .userPresence flag
   - Test key (triggers system permission if needed)
   - Handle user cancel → offer passcode fallback
   - Register public key with server
4. If "Use Passcode Only" selected:
   - Create Secure Enclave key with .devicePasscode flag
   - Test key with passcode
   - Register public key with server
```

**Flow B: Passcode Only Available**
```
1. App detects no biometrics enrolled
2. Show message: "Using passcode authentication"
3. Create Secure Enclave key with .devicePasscode flag
4. Register public key with server
```

**Flow C: No Device Security**
```
1. App detects no passcode set
2. Block enrollment
3. Show alert: "Please set up device passcode in Settings"
4. Offer SMS-only fallback registration
```

#### 2. **Authentication Flow**

**Challenge-Response Authentication:**
```
1. User enters username
2. App requests challenge from server
3. Server returns challenge (nonce)
4. App signs challenge with private key
   - Triggers biometric/passcode prompt
   - Handle cancellation gracefully
5. Send signature to server
6. Server verifies signature with stored public key
7. Grant or deny access
```

**SMS Fallback:**
```
1. If Secure Enclave auth unavailable
2. Request SMS OTP from server
3. Show OTP input screen
4. Verify OTP with server
```

#### 3. **Key Management**

**Secure Enclave Key Creation:**
- Support both `.userPresence` (biometric preferred) and `.devicePasscode` (passcode only)
- Use ECDSA with P-256 curve
- Store in Secure Enclave when available
- Fallback to regular keychain on simulator
- Unique application tags for different key types

**Key Retrieval:**
- Retrieve keys from keychain by application tag
- Handle missing key errors gracefully

**Key Deletion:**
- Delete keys when user unenrolls
- Clean up during method switching

#### 4. **Testing Dashboard**

Create a comprehensive testing screen showing:

**Device Status Section:**
- ✅/❌ Secure Enclave available
- ✅/❌ Biometrics enrolled (type: Face ID/Touch ID)
- ✅/❌ Passcode set
- Current enrollment status
- Current MFA method

**Test Actions:**
- [Enroll with Biometrics]
- [Enroll with Passcode Only]
- [Test Authentication]
- [Re-enroll]
- [Unenroll]
- [Simulate Biometric Decline]
- [Switch to SMS Fallback]
- [Check Device Security Status]

**Test Results Log:**
- Show chronological log of all actions
- Display success/failure with details
- Show LAError codes and descriptions
- Timestamp each event

#### 5. **Error Handling**

Handle all LocalAuthentication errors:

```swift
LAError.userCancel -> "User cancelled - offer passcode"
LAError.biometryNotAvailable -> "Biometrics disabled - use passcode"
LAError.biometryNotEnrolled -> "No biometrics enrolled"
LAError.passcodeNotSet -> "Critical: No device security"
LAError.biometryLockout -> "Too many attempts - use passcode"
LAError.authenticationFailed -> "Authentication failed - retry"
```

#### 6. **Settings Screen**

- View current security method
- Phone number for SMS fallback
- Option to change authentication method
- Option to unenroll device
- View server registration status
- App version and device info

---

## Backend (Spring Boot) Requirements

### Technology Stack
- **Framework**: Spring Boot 3.2+
- **Language**: Java 17+
- **Database**: H2 (in-memory for testing)
- **Security**: Spring Security (optional)
- **Build Tool**: Maven

### API Endpoints

#### 1. **Enrollment Endpoints**

**POST /api/v1/mfa/enroll**
```json
Request:
{
  "username": "testuser",
  "phoneNumber": "+1234567890",
  "publicKey": "base64EncodedPublicKey",
  "method": "secureEnclave" | "smsOTP",
  "deviceId": "unique-device-id",
  "deviceModel": "iPhone 15 Pro"
}

Response:
{
  "success": true,
  "deviceId": "unique-device-id",
  "method": "secureEnclave",
  "message": "Device enrolled successfully"
}
```

**POST /api/v1/mfa/unenroll**
```json
Request:
{
  "username": "testuser",
  "deviceId": "unique-device-id"
}

Response:
{
  "success": true,
  "message": "Device unenrolled"
}
```

**POST /api/v1/mfa/upgrade**
```json
Request:
{
  "username": "testuser",
  "deviceId": "unique-device-id",
  "publicKey": "base64EncodedPublicKey"
}

Response:
{
  "success": true,
  "method": "secureEnclave",
  "message": "Upgraded to Secure Enclave MFA"
}
```

**POST /api/v1/mfa/downgrade**
```json
Request:
{
  "username": "testuser",
  "deviceId": "unique-device-id"
}

Response:
{
  "success": true,
  "method": "smsOTP",
  "message": "Downgraded to SMS OTP"
}
```

#### 2. **Authentication Endpoints**

**POST /api/v1/auth/initiate**
```json
Request:
{
  "username": "testuser",
  "deviceId": "unique-device-id"
}

Response:
{
  "method": "secureEnclave" | "smsOTP",
  "challenge": "base64EncodedRandomNonce",
  "challengeId": "uuid",
  "expiresIn": 300
}
```

**POST /api/v1/auth/verify-signature**
```json
Request:
{
  "username": "testuser",
  "deviceId": "unique-device-id",
  "challengeId": "uuid",
  "signature": "base64EncodedSignature"
}

Response:
{
  "success": true,
  "token": "jwt-token",
  "message": "Authentication successful"
}
```

**POST /api/v1/auth/request-otp**
```json
Request:
{
  "username": "testuser",
  "phoneNumber": "+1234567890"
}

Response:
{
  "success": true,
  "message": "OTP sent to +1234567890",
  "expiresIn": 300
}
```

**POST /api/v1/auth/verify-otp**
```json
Request:
{
  "username": "testuser",
  "otp": "123456"
}

Response:
{
  "success": true,
  "token": "jwt-token",
  "message": "Authentication successful"
}
```

#### 3. **Device Management Endpoints**

**GET /api/v1/devices/{username}**
```json
Response:
{
  "devices": [
    {
      "deviceId": "unique-device-id",
      "deviceModel": "iPhone 15 Pro",
      "method": "secureEnclave",
      "enrolledAt": "2025-11-01T10:00:00Z",
      "lastUsed": "2025-11-05T08:30:00Z"
    }
  ]
}
```

**GET /api/v1/device/{deviceId}/status**
```json
Response:
{
  "deviceId": "unique-device-id",
  "enrolled": true,
  "method": "secureEnclave",
  "hasPublicKey": true,
  "phoneNumber": "+1234567890"
}
```

### Backend Implementation Details

#### **User Model**
```java
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String username;
    
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<Device> devices;
}
```

#### **Device Model**
```java
@Entity
public class Device {
    @Id
    private String deviceId;
    
    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
    
    private String deviceModel;
    
    @Enumerated(EnumType.STRING)
    private MFAMethod method; // SECURE_ENCLAVE, SMS_OTP
    
    @Lob
    private byte[] publicKey; // Only for SECURE_ENCLAVE
    
    private String phoneNumber;
    
    private LocalDateTime enrolledAt;
    private LocalDateTime lastUsed;
}
```

#### **Challenge Model**
```java
@Entity
public class Challenge {
    @Id
    private String challengeId;
    
    private String username;
    private String deviceId;
    
    @Lob
    private byte[] nonce;
    
    private LocalDateTime createdAt;
    private LocalDateTime expiresAt;
    
    private boolean used;
}
```

#### **OTP Model**
```java
@Entity
public class OTP {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String username;
    private String phoneNumber;
    private String otp;
    
    private LocalDateTime createdAt;
    private LocalDateTime expiresAt;
    
    private boolean used;
}
```

#### **Cryptographic Verification Service**
```java
@Service
public class CryptoService {
    
    // Verify ECDSA signature
    public boolean verifySignature(
        byte[] publicKeyBytes,
        byte[] data,
        byte[] signature
    ) {
        // Use Java Security API
        // KeyFactory with EC algorithm
        // Signature.getInstance("SHA256withECDSA")
        // Verify signature against data
    }
    
    // Generate random challenge
    public byte[] generateChallenge() {
        // SecureRandom - 32 bytes
    }
    
    // Generate OTP
    public String generateOTP() {
        // 6 digit random number
    }
}
```

#### **SMS Service (Mock)**
```java
@Service
public class SMSService {
    
    private static final Logger log = LoggerFactory.getLogger(SMSService.class);
    
    public void sendOTP(String phoneNumber, String otp) {
        // Mock implementation - just log
        log.info("📱 SMS to {}: Your OTP is {}", phoneNumber, otp);
        
        // In production, integrate with Twilio/AWS SNS/etc.
    }
}
```

---

## iOS Application Structure

### Models

**MFAMethod.swift**
```swift
enum MFAMethod: String, Codable {
    case secureEnclave = "secureEnclave"
    case smsOTP = "smsOTP"
}
```

**AuthMethod.swift**
```swift
enum AuthMethod: String, Codable {
    case biometric = "biometric"
    case passcode = "passcode"
}
```

**DeviceCapability.swift**
```swift
enum DeviceCapability {
    case biometricsAvailable
    case passcodeOnly
    case none
}
```

**KeyPair.swift**
```swift
struct KeyPair {
    let privateKey: SecKey
    let publicKey: SecKey
    
    func getPublicKeyData() -> Data? {
        var error: Unmanaged<CFError>?
        return SecKeyCopyExternalRepresentation(publicKey, &error) as Data?
    }
}
```

**Challenge.swift**
```swift
struct Challenge: Codable {
    let method: MFAMethod
    let challenge: String
    let challengeId: String
    let expiresIn: Int
}
```

### Services

**MFAConfiguration.swift**
```swift
struct MFAConfiguration {
    static var useSecureEnclave: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }
    
    static let baseURL = "http://localhost:8080/api/v1"
    static let timeout: TimeInterval = 30
}
```

**KeychainService.swift**
- Create keys with different access control flags
- Retrieve keys by tag
- Delete keys
- Sign data with private key

**BiometricService.swift**
- Check biometric availability
- Check biometric type (Face ID/Touch ID)
- Evaluate authentication policy
- Handle LAContext and errors

**NetworkService.swift**
- All API calls to backend
- Handle request/response serialization
- Error handling
- Timeout handling

**MFAStorageService.swift**
- UserDefaults for enrollment status
- Store device ID
- Store current MFA method
- Store phone number

### ViewModels

**EnrollmentViewModel.swift**
- Device capability checking
- Enrollment flow orchestration
- Handle biometric accept/decline
- Key creation
- Server registration
- Error handling

**AuthenticationViewModel.swift**
- Challenge request
- Signature creation
- OTP request/verification
- Authentication result handling

**TestingViewModel.swift**
- Device status monitoring
- Test action execution
- Result logging
- Debug information

### Views

**ContentView.swift**
- Main navigation
- Tab bar or navigation links

**EnrollmentView.swift**
- Enrollment options
- Biometric choice screen
- Progress indicators
- Success/error messages

**AuthenticationView.swift**
- Username input
- Authentication in progress
- OTP input (if needed)
- Success/error display

**TestingDashboardView.swift**
- Device status cards
- Test action buttons
- Results log list
- Expandable details

**SettingsView.swift**
- Current security display
- Phone number management
- Method switching
- Unenroll option

---

## Testing Scenarios to Implement

### Scenario 1: Happy Path (Biometric)
1. Launch app
2. No enrollment exists
3. Device has Face ID enrolled
4. Tap "Enroll with Face ID"
5. System prompts for Face ID permission
6. User approves
7. Face ID prompt appears
8. User authenticates
9. Success - key registered

### Scenario 2: User Declines Biometric Permission
1. Launch app
2. Tap "Enroll with Face ID"
3. System prompts for Face ID permission
4. User clicks "Don't Allow"
5. App catches LAError.userCancel
6. App shows "Use Passcode Instead?"
7. User taps "Yes"
8. Passcode prompt appears
9. Success - key registered with passcode method

### Scenario 3: User Chooses Passcode Only
1. Launch app
2. Device has biometrics but user prefers passcode
3. Tap "Use Passcode Only"
4. Passcode prompt appears
5. Success - key registered with passcode method

### Scenario 4: No Biometrics Enrolled
1. Launch app
2. Device has no Face ID/Touch ID enrolled
3. App shows "Passcode Authentication"
4. Only passcode option available
5. Enroll with passcode

### Scenario 5: No Device Security
1. Launch app
2. Device has no passcode set
3. App blocks enrollment
4. Shows alert with Settings link
5. Offers SMS-only registration

### Scenario 6: Authentication Success
1. User is enrolled (Secure Enclave)
2. Enter username
3. Tap "Sign In"
4. Challenge received from server
5. Face ID prompt appears
6. User authenticates
7. Signature sent to server
8. Server validates
9. Success screen

### Scenario 7: Authentication with SMS Fallback
1. User enrolled with SMS only
2. Enter username
3. Tap "Sign In"
4. Server sends OTP
5. OTP input screen
6. Enter correct OTP
7. Success

### Scenario 8: Device Security Removed After Enrollment
1. User enrolled with Secure Enclave
2. User goes to Settings
3. Disables Face ID
4. Removes passcode
5. Returns to app
6. App detects no security
7. Shows critical alert
8. Auto-downgrades to SMS
9. Notifies server

### Scenario 9: Re-enrollment After Security Restored
1. User on SMS method (had removed passcode)
2. User sets up Face ID in Settings
3. Returns to app
4. App detects security available
5. Shows "Upgrade to biometric security?"
6. User accepts
7. New key created
8. Server updated

### Scenario 10: Method Switching
1. User enrolled with Face ID
2. Go to Settings
3. Tap "Switch to Passcode Only"
4. Old key deleted
5. New passcode-only key created
6. Server updated

---

## Configuration Files

### Info.plist Required Keys
```xml
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to securely authenticate your identity for account access.</string>

<key>NSLocalNetworkUsageDescription</key>
<string>Connect to local server for testing MFA functionality.</string>
```

### Application Properties (Spring Boot)
```properties
# Server Configuration
server.port=8080
spring.application.name=mfa-backend

# H2 Database
spring.datasource.url=jdbc:h2:mem:mfadb
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=

# JPA
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create-drop
spring.jpa.show-sql=true

# H2 Console
spring.h2.console.enabled=true
spring.h2.console.path=/h2-console

# Logging
logging.level.com.example.mfa=DEBUG
```

---

## Implementation Priorities

### Phase 1: Core Infrastructure
1. Spring Boot project setup
2. Database models and repositories
3. iOS project setup
4. Basic networking layer
5. Keychain service

### Phase 2: Enrollment Flow
1. Backend enrollment endpoints
2. iOS key creation (both types)
3. Device capability detection
4. Enrollment UI
5. Error handling

### Phase 3: Authentication Flow
1. Challenge generation/validation
2. Signature verification
3. iOS authentication flow
4. OTP generation/validation
5. Authentication UI

### Phase 4: Testing & Edge Cases
1. Testing dashboard
2. All error scenarios
3. Method switching
4. Security status monitoring
5. Comprehensive logging

### Phase 5: Polish
1. UI/UX improvements
2. Better error messages
3. Loading states
4. Settings screen
5. Documentation

---

## Success Criteria

### iOS App
- ✅ Successfully creates Secure Enclave keys on real device
- ✅ Falls back to regular keychain on simulator
- ✅ Handles all biometric decline scenarios gracefully
- ✅ Properly detects device capabilities
- ✅ Clean error messages for all LAErrors
- ✅ Comprehensive testing dashboard works
- ✅ Can switch between authentication methods
- ✅ SMS fallback functions properly

### Backend
- ✅ All endpoints return correct responses
- ✅ ECDSA signature verification works
- ✅ Challenge expiration enforced
- ✅ OTP generation/validation secure
- ✅ Device management functional
- ✅ Proper error responses
- ✅ Logging adequate for debugging

### Testing
- ✅ All 10 scenarios testable
- ✅ Works on both simulator and real device
- ✅ Clear distinction between Secure Enclave and regular keychain
- ✅ Can demonstrate to stakeholders
- ✅ Code is well-documented

---

## Development Notes

### For iOS Developer
- Use async/await for all network calls
- Implement proper error handling with Result types
- Use Combine or @Published for reactive UI updates
- Keep views simple, logic in ViewModels
- Add comprehensive comments for crypto operations
- Use #if DEBUG for test helpers
- Distinguish simulator vs device clearly

### For Backend Developer
- Use proper DTOs for all requests/responses
- Implement comprehensive error handling
- Add request validation
- Log all security-relevant events
- Use Java Security API for crypto (not Bouncy Castle needed)
- Mock SMS service with clear logs
- Add H2 console for easy debugging
- Include API documentation (Swagger optional)

### Security Considerations
- Private keys never leave Secure Enclave on device
- Private keys never sent over network
- Challenges expire (5 minutes)
- OTPs expire (5 minutes)
- One-time use for challenges and OTPs
- Use HTTPS in production (HTTP ok for local testing)
- Validate all signatures server-side
- Don't trust client for security decisions

---

## Deliverables

### iOS App
1. Complete Xcode project
2. All source files with comments
3. README with setup instructions
4. Screenshots of key screens
5. Test device requirements documented

### Backend
1. Complete Spring Boot project
2. All source files with comments
3. README with setup instructions
4. API documentation (Postman collection or Swagger)
5. Sample curl commands for testing

### Documentation
1. Setup guide
2. Testing guide
3. API reference
4. Known limitations
5. Future enhancements

---

## Known Limitations

1. **Simulator**: Cannot test real Secure Enclave functionality
2. **SMS**: Mock implementation only (logs to console)
3. **JWT**: Not implementing full JWT flow (simplified tokens)
4. **Multi-device**: Basic support, not production-ready
5. **Biometric Changes**: Testing requires manual Settings changes
6. **Network**: Assumes localhost, no production deployment

---

## Future Enhancements

- Real SMS integration (Twilio)
- JWT with refresh tokens
- Push notification authentication
- Hardware security key support
- WebAuthn/FIDO2 integration
- Comprehensive analytics
- Remote device management
- Audit logging
- Rate limiting
- Account recovery flow

---

## Questions to Clarify During Development

1. Should we support multiple devices per user?
2. JWT token expiration time?
3. Maximum failed authentication attempts?
4. Challenge/OTP validity duration?
5. Should we persist logs locally on iOS?
6. H2 vs PostgreSQL for persistence?
7. Need for biometric prompt customization?
8. Support for iPad?

---

## Contact & Support

This specification provides comprehensive guidance for implementing a complete MFA testing system. The implementation should prioritize clarity and testability over production-ready security features, as the goal is to demonstrate and test various MFA flows.

The system should allow developers to:
- Understand how Secure Enclave works
- Test biometric authentication flows
- Handle all user scenarios gracefully
- Demonstrate to stakeholders
- Use as reference for production implementation

---

**Document Version**: 1.0  
**Last Updated**: November 2025  
**Status**: Ready for Implementation
