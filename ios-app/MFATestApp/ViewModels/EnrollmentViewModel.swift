import Foundation
import LocalAuthentication
import Combine

/// ViewModel for handling enrollment flow
@MainActor
class EnrollmentViewModel: ObservableObject {

    @Published var status: EnrollmentStatus = .notStarted
    @Published var errorMessage: String?
    @Published var deviceCapability: DeviceCapability = .none

    private let keychainService = KeychainService()
    private let biometricService = BiometricService()
    private let networkService = NetworkService()
    private let storage = MFAStorageService()

    init() {
        checkDeviceCapabilities()
    }

    // MARK: - Device Capability

    func checkDeviceCapabilities() {
        deviceCapability = biometricService.checkDeviceCapabilities()
    }

    // MARK: - Enrollment

    func enrollWithBiometrics(username: String, phoneNumber: String) async {
        status = .creatingKey
        errorMessage = nil

        do {
            // Create key with biometric preference
            let keyPair = try keychainService.createKeyWithBiometrics()

            // Test key (triggers biometric prompt)
            status = .testingKey
            let context = biometricService.createContext(
                reason: "Enable biometric authentication",
                cancelTitle: "Use Passcode Instead"
            )

            let testData = Data("enrollment_test".utf8)
            let _ = try keychainService.signData(testData, with: keyPair.privateKey, context: context)

            // Export public key
            guard let publicKeyBase64 = keyPair.getPublicKeyBase64() else {
                throw EnrollmentError.publicKeyExportFailed
            }

            // Register with server
            status = .registering
            let deviceId = storage.getOrCreateDeviceId()
            let deviceModel = await UIDevice.current.model

            let response = try await networkService.enroll(
                username: username,
                phoneNumber: phoneNumber,
                publicKey: publicKeyBase64,
                method: .secureEnclave,
                deviceId: deviceId,
                deviceModel: deviceModel
            )

            guard response.success else {
                throw EnrollmentError.serverRegistrationFailed(response.message)
            }

            // Save enrollment locally
            storage.saveEnrollment(
                username: username,
                method: .biometric,
                deviceId: deviceId,
                phoneNumber: phoneNumber
            )
            storage.setActiveKeyTag(MFAConfiguration.biometricKeyTag)

            status = .success

        } catch let error as LAError {
            handleLAError(error, username: username, phoneNumber: phoneNumber)
        } catch {
            status = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    func enrollWithPasscode(username: String, phoneNumber: String) async {
        status = .creatingKey
        errorMessage = nil

        do {
            // Create key with passcode only
            let keyPair = try keychainService.createKeyWithPasscode()

            // Test key (triggers passcode prompt)
            status = .testingKey
            let context = LAContext()
            context.localizedReason = "Enable passcode authentication"

            let testData = Data("enrollment_test".utf8)
            let _ = try keychainService.signData(testData, with: keyPair.privateKey, context: context)

            // Export public key
            guard let publicKeyBase64 = keyPair.getPublicKeyBase64() else {
                throw EnrollmentError.publicKeyExportFailed
            }

            // Register with server
            status = .registering
            let deviceId = storage.getOrCreateDeviceId()
            let deviceModel = await UIDevice.current.model

            let response = try await networkService.enroll(
                username: username,
                phoneNumber: phoneNumber,
                publicKey: publicKeyBase64,
                method: .secureEnclave,
                deviceId: deviceId,
                deviceModel: deviceModel
            )

            guard response.success else {
                throw EnrollmentError.serverRegistrationFailed(response.message)
            }

            // Save enrollment locally
            storage.saveEnrollment(
                username: username,
                method: .passcode,
                deviceId: deviceId,
                phoneNumber: phoneNumber
            )
            storage.setActiveKeyTag(MFAConfiguration.passcodeKeyTag)

            status = .success

        } catch {
            status = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    func enrollWithSMSOnly(username: String, phoneNumber: String) async {
        status = .registering
        errorMessage = nil

        do {
            let deviceId = storage.getOrCreateDeviceId()
            let deviceModel = await UIDevice.current.model

            let response = try await networkService.enroll(
                username: username,
                phoneNumber: phoneNumber,
                publicKey: nil,
                method: .smsOTP,
                deviceId: deviceId,
                deviceModel: deviceModel
            )

            guard response.success else {
                throw EnrollmentError.serverRegistrationFailed(response.message)
            }

            // Save enrollment locally (no key created)
            storage.saveEnrollment(
                username: username,
                method: .biometric,  // This doesn't really matter for SMS-only
                deviceId: deviceId,
                phoneNumber: phoneNumber
            )

            status = .success

        } catch {
            status = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Unenrollment

    func unenroll() async {
        errorMessage = nil

        do {
            guard let username = storage.getUsername(),
                  let deviceId = storage.getDeviceId() else {
                throw EnrollmentError.notEnrolled
            }

            // Unenroll from server
            let response = try await networkService.unenroll(username: username, deviceId: deviceId)

            guard response.success else {
                throw EnrollmentError.serverError(response.message)
            }

            // Delete local keys
            try? keychainService.deleteAllKeys()

            // Clear local storage
            storage.clearEnrollment()

            status = .notStarted

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Error Handling

    private func handleLAError(_ error: LAError, username: String, phoneNumber: String) {
        switch error.code {
        case .userCancel:
            // Offer passcode fallback
            status = .offerPasscodeFallback
            errorMessage = "Biometric authentication cancelled. You can use passcode instead."

        case .biometryNotAvailable, .biometryNotEnrolled:
            // Auto-switch to passcode
            Task {
                await enrollWithPasscode(username: username, phoneNumber: phoneNumber)
            }

        case .passcodeNotSet:
            status = .failed("Please set up device security (passcode) first")
            errorMessage = "Device passcode must be set to use MFA"

        default:
            status = .failed(biometricService.getErrorMessage(from: error))
            errorMessage = biometricService.getErrorMessage(from: error)
        }
    }

    func acceptPasscodeFallback(username: String, phoneNumber: String) {
        Task {
            await enrollWithPasscode(username: username, phoneNumber: phoneNumber)
        }
    }
}

// MARK: - Errors

enum EnrollmentError: LocalizedError {
    case publicKeyExportFailed
    case serverRegistrationFailed(String)
    case serverError(String)
    case notEnrolled

    var errorDescription: String? {
        switch self {
        case .publicKeyExportFailed:
            return "Failed to export public key"
        case .serverRegistrationFailed(let message):
            return "Server registration failed: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .notEnrolled:
            return "Device not enrolled"
        }
    }
}
