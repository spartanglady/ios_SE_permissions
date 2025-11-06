import Foundation
import LocalAuthentication

/// Service for managing biometric authentication
class BiometricService {

    // MARK: - Device Capability Checking

    /// Check what authentication capabilities the device has
    func checkDeviceCapabilities() -> DeviceCapability {
        let context = LAContext()
        var error: NSError?

        // Check if biometrics are available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return .biometricsAvailable
        }

        // Check if at least passcode is available
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            return .passcodeOnly
        }

        // No authentication available
        return .none
    }

    /// Get the type of biometric authentication available
    func getBiometricType() -> String {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "None"
        }

        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "None"
        @unknown default:
            return "Unknown"
        }
    }

    /// Check if biometrics are available
    func isBiometricsAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Check if passcode is set
    func isPasscodeSet() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    // MARK: - Authentication

    /// Create LAContext with custom messages
    func createContext(reason: String, cancelTitle: String? = nil) -> LAContext {
        let context = LAContext()
        context.localizedReason = reason

        if let cancelTitle = cancelTitle {
            context.localizedCancelTitle = cancelTitle
        }

        return context
    }

    /// Evaluate authentication policy
    func authenticate(reason: String, cancelTitle: String? = nil) async throws -> Bool {
        let context = createContext(reason: reason, cancelTitle: cancelTitle)

        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    // MARK: - Error Handling

    /// Convert LAError to user-friendly message
    func getErrorMessage(from error: Error) -> String {
        guard let laError = error as? LAError else {
            return error.localizedDescription
        }

        switch laError.code {
        case .userCancel:
            return "Authentication cancelled by user"
        case .biometryNotAvailable:
            return "Biometric authentication not available"
        case .biometryNotEnrolled:
            return "No biometric authentication enrolled"
        case .passcodeNotSet:
            return "Device passcode not set"
        case .biometryLockout:
            return "Biometric authentication locked due to too many failed attempts"
        case .authenticationFailed:
            return "Authentication failed - please try again"
        case .systemCancel:
            return "Authentication cancelled by system"
        case .appCancel:
            return "Authentication cancelled by app"
        case .invalidContext:
            return "Invalid authentication context"
        case .notInteractive:
            return "Authentication not interactive"
        case .watchNotAvailable:
            return "Apple Watch not available"
        case .userFallback:
            return "User chose to enter password"
        default:
            return "Authentication error: \(laError.localizedDescription)"
        }
    }

    /// Check if error is user cancellation
    func isUserCancellation(_ error: Error) -> Bool {
        guard let laError = error as? LAError else {
            return false
        }
        return laError.code == .userCancel
    }

    /// Check if error is biometry not available
    func isBiometryNotAvailable(_ error: Error) -> Bool {
        guard let laError = error as? LAError else {
            return false
        }
        return laError.code == .biometryNotAvailable || laError.code == .biometryNotEnrolled
    }

    /// Check if error is passcode not set
    func isPasscodeNotSet(_ error: Error) -> Bool {
        guard let laError = error as? LAError else {
            return false
        }
        return laError.code == .passcodeNotSet
    }
}
