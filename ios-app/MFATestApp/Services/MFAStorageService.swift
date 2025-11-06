import Foundation
import UIKit

/// Service for storing MFA-related data using UserDefaults
class MFAStorageService {

    private let defaults = UserDefaults.standard

    // Keys
    private let deviceIdKey = "mfa.deviceId"
    private let usernameKey = "mfa.username"
    private let methodKey = "mfa.method"
    private let authMethodKey = "mfa.authMethod"
    private let phoneNumberKey = "mfa.phoneNumber"
    private let enrolledKey = "mfa.enrolled"
    private let activeKeyTagKey = "mfa.activeKeyTag"

    // MARK: - Device ID

    func getOrCreateDeviceId() -> String {
        if let existingId = defaults.string(forKey: deviceIdKey) {
            return existingId
        }

        // Create new device ID using UUID and device name
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        defaults.set(deviceId, forKey: deviceIdKey)
        return deviceId
    }

    func getDeviceId() -> String? {
        return defaults.string(forKey: deviceIdKey)
    }

    // MARK: - Enrollment Status

    func saveEnrollment(username: String, method: AuthMethod, deviceId: String, phoneNumber: String? = nil) {
        defaults.set(username, forKey: usernameKey)
        defaults.set(method.rawValue, forKey: authMethodKey)
        defaults.set(deviceId, forKey: deviceIdKey)
        defaults.set(phoneNumber, forKey: phoneNumberKey)
        defaults.set(true, forKey: enrolledKey)
    }

    func isEnrolled() -> Bool {
        return defaults.bool(forKey: enrolledKey)
    }

    func getUsername() -> String? {
        return defaults.string(forKey: usernameKey)
    }

    func getAuthMethod() -> AuthMethod? {
        guard let methodString = defaults.string(forKey: authMethodKey) else {
            return nil
        }
        return AuthMethod(rawValue: methodString)
    }

    func getMFAMethod() -> MFAMethod? {
        guard let methodString = defaults.string(forKey: methodKey) else {
            return nil
        }
        return MFAMethod(rawValue: methodString)
    }

    func getPhoneNumber() -> String? {
        return defaults.string(forKey: phoneNumberKey)
    }

    // MARK: - Active Key Tag

    func setActiveKeyTag(_ tag: String) {
        defaults.set(tag, forKey: activeKeyTagKey)
    }

    func getActiveKeyTag() -> String? {
        return defaults.string(forKey: activeKeyTagKey)
    }

    // MARK: - Clear Data

    func clearEnrollment() {
        defaults.removeObject(forKey: usernameKey)
        defaults.removeObject(forKey: methodKey)
        defaults.removeObject(forKey: authMethodKey)
        defaults.removeObject(forKey: phoneNumberKey)
        defaults.removeObject(forKey: enrolledKey)
        defaults.removeObject(forKey: activeKeyTagKey)
        // Note: Don't clear deviceId as it should persist
    }

    func clearAll() {
        defaults.removeObject(forKey: deviceIdKey)
        defaults.removeObject(forKey: usernameKey)
        defaults.removeObject(forKey: methodKey)
        defaults.removeObject(forKey: authMethodKey)
        defaults.removeObject(forKey: phoneNumberKey)
        defaults.removeObject(forKey: enrolledKey)
        defaults.removeObject(forKey: activeKeyTagKey)
    }
}
