import SwiftUI

struct TestingDashboardView: View {
    @StateObject private var viewModel = TestingViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // Device Status Section
                    GroupBox("Device Status") {
                        VStack(alignment: .leading, spacing: 12) {
                            DeviceStatusItem(
                                icon: "cpu",
                                title: "Secure Enclave",
                                value: viewModel.isSecureEnclaveAvailable ? "Available" : "Not Available (Simulator)",
                                isPositive: viewModel.isSecureEnclaveAvailable
                            )

                            DeviceStatusItem(
                                icon: "faceid",
                                title: "Biometrics",
                                value: viewModel.biometricType,
                                isPositive: viewModel.biometricType != "None"
                            )

                            DeviceStatusItem(
                                icon: "lock",
                                title: "Passcode",
                                value: viewModel.isPasscodeSet ? "Set" : "Not Set",
                                isPositive: viewModel.isPasscodeSet
                            )

                            DeviceStatusItem(
                                icon: "checkmark.shield",
                                title: "Enrollment",
                                value: viewModel.isEnrolled ? "Enrolled" : "Not Enrolled",
                                isPositive: viewModel.isEnrolled
                            )

                            DeviceStatusItem(
                                icon: "key",
                                title: "Method",
                                value: viewModel.currentMethod,
                                isPositive: viewModel.isEnrolled
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Test Actions
                    GroupBox("Test Actions") {
                        VStack(spacing: 12) {
                            Button("Refresh Status") {
                                viewModel.refreshStatus()
                                viewModel.logResult("Status Refresh", success: true, details: "Device status refreshed")
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)

                            Button("Check Device Capabilities") {
                                viewModel.refreshStatus()
                                let details = """
                                Capability: \(viewModel.deviceCapability)
                                Biometric: \(viewModel.biometricType)
                                Passcode: \(viewModel.isPasscodeSet ? "Set" : "Not Set")
                                """
                                viewModel.logResult("Capability Check", success: true, details: details)
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)

                            Button("Clear Test Log") {
                                viewModel.clearResults()
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)

                    // Test Results Log
                    if !viewModel.testResults.isEmpty {
                        GroupBox("Test Results Log") {
                            VStack(spacing: 8) {
                                ForEach(viewModel.testResults) { result in
                                    TestResultRow(result: result)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Instructions
                    GroupBox("Testing Instructions") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Check device status above")
                            Text("2. Use Enrollment tab to enroll")
                            Text("3. Use Sign In tab to authenticate")
                            Text("4. Monitor test results here")
                            Text("5. Try different scenarios")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Testing Dashboard")
            .onAppear {
                viewModel.refreshStatus()
            }
        }
    }
}

struct DeviceStatusItem: View {
    let icon: String
    let title: String
    let value: String
    let isPositive: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isPositive ? .green : .orange)
                .frame(width: 24)

            Text(title)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .foregroundColor(isPositive ? .primary : .secondary)
        }
    }
}

struct TestResultRow: View {
    let result: TestResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)

                Text(result.action)
                    .font(.headline)

                Spacer()

                Text(result.formattedTimestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(result.details)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TestingDashboardView()
}
