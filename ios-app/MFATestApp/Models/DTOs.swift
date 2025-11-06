import Foundation

// MARK: - Enrollment DTOs

struct EnrollmentRequest: Codable {
    let username: String
    let phoneNumber: String?
    let publicKey: String?
    let method: String
    let deviceId: String
    let deviceModel: String?
}

struct EnrollmentResponse: Codable {
    let success: Bool
    let deviceId: String?
    let method: String?
    let message: String
}

struct UnenrollRequest: Codable {
    let username: String
    let deviceId: String
}

// MARK: - Authentication DTOs

struct AuthInitiateRequest: Codable {
    let username: String
    let deviceId: String
}

struct ChallengeResponse: Codable {
    let method: String
    let challenge: String?
    let challengeId: String?
    let expiresIn: Int
}

struct VerifySignatureRequest: Codable {
    let username: String
    let deviceId: String
    let challengeId: String
    let signature: String
}

struct AuthResponse: Codable {
    let success: Bool
    let token: String?
    let message: String
}

struct OTPRequest: Codable {
    let username: String
    let phoneNumber: String?
    let otp: String?
}

// MARK: - Device DTOs

struct DeviceStatusResponse: Codable {
    let deviceId: String
    let enrolled: Bool
    let method: String?
    let hasPublicKey: Bool
    let phoneNumber: String?
    let enrolledAt: String?
    let lastUsed: String?
}

// MARK: - Enrollment Status

enum EnrollmentStatus {
    case notStarted
    case creatingKey
    case testingKey
    case registering
    case success
    case failed(String)
    case offerPasscodeFallback
}

// MARK: - Authentication Status

enum AuthenticationStatus {
    case idle
    case requestingChallenge
    case signing
    case verifying
    case requestingOTP
    case verifyingOTP
    case success(String)  // token
    case failed(String)
}
