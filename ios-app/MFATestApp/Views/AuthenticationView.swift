import SwiftUI

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @StateObject private var storage = MFAStorageService()

    @State private var username: String = ""
    @State private var otpInput: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // Header
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding()

                    Text("Sign In")
                        .font(.title)
                        .fontWeight(.bold)

                    // Check enrollment
                    if !storage.isEnrolled() {
                        Text("⚠️ Please enroll your device first")
                            .foregroundColor(.orange)
                            .padding()
                    } else {
                        // Authentication Form
                        VStack(spacing: 16) {
                            TextField("Username", text: $username)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .padding(.horizontal)

                            // Show OTP input if status is verifying OTP
                            if case .verifyingOTP = viewModel.status {
                                TextField("Enter OTP", text: $otpInput)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                    .padding(.horizontal)

                                Button("Verify OTP") {
                                    Task {
                                        await viewModel.verifyOTP(username: username, otp: otpInput)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(otpInput.isEmpty)
                            } else {
                                Button("Sign In") {
                                    Task {
                                        await viewModel.authenticateWithSecureEnclave(username: username)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(username.isEmpty)
                                .padding(.horizontal)

                                Button("Use SMS OTP Instead") {
                                    Task {
                                        await viewModel.authenticateWithOTP(username: username)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(username.isEmpty)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)

                        // Status Messages
                        VStack(spacing: 16) {
                            switch viewModel.status {
                            case .idle:
                                EmptyView()

                            case .requestingChallenge:
                                ProgressView("Requesting challenge...")

                            case .signing:
                                ProgressView("Signing challenge...")

                            case .verifying:
                                ProgressView("Verifying...")

                            case .requestingOTP:
                                ProgressView("Requesting OTP...")

                            case .verifyingOTP:
                                Text("📱 OTP sent! Check backend logs for the code")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .multilineTextAlignment(.center)
                                    .padding()

                            case .success(let token):
                                VStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.green)

                                    Text("Authentication Successful!")
                                        .font(.headline)

                                    Text("Token: \(token.prefix(20))...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Button("Sign In Again") {
                                        viewModel.reset()
                                        username = ""
                                        otpInput = ""
                                    }
                                    .buttonStyle(.bordered)
                                    .padding(.top)
                                }

                            case .failed(let error):
                                VStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.red)

                                    Text("Authentication Failed")
                                        .font(.headline)

                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)

                                    Button("Try Again") {
                                        viewModel.reset()
                                    }
                                    .buttonStyle(.bordered)
                                    .padding(.top)
                                }
                            }
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Authentication")
        }
    }
}

#Preview {
    AuthenticationView()
}
