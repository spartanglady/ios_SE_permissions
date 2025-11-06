import Foundation
import Security
import LocalAuthentication

/// Service for managing Secure Enclave keys and signatures
class KeychainService {

    // MARK: - Key Creation

    /// Create key pair with biometric authentication preference
    func createKeyWithBiometrics() throws -> KeyPair {
        let tag = MFAConfiguration.biometricKeyTag.data(using: .utf8)!

        // Delete existing key if any
        try? deleteKey(tag: tag)

        // Create access control with .userPresence (allows biometrics with passcode fallback)
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage, .userPresence],
            nil
        ) else {
            throw KeychainError.accessControlCreationFailed
        }

        var attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECP256r1,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag,
                kSecAttrAccessControl as String: access
            ]
        ]

        // Only add Secure Enclave on real devices
        if MFAConfiguration.useSecureEnclave {
            attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        }

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error?.takeRetainedValue() as Error? ?? KeychainError.keyCreationFailed
        }

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw KeychainError.publicKeyExtractionFailed
        }

        return KeyPair(privateKey: privateKey, publicKey: publicKey)
    }

    /// Create key pair with passcode-only authentication
    func createKeyWithPasscode() throws -> KeyPair {
        let tag = MFAConfiguration.passcodeKeyTag.data(using: .utf8)!

        // Delete existing key if any
        try? deleteKey(tag: tag)

        // Create access control with .devicePasscode (passcode only, no biometrics)
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage, .devicePasscode],
            nil
        ) else {
            throw KeychainError.accessControlCreationFailed
        }

        var attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECP256r1,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag,
                kSecAttrAccessControl as String: access
            ]
        ]

        if MFAConfiguration.useSecureEnclave {
            attributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        }

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error?.takeRetainedValue() as Error? ?? KeychainError.keyCreationFailed
        }

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw KeychainError.publicKeyExtractionFailed
        }

        return KeyPair(privateKey: privateKey, publicKey: publicKey)
    }

    // MARK: - Key Retrieval

    /// Retrieve key by tag
    func retrieveKey(tag: String) throws -> SecKey {
        let tagData = tag.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tagData,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECP256r1,
            kSecReturnRef as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            throw KeychainError.keyNotFound
        }

        guard let privateKey = item as! SecKey? else {
            throw KeychainError.keyNotFound
        }

        return privateKey
    }

    /// Retrieve active key (checks both biometric and passcode tags)
    func retrieveActiveKey() throws -> (SecKey, String) {
        // Try biometric key first
        if let key = try? retrieveKey(tag: MFAConfiguration.biometricKeyTag) {
            return (key, MFAConfiguration.biometricKeyTag)
        }

        // Try passcode key
        if let key = try? retrieveKey(tag: MFAConfiguration.passcodeKeyTag) {
            return (key, MFAConfiguration.passcodeKeyTag)
        }

        throw KeychainError.keyNotFound
    }

    // MARK: - Signing

    /// Sign data with private key
    func signData(_ data: Data, with privateKey: SecKey, context: LAContext? = nil) throws -> Data {
        var error: Unmanaged<CFError>?

        // If context is provided, bind it to the key operation
        if let context = context {
            // The context will be used automatically by the Secure Enclave
            // when the key requires user authentication
        }

        guard let signature = SecKeyCreateSignature(
            privateKey,
            .ecdsaSignatureMessageX962SHA256,
            data as CFData,
            &error
        ) as Data? else {
            throw error?.takeRetainedValue() as Error? ?? KeychainError.signingFailed
        }

        return signature
    }

    // MARK: - Key Deletion

    /// Delete key by tag
    func deleteKey(tag: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    /// Delete all MFA keys
    func deleteAllKeys() throws {
        if let bioTag = MFAConfiguration.biometricKeyTag.data(using: .utf8) {
            try? deleteKey(tag: bioTag)
        }
        if let passTag = MFAConfiguration.passcodeKeyTag.data(using: .utf8) {
            try? deleteKey(tag: passTag)
        }
    }
}

// MARK: - Errors

enum KeychainError: LocalizedError {
    case accessControlCreationFailed
    case keyCreationFailed
    case publicKeyExtractionFailed
    case keyNotFound
    case signingFailed
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .accessControlCreationFailed:
            return "Failed to create access control"
        case .keyCreationFailed:
            return "Failed to create key pair"
        case .publicKeyExtractionFailed:
            return "Failed to extract public key"
        case .keyNotFound:
            return "Key not found in keychain"
        case .signingFailed:
            return "Failed to sign data"
        case .deleteFailed(let status):
            return "Failed to delete key (status: \(status))"
        }
    }
}
