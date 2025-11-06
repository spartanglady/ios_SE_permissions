# MFA Test App - iOS Application

iOS application for testing Multi-Factor Authentication with Secure Enclave integration.

## Features

- Secure Enclave key pair generation (P-256 ECDSA)
- Biometric authentication (Face ID/Touch ID)
- Passcode-only authentication
- Challenge-response authentication
- SMS OTP fallback
- Comprehensive testing dashboard
- Support for all MFA scenarios

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.9+
- A Mac for development

## Project Structure

```
MFATestApp/
├── Models/
│   ├── MFAMethod.swift          # Enums for MFA methods
│   ├── AuthMethod.swift
│   ├── DeviceCapability.swift
│   ├── KeyPair.swift
│   └── DTOs.swift               # Request/Response models
├── Services/
│   ├── MFAConfiguration.swift   # App configuration
│   ├── KeychainService.swift    # Secure Enclave operations
│   ├── BiometricService.swift   # LocalAuthentication wrapper
│   ├── NetworkService.swift     # API communication
│   └── MFAStorageService.swift  # Local data persistence
├── ViewModels/
│   ├── EnrollmentViewModel.swift
│   ├── AuthenticationViewModel.swift
│   └── TestingViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── EnrollmentView.swift
│   ├── AuthenticationView.swift
│   └── TestingDashboardView.swift
├── Resources/
│   └── Info.plist
└── MFATestAppApp.swift          # App entry point
```

## Setup Instructions

### 1. Prerequisites

Ensure the backend is running:
```bash
cd ../backend
mvn spring-boot:run
```

### 2. Configure Backend URL

Edit `Services/MFAConfiguration.swift`:

For **Simulator**:
```swift
static let baseURL = "http://localhost:8080/api/v1"
```

For **Real Device**:
```swift
// Use your Mac's IP address
static let baseURL = "http://192.168.1.XXX:8080/api/v1"
```

To find your Mac's IP:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

### 3. Open in Xcode

```bash
cd ios-app
open MFATestApp.xcodeproj  # If project file exists
```

If the xcodeproj doesn't exist, create a new iOS project in Xcode:
1. File > New > Project
2. iOS > App
3. Product Name: MFATestApp
4. Interface: SwiftUI
5. Language: Swift
6. Copy all source files into the project

### 4. Configure Signing

1. Select project in Xcode
2. Select target "MFATestApp"
3. Signing & Capabilities tab
4. Team: Select your development team
5. Bundle Identifier: Set unique identifier

### 5. Run on Simulator

1. Select iPhone simulator (iOS 15.0+)
2. Press Cmd+R to build and run
3. Enable Face ID: Features > Face ID > Enrolled

### 6. Run on Real Device

1. Connect iPhone via USB
2. Trust computer on device
3. Ensure device has passcode/Face ID set
4. Select device in Xcode
5. Press Cmd+R to build and run

## Usage Guide

### Enrollment Flow

1. **Launch app** → Opens on Enrollment tab
2. **Enter credentials:**
   - Username: `testuser`
   - Phone: `+1234567890`
3. **Choose enrollment method:**
   - **Face ID/Touch ID**: Uses biometrics with passcode fallback
   - **Passcode Only**: Uses only device passcode
   - **SMS Only**: No Secure Enclave (for devices without security)
4. **Complete authentication prompt**
5. **Success!** Device is enrolled

### Authentication Flow

1. **Switch to Sign In tab**
2. **Enter username:** `testuser`
3. **Tap "Sign In"**
4. **Authenticate** with Face ID/passcode
5. **Success!** Token received

### SMS OTP Flow

1. **Sign In tab**
2. **Tap "Use SMS OTP Instead"**
3. **Check backend console** for OTP code
4. **Enter OTP** in app
5. **Tap "Verify OTP"**
6. **Success!**

### Testing Dashboard

The Testing tab shows:
- ✅ Secure Enclave availability
- ✅ Biometric type (Face ID/Touch ID)
- ✅ Passcode status
- ✅ Current enrollment status
- ✅ Test action buttons
- ✅ Test results log

## Key Features

### Secure Enclave Integration

```swift
// Creates key in Secure Enclave (real device only)
let keyPair = try keychainService.createKeyWithBiometrics()

// On simulator, falls back to regular keychain
#if targetEnvironment(simulator)
// Uses regular keychain
#else
// Uses Secure Enclave
#endif
```

### Biometric vs Passcode

**Biometric Preferred** (.userPresence):
- Shows Face ID/Touch ID first
- Falls back to passcode automatically
- User can cancel and use passcode

**Passcode Only** (.devicePasscode):
- Never shows biometric prompt
- Only uses device passcode
- Intentional user choice

### Error Handling

The app handles all LocalAuthentication errors:
- `userCancel` → Offer passcode fallback
- `biometryNotAvailable` → Auto-switch to passcode
- `passcodeNotSet` → Show warning, offer SMS
- `biometryLockout` → Use passcode
- `authenticationFailed` → Allow retry

## Testing Scenarios

### Scenario 1: Happy Path (Biometric)
1. Device has Face ID
2. Enroll with Face ID
3. Authenticate with Face ID
4. ✅ Success

### Scenario 2: User Declines Biometrics
1. Enroll with Face ID
2. Tap "Don't Allow" on system prompt
3. App offers passcode fallback
4. Accept → Enrolls with passcode
5. ✅ Success

### Scenario 3: No Biometrics Available
1. Disable Face ID in Settings
2. Only passcode option shown
3. Enroll with passcode
4. ✅ Success

### Scenario 4: SMS Fallback
1. Remove all device security
2. SMS Only option shown
3. Enroll with SMS
4. Check backend logs for OTP
5. ✅ Success

### Scenario 5: Security Removed After Enrollment
1. Enroll with Face ID
2. Go to Settings → Disable passcode
3. Return to app
4. App detects no security
5. Auto-downgrades to SMS
6. ✅ Graceful fallback

## Simulator vs Real Device

| Feature | Simulator | Real Device |
|---------|-----------|-------------|
| Secure Enclave | ❌ Regular keychain | ✅ True Secure Enclave |
| Face ID | ✅ Simulated | ✅ Real biometrics |
| Touch ID | ✅ Simulated | ✅ Real biometrics |
| Passcode | ✅ Works | ✅ Works |
| Key Security | Regular | Hardware-backed |
| Testing | Fast iteration | True security test |

## Troubleshooting

### Can't Connect to Backend

**Simulator:**
- Backend running? Check `http://localhost:8080`
- curl test: `curl http://localhost:8080/api/v1/devices/testuser`

**Real Device:**
- Using Mac's IP address (not localhost)?
- Same WiFi network?
- Firewall blocking port 8080?

### Key Creation Fails

**Error: `errSecItemNotFound`**
- Ensure device passcode is set
- Check Info.plist has NSFaceIDUsageDescription
- On simulator: Remove `kSecAttrTokenIDSecureEnclave`

**Error: Access control failed**
- Device security not set up
- Try passcode-only method first

### Signature Verification Fails

1. Check challenge data encoding (Base64)
2. Verify same data signed and verified
3. Check backend logs for details
4. Try re-enrolling device

### Face ID Not Working in Simulator

1. Menu: Features > Face ID > Enrolled
2. During test: Features > Face ID > Matching Face
3. To fail: Features > Face ID > Non-matching Face

## Code Examples

### Create Key with Biometrics

```swift
let keychainService = KeychainService()
let keyPair = try keychainService.createKeyWithBiometrics()

// Test key (triggers Face ID)
let context = LAContext()
context.localizedReason = "Authenticate to enroll"
let testData = Data("test".utf8)
let signature = try keychainService.signData(testData, with: keyPair.privateKey, context: context)
```

### Sign Challenge

```swift
// Get challenge from server
let challengeResponse = try await networkService.initiateAuthentication(username: username, deviceId: deviceId)
let challengeData = Data(base64Encoded: challengeResponse.challenge)!

// Sign with private key
let (privateKey, _) = try keychainService.retrieveActiveKey()
let signature = try keychainService.signData(challengeData, with: privateKey)
```

### Check Device Capabilities

```swift
let biometricService = BiometricService()
let capability = biometricService.checkDeviceCapabilities()

switch capability {
case .biometricsAvailable:
    print("Face ID or Touch ID available")
case .passcodeOnly:
    print("Only passcode available")
case .none:
    print("No device security")
}
```

## Important Notes

### For Real Device Testing

1. **Secure Enclave keys cannot be exported**
   - Private keys never leave the device
   - Cannot be backed up
   - Deleted if device is reset

2. **Biometric changes**
   - Adding new Face ID scan requires re-enrollment
   - Removing biometrics downgrades to passcode

3. **App deletion**
   - Keychain items may persist
   - Use "Reset" option before reinstalling

### Security Considerations

- Private keys never transmitted
- Challenge used only once
- 5-minute expiration on challenges
- Base64 encoding for all transfers
- HTTPS recommended for production

## Production Checklist

Before production use:

- [ ] Use real SMS service (not mock)
- [ ] Implement proper session management
- [ ] Add certificate pinning
- [ ] Implement jailbreak detection
- [ ] Add comprehensive error logging
- [ ] Use HTTPS for all network calls
- [ ] Implement backup codes
- [ ] Add account recovery flow
- [ ] Comprehensive testing on all devices
- [ ] Security audit

## Resources

- [Apple LocalAuthentication Documentation](https://developer.apple.com/documentation/localauthentication)
- [Secure Enclave Overview](https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys/protecting_keys_with_the_secure_enclave)
- [FIDO Alliance Guidelines](https://fidoalliance.org)

## Support

For issues or questions:
1. Check TESTING_CHECKLIST.md for expected behavior
2. Review QUICK_REFERENCE.md for code examples
3. Check backend logs for server-side errors
4. Review Xcode console for client-side errors

## License

This is a reference implementation for learning and testing purposes.
