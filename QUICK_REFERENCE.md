# MFA Implementation Quick Reference

Quick lookup for critical implementation details.

## iOS Key Creation

### Biometric Preferred (with Passcode Fallback)
```swift
let access = SecAccessControlCreateWithFlags(
    nil,
    kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    [.privateKeyUsage, .userPresence],
    nil
)

var attributes: [String: Any] = [
    kSecAttrKeyType as String: kSecAttrKeyTypeECSECP256r1,
    kSecAttrKeySizeInBits as String: 256,
    kSecPrivateKeyAttrs as String: [
        kSecAttrIsPermanent as String: true,
        kSecAttrApplicationTag as String: "com.app.mfa.biometric".data(using: .utf8)!,
        kSecAttrAccessControl as String: access
    ]
]

// Only on real devices
#if !targetEnvironment(simulator)
attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
#endif

var error: Unmanaged<CFError>?
guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
    throw error!.takeRetainedValue() as Error
}
```

### Passcode Only
```swift
let access = SecAccessControlCreateWithFlags(
    nil,
    kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    [.privateKeyUsage, .devicePasscode],  // Only difference
    nil
)
// ... rest same as above but with different tag
```

## iOS Signing Data

```swift
func signData(_ data: Data, privateKey: SecKey, context: LAContext) throws -> Data {
    var error: Unmanaged<CFError>?
    
    guard let signature = SecKeyCreateSignature(
        privateKey,
        .ecdsaSignatureMessageX962SHA256,
        data as CFData,
        &error
    ) as Data? else {
        throw error!.takeRetainedValue() as Error
    }
    
    return signature
}
```

## iOS LAContext Usage

```swift
let context = LAContext()
context.localizedReason = "Verify your identity"
context.localizedCancelTitle = "Use Passcode"

// For enrollment test
let testData = "enrollment_test".data(using: .utf8)!
let signature = try signData(testData, with: privateKey, context: context)
```

## iOS Error Handling

```swift
do {
    let signature = try signChallenge(challenge)
} catch let error as LAError {
    switch error.code {
    case .userCancel:
        // Offer passcode fallback
    case .biometryNotAvailable, .biometryNotEnrolled:
        // Switch to passcode method
    case .passcodeNotSet:
        // Critical: no security
        await downgradeTosms()
    case .biometryLockout:
        // Too many attempts - use passcode
    case .authenticationFailed:
        // Wrong credential - retry
    default:
        // Generic error
    }
}
```

## iOS Device Capability Check

```swift
enum DeviceCapability {
    case biometricsAvailable
    case passcodeOnly
    case none
}

func checkDeviceCapabilities() -> DeviceCapability {
    let context = LAContext()
    var error: NSError?
    
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
        return .biometricsAvailable
    }
    
    if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
        return .passcodeOnly
    }
    
    return .none
}
```

## iOS Public Key Export

```swift
func exportPublicKey(_ publicKey: SecKey) -> Data? {
    var error: Unmanaged<CFError>?
    guard let keyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
        return nil
    }
    return keyData
}

// For server transmission
let base64Key = keyData.base64EncodedString()
```

## Backend Signature Verification (Java)

```java
@Service
public class CryptoService {
    
    public boolean verifySignature(byte[] publicKeyBytes, byte[] data, byte[] signature) {
        try {
            // Reconstruct EC public key from raw bytes
            KeyFactory keyFactory = KeyFactory.getInstance("EC");
            X509EncodedKeySpec keySpec = new X509EncodedKeySpec(publicKeyBytes);
            PublicKey publicKey = keyFactory.generatePublic(keySpec);
            
            // Verify signature
            Signature sig = Signature.getInstance("SHA256withECDSA");
            sig.initVerify(publicKey);
            sig.update(data);
            
            return sig.verify(signature);
            
        } catch (Exception e) {
            log.error("Signature verification failed", e);
            return false;
        }
    }
    
    public byte[] generateChallenge() {
        SecureRandom random = new SecureRandom();
        byte[] challenge = new byte[32];
        random.nextBytes(challenge);
        return challenge;
    }
    
    public String generateOTP() {
        SecureRandom random = new SecureRandom();
        int otp = 100000 + random.nextInt(900000);
        return String.valueOf(otp);
    }
}
```

## Backend Controller Example

```java
@RestController
@RequestMapping("/api/v1/mfa")
public class EnrollmentController {
    
    @PostMapping("/enroll")
    public ResponseEntity<EnrollmentResponse> enroll(@RequestBody EnrollmentRequest request) {
        try {
            // Decode public key from Base64
            byte[] publicKeyBytes = Base64.getDecoder().decode(request.getPublicKey());
            
            // Create device
            Device device = new Device();
            device.setDeviceId(request.getDeviceId());
            device.setPublicKey(publicKeyBytes);
            device.setMethod(MFAMethod.valueOf(request.getMethod().toUpperCase()));
            device.setPhoneNumber(request.getPhoneNumber());
            device.setEnrolledAt(LocalDateTime.now());
            
            // Save
            deviceRepository.save(device);
            
            return ResponseEntity.ok(new EnrollmentResponse(true, "Enrolled successfully"));
            
        } catch (Exception e) {
            log.error("Enrollment failed", e);
            return ResponseEntity.badRequest()
                .body(new EnrollmentResponse(false, "Enrollment failed: " + e.getMessage()));
        }
    }
}
```

## Backend Authentication Flow

```java
@PostMapping("/auth/initiate")
public ResponseEntity<ChallengeResponse> initiateAuth(@RequestBody AuthRequest request) {
    // Generate challenge
    byte[] nonce = cryptoService.generateChallenge();
    String challengeId = UUID.randomUUID().toString();
    
    // Save challenge
    Challenge challenge = new Challenge();
    challenge.setChallengeId(challengeId);
    challenge.setNonce(nonce);
    challenge.setUsername(request.getUsername());
    challenge.setDeviceId(request.getDeviceId());
    challenge.setCreatedAt(LocalDateTime.now());
    challenge.setExpiresAt(LocalDateTime.now().plusMinutes(5));
    challengeRepository.save(challenge);
    
    // Return to client
    return ResponseEntity.ok(new ChallengeResponse(
        Base64.getEncoder().encodeToString(nonce),
        challengeId,
        300
    ));
}

@PostMapping("/auth/verify-signature")
public ResponseEntity<AuthResponse> verifySignature(@RequestBody VerifyRequest request) {
    // Get challenge
    Challenge challenge = challengeRepository.findById(request.getChallengeId())
        .orElseThrow(() -> new RuntimeException("Challenge not found"));
    
    // Check expiration
    if (LocalDateTime.now().isAfter(challenge.getExpiresAt())) {
        return ResponseEntity.badRequest()
            .body(new AuthResponse(false, "Challenge expired"));
    }
    
    // Check already used
    if (challenge.isUsed()) {
        return ResponseEntity.badRequest()
            .body(new AuthResponse(false, "Challenge already used"));
    }
    
    // Get device
    Device device = deviceRepository.findById(request.getDeviceId())
        .orElseThrow(() -> new RuntimeException("Device not found"));
    
    // Verify signature
    byte[] signature = Base64.getDecoder().decode(request.getSignature());
    boolean valid = cryptoService.verifySignature(
        device.getPublicKey(),
        challenge.getNonce(),
        signature
    );
    
    if (valid) {
        // Mark challenge as used
        challenge.setUsed(true);
        challengeRepository.save(challenge);
        
        // Update device last used
        device.setLastUsed(LocalDateTime.now());
        deviceRepository.save(device);
        
        // Generate token (simplified)
        String token = "token_" + UUID.randomUUID().toString();
        
        return ResponseEntity.ok(new AuthResponse(true, "Authenticated", token));
    } else {
        return ResponseEntity.badRequest()
            .body(new AuthResponse(false, "Invalid signature"));
    }
}
```

## iOS Network Layer

```swift
class NetworkService {
    let baseURL = "http://localhost:8080/api/v1"
    
    func enroll(
        username: String,
        phoneNumber: String,
        publicKey: String,
        method: MFAMethod,
        deviceId: String
    ) async throws -> EnrollmentResponse {
        let url = URL(string: "\(baseURL)/mfa/enroll")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = EnrollmentRequest(
            username: username,
            phoneNumber: phoneNumber,
            publicKey: publicKey,
            method: method.rawValue,
            deviceId: deviceId
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(EnrollmentResponse.self, from: data)
    }
    
    func getChallenge(username: String, deviceId: String) async throws -> ChallengeResponse {
        let url = URL(string: "\(baseURL)/auth/initiate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = AuthRequest(username: username, deviceId: deviceId)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ChallengeResponse.self, from: data)
    }
    
    func verifySignature(
        username: String,
        deviceId: String,
        challengeId: String,
        signature: String
    ) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/verify-signature")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = VerifyRequest(
            username: username,
            deviceId: deviceId,
            challengeId: challengeId,
            signature: signature
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
}
```

## iOS Complete Enrollment Flow

```swift
class EnrollmentViewModel: ObservableObject {
    @Published var status: EnrollmentStatus = .notStarted
    
    private let keychainService = KeychainService()
    private let biometricService = BiometricService()
    private let networkService = NetworkService()
    private let storage = MFAStorageService()
    
    func enrollWithBiometrics(username: String, phoneNumber: String) async {
        do {
            status = .creatingKey
            
            // Create key
            let keyPair = try keychainService.createKeyWithBiometrics()
            
            // Test key (triggers biometric prompt)
            status = .testingKey
            let context = LAContext()
            context.localizedReason = "Enable biometric authentication"
            context.localizedCancelTitle = "Use Passcode Instead"
            
            let testData = Data("enrollment_test".utf8)
            let _ = try keychainService.signData(testData, with: keyPair.privateKey, context: context)
            
            // Export public key
            guard let publicKeyData = keyPair.getPublicKeyData() else {
                throw EnrollmentError.keyExportFailed
            }
            let publicKeyBase64 = publicKeyData.base64EncodedString()
            
            // Register with server
            status = .registering
            let deviceId = storage.getOrCreateDeviceId()
            let response = try await networkService.enroll(
                username: username,
                phoneNumber: phoneNumber,
                publicKey: publicKeyBase64,
                method: .secureEnclave,
                deviceId: deviceId
            )
            
            // Save enrollment
            storage.saveEnrollment(
                username: username,
                method: .biometric,
                deviceId: deviceId
            )
            
            status = .success
            
        } catch let error as LAError {
            handleLAError(error, username: username, phoneNumber: phoneNumber)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }
    
    func handleLAError(_ error: LAError, username: String, phoneNumber: String) {
        switch error.code {
        case .userCancel:
            // Offer passcode fallback
            status = .offerPasscodeFallback
        case .biometryNotAvailable, .biometryNotEnrolled:
            // Auto-switch to passcode
            Task {
                await enrollWithPasscodeOnly(username: username, phoneNumber: phoneNumber)
            }
        case .passcodeNotSet:
            status = .failed("Please set up device security")
        default:
            status = .failed(error.localizedDescription)
        }
    }
}
```

## Testing Simulator vs Device

```swift
#if targetEnvironment(simulator)
let isSimulator = true
#else
let isSimulator = false
#endif

// Use in key creation
var attributes: [String: Any] = [
    kSecAttrKeyType as String: kSecAttrKeyTypeECSECP256r1,
    kSecAttrKeySizeInBits as String: 256,
    // ... other attributes
]

if !isSimulator {
    attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
}
```

## Common Errors and Solutions

### iOS

**Error**: SecKeyCreateRandomKey returns nil
- Check access control flags are correct
- Verify device has passcode set
- Check application tag is valid Data

**Error**: LAError.biometryNotAvailable
- Biometrics disabled in Settings
- Fall back to passcode-only method

**Error**: Signature verification fails on backend
- Check data encoding (Base64)
- Verify same data is signed and verified
- Check key format (X509 encoding)

### Backend

**Error**: InvalidKeySpecException
- Public key not in X509 format
- Check Base64 decoding
- Verify iOS exports key correctly

**Error**: SignatureException
- Data mismatch between sign and verify
- Check encoding consistency
- Verify algorithm names match

## Key Differences: .userPresence vs .devicePasscode

| Aspect | .userPresence | .devicePasscode |
|--------|---------------|-----------------|
| Biometric UI | Shows if available | Never shows |
| Passcode fallback | Automatic | Only option |
| Use case | User accepts biometrics | User declines biometrics |
| Flexibility | High | Low (intentional) |
| Future-proof | Yes (new biometric types) | Limited |

## Application Tags Convention

```swift
// Different tags for different keys
let biometricKeyTag = "com.yourapp.mfa.biometric".data(using: .utf8)!
let passcodeKeyTag = "com.yourapp.mfa.passcode".data(using: .utf8)!

// Store which tag is active
UserDefaults.standard.set("biometric", forKey: "active_key_tag")
```

## Clean Up Keys

```swift
func deleteKey(tag: Data) throws {
    let query: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrApplicationTag as String: tag
    ]
    
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
        throw KeychainError.deleteFailed(status)
    }
}
```

This quick reference should help you implement the critical parts without referring back to the full specification constantly.
