import Foundation
import Security

/// Represents a key pair (public and private key)
struct KeyPair {
    let privateKey: SecKey
    let publicKey: SecKey

    /// Export public key as Data
    func getPublicKeyData() -> Data? {
        var error: Unmanaged<CFError>?
        guard let keyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            return nil
        }
        return keyData
    }

    /// Export public key as Base64 string
    func getPublicKeyBase64() -> String? {
        guard let keyData = getPublicKeyData() else {
            return nil
        }
        return keyData.base64EncodedString()
    }
}
