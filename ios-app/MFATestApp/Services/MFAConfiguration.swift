import Foundation

/// Configuration for MFA application
struct MFAConfiguration {

    /// Whether to use Secure Enclave (real device) or regular keychain (simulator)
    static var useSecureEnclave: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }

    /// Base URL for the backend API
    /// For simulator: use localhost
    /// For real device: use Mac's IP address (e.g., "http://192.168.1.100:8080/api/v1")
    static let baseURL = "http://localhost:8080/api/v1"

    /// Network request timeout
    static let timeout: TimeInterval = 30

    /// Application tags for keychain
    static let biometricKeyTag = "com.example.mfa.biometric"
    static let passcodeKeyTag = "com.example.mfa.passcode"
}
