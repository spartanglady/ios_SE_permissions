import Foundation

/// Local authentication method (biometric vs passcode)
enum AuthMethod: String, Codable {
    case biometric = "biometric"
    case passcode = "passcode"
}
