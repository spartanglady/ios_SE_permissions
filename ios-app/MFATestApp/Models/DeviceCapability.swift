import Foundation

/// Device security capabilities
enum DeviceCapability {
    case biometricsAvailable      // Face ID or Touch ID available
    case passcodeOnly             // Only passcode available
    case none                     // No device security set up
}
