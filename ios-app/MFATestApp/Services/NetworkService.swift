import Foundation

/// Service for making network requests to the backend API
class NetworkService {

    private let baseURL = MFAConfiguration.baseURL
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = MFAConfiguration.timeout
        self.session = URLSession(configuration: config)
    }

    // MARK: - Enrollment

    func enroll(
        username: String,
        phoneNumber: String?,
        publicKey: String?,
        method: MFAMethod,
        deviceId: String,
        deviceModel: String?
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
            deviceId: deviceId,
            deviceModel: deviceModel
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        return try JSONDecoder().decode(EnrollmentResponse.self, from: data)
    }

    func unenroll(username: String, deviceId: String) async throws -> EnrollmentResponse {
        let url = URL(string: "\(baseURL)/mfa/unenroll")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = UnenrollRequest(username: username, deviceId: deviceId)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        return try JSONDecoder().decode(EnrollmentResponse.self, from: data)
    }

    func upgrade(username: String, deviceId: String, publicKey: String) async throws -> EnrollmentResponse {
        let url = URL(string: "\(baseURL)/mfa/upgrade")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = EnrollmentRequest(
            username: username,
            phoneNumber: nil,
            publicKey: publicKey,
            method: "secureEnclave",
            deviceId: deviceId,
            deviceModel: nil
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        return try JSONDecoder().decode(EnrollmentResponse.self, from: data)
    }

    func downgrade(username: String, deviceId: String) async throws -> EnrollmentResponse {
        let url = URL(string: "\(baseURL)/mfa/downgrade")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = UnenrollRequest(username: username, deviceId: deviceId)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        return try JSONDecoder().decode(EnrollmentResponse.self, from: data)
    }

    // MARK: - Authentication

    func initiateAuthentication(username: String, deviceId: String) async throws -> ChallengeResponse {
        let url = URL(string: "\(baseURL)/auth/initiate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = AuthInitiateRequest(username: username, deviceId: deviceId)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

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

        let body = VerifySignatureRequest(
            username: username,
            deviceId: deviceId,
            challengeId: challengeId,
            signature: signature
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func requestOTP(username: String, phoneNumber: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/request-otp")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = OTPRequest(username: username, phoneNumber: phoneNumber, otp: nil)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func verifyOTP(username: String, otp: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/verify-otp")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = OTPRequest(username: username, phoneNumber: nil, otp: otp)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    // MARK: - Device Management

    func getDeviceStatus(deviceId: String) async throws -> DeviceStatusResponse {
        let url = URL(string: "\(baseURL)/device/\(deviceId)/status")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        return try JSONDecoder().decode(DeviceStatusResponse.self, from: data)
    }

    func getUserDevices(username: String) async throws -> [DeviceStatusResponse] {
        let url = URL(string: "\(baseURL)/devices/\(username)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        return try JSONDecoder().decode([DeviceStatusResponse].self, from: data)
    }
}

// MARK: - Errors

enum NetworkError: LocalizedError {
    case invalidResponse
    case decodingError
    case networkFailure

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode server response"
        case .networkFailure:
            return "Network request failed"
        }
    }
}
