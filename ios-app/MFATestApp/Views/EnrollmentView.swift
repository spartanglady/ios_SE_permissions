import SwiftUI

struct EnrollmentView: View {
    @StateObject private var viewModel = EnrollmentViewModel()
    @StateObject private var storage = MFAStorageService()

    @State private var username: String = ""
    @State private var phoneNumber: String = "+1234567890"
    @State private var showingUnenrollConfirmation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Multi-Factor Authentication")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Enroll your device for secure authentication")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                    // Device Status
                    GroupBox("Device Status") {
                        VStack(alignment: .leading, spacing: 8) {
                            StatusRow(title: "Secure Enclave", value: MFAConfiguration.useSecureEnclave ? "Available" : "Not Available")
                            StatusRow(title: "Biometrics", value: viewModel.deviceCapability == .biometricsAvailable ? "Available" : "Not Available")
                            StatusRow(title: "Passcode", value: viewModel.deviceCapability != .none ? "Set" : "Not Set")
                            StatusRow(title: "Enrollment", value: storage.isEnrolled() ? "Enrolled" : "Not Enrolled")
                        }
                    }
                    .padding(.horizontal)

                    if !storage.isEnrolled() {
                        // Enrollment Form
                        GroupBox("Enrollment") {
                            VStack(spacing: 16) {
                                TextField("Username", text: $username)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.username)
                                    .autocapitalization(.none)

                                TextField("Phone Number", text: $phoneNumber)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.telephoneNumber)
                                    .keyboardType(.phonePad)

                                // Enrollment Options
                                if viewModel.deviceCapability == .biometricsAvailable {
                                    Button("Enroll with Face ID/Touch ID") {
                                        Task {
                                            await viewModel.enrollWithBiometrics(
                                                username: username,
                                                phoneNumber: phoneNumber
                                            )
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(username.isEmpty)

                                    Button("Enroll with Passcode Only") {
                                        Task {
                                            await viewModel.enrollWithPasscode(
                                                username: username,
                                                phoneNumber: phoneNumber
                                            )
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(username.isEmpty)
                                } else if viewModel.deviceCapability == .passcodeOnly {
                                    Button("Enroll with Passcode") {
                                        Task {
                                            await viewModel.enrollWithPasscode(
                                                username: username,
                                                phoneNumber: phoneNumber
                                            )
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(username.isEmpty)
                                } else {
                                    Text("⚠️ Please set up device security")
                                        .font(.caption)
                                        .foregroundColor(.orange)

                                    Button("Enroll with SMS Only") {
                                        Task {
                                            await viewModel.enrollWithSMSOnly(
                                                username: username,
                                                phoneNumber: phoneNumber
                                            )
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(username.isEmpty || phoneNumber.isEmpty)
                                }
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // Enrolled Status
                        GroupBox("Enrollment Info") {
                            VStack(alignment: .leading, spacing: 8) {
                                if let enrolledUsername = storage.getUsername() {
                                    StatusRow(title: "Username", value: enrolledUsername)
                                }
                                if let method = storage.getAuthMethod() {
                                    StatusRow(title: "Method", value: method.rawValue)
                                }
                                if let phone = storage.getPhoneNumber() {
                                    StatusRow(title: "Phone", value: phone)
                                }
                            }
                        }
                        .padding(.horizontal)

                        Button("Unenroll Device") {
                            showingUnenrollConfirmation = true
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .padding(.horizontal)
                    }

                    // Status Messages
                    if case .success = viewModel.status {
                        Text("✅ Enrollment successful!")
                            .foregroundColor(.green)
                            .padding()
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .multilineTextAlignment(.center)
                    }

                    if case .offerPasscodeFallback = viewModel.status {
                        VStack {
                            Text("Use passcode instead?")
                                .font(.headline)
                            Button("Yes, use passcode") {
                                viewModel.acceptPasscodeFallback(
                                    username: username,
                                    phoneNumber: phoneNumber
                                )
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Enrollment")
            .confirmationDialog("Unenroll Device", isPresented: $showingUnenrollConfirmation) {
                Button("Unenroll", role: .destructive) {
                    Task {
                        await viewModel.unenroll()
                    }
                }
            } message: {
                Text("Are you sure you want to unenroll this device?")
            }
        }
    }
}

struct StatusRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    EnrollmentView()
}
