import Foundation

/// MFA authentication method
enum MFAMethod: String, Codable {
    case secureEnclave = "secureEnclave"
    case smsOTP = "smsOTP"
}
