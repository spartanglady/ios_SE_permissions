import Foundation
import LocalAuthentication

/// ViewModel for handling authentication flow
@MainActor
class AuthenticationViewModel: ObservableObject {

    @Published var status: AuthenticationStatus = .idle
    @Published var errorMessage: String?
    @Published var otpInput: String = ""

    private let keychainService = KeychainService()
    private let biometricService = BiometricService()
    private let networkService = NetworkService()
    private let storage = MFAStorageService()

    // MARK: - Authentication with Secure Enclave

    func authenticateWithSecureEnclave(username: String) async {
        status = .requestingChallenge
        errorMessage = nil

        do {
            guard let deviceId = storage.getDeviceId() else {
                throw AuthError.notEnrolled
            }

            // Request challenge from server
            let challengeResponse = try await networkService.initiateAuthentication(
                username: username,
                deviceId: deviceId
            )

            guard let challengeBase64 = challengeResponse.challenge,
                  let challengeId = challengeResponse.challengeId else {
                // Server says use SMS OTP
                await authenticateWithOTP(username: username)
                return
            }

            guard let challengeData = Data(base64Encoded: challengeBase64) else {
                throw AuthError.invalidChallenge
            }

            // Retrieve private key
            status = .signing
            let (privateKey, _) = try keychainService.retrieveActiveKey()

            // Sign challenge (triggers biometric/passcode prompt)
            let context = biometricService.createContext(
                reason: "Sign in to your account",
                cancelTitle: "Cancel"
            )

            let signature = try keychainService.signData(challengeData, with: privateKey, context: context)
            let signatureBase64 = signature.base64EncodedString()

            // Verify signature with server
            status = .verifying
            let authResponse = try await networkService.verifySignature(
                username: username,
                deviceId: deviceId,
                challengeId: challengeId,
                signature: signatureBase64
            )

            if authResponse.success, let token = authResponse.token {
                status = .success(token)
            } else {
                throw AuthError.verificationFailed(authResponse.message)
            }

        } catch let error as LAError {
            if biometricService.isUserCancellation(error) {
                status = .idle
                errorMessage = "Authentication cancelled"
            } else {
                status = .failed(biometricService.getErrorMessage(from: error))
                errorMessage = biometricService.getErrorMessage(from: error)
            }
        } catch {
            status = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Authentication with OTP

    func authenticateWithOTP(username: String) async {
        status = .requestingOTP
        errorMessage = nil

        do {
            guard let phoneNumber = storage.getPhoneNumber() else {
                throw AuthError.noPhoneNumber
            }

            // Request OTP from server
            let response = try await networkService.requestOTP(
                username: username,
                phoneNumber: phoneNumber
            )

            guard response.success else {
                throw AuthError.otpRequestFailed(response.message)
            }

            status = .verifyingOTP

        } catch {
            status = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    func verifyOTP(username: String, otp: String) async {
        status = .verifying
        errorMessage = nil

        do {
            let response = try await networkService.verifyOTP(username: username, otp: otp)

            if response.success, let token = response.token {
                status = .success(token)
            } else {
                throw AuthError.otpVerificationFailed(response.message)
            }

        } catch {
            status = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    func reset() {
        status = .idle
        errorMessage = nil
        otpInput = ""
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case notEnrolled
    case invalidChallenge
    case verificationFailed(String)
    case noPhoneNumber
    case otpRequestFailed(String)
    case otpVerificationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notEnrolled:
            return "Device not enrolled"
        case .invalidChallenge:
            return "Invalid challenge received from server"
        case .verificationFailed(let message):
            return "Verification failed: \(message)"
        case .noPhoneNumber:
            return "No phone number on file"
        case .otpRequestFailed(let message):
            return "OTP request failed: \(message)"
        case .otpVerificationFailed(let message):
            return "OTP verification failed: \(message)"
        }
    }
}
