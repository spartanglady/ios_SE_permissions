import Foundation
import Combine

/// ViewModel for testing dashboard
@MainActor
class TestingViewModel: ObservableObject {

    @Published var deviceCapability: DeviceCapability = .none
    @Published var biometricType: String = "None"
    @Published var isPasscodeSet: Bool = false
    @Published var isSecureEnclaveAvailable: Bool = false
    @Published var isEnrolled: Bool = false
    @Published var currentMethod: String = "Not enrolled"
    @Published var testResults: [TestResult] = []

    private let biometricService = BiometricService()
    private let storage = MFAStorageService()

    init() {
        refreshStatus()
    }

    // MARK: - Status Refresh

    func refreshStatus() {
        deviceCapability = biometricService.checkDeviceCapabilities()
        biometricType = biometricService.getBiometricType()
        isPasscodeSet = biometricService.isPasscodeSet()
        isSecureEnclaveAvailable = MFAConfiguration.useSecureEnclave
        isEnrolled = storage.isEnrolled()

        if let method = storage.getAuthMethod() {
            currentMethod = method.rawValue
        } else {
            currentMethod = "Not enrolled"
        }
    }

    // MARK: - Test Actions

    func logResult(_ action: String, success: Bool, details: String) {
        let result = TestResult(
            action: action,
            success: success,
            details: details,
            timestamp: Date()
        )
        testResults.insert(result, at: 0)
    }

    func clearResults() {
        testResults.removeAll()
    }
}

// MARK: - Test Result Model

struct TestResult: Identifiable {
    let id = UUID()
    let action: String
    let success: Bool
    let details: String
    let timestamp: Date

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .short
        return formatter.string(from: timestamp)
    }
}
