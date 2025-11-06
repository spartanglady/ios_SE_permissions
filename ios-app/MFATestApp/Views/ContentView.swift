import SwiftUI

struct ContentView: View {
    @StateObject private var storage = MFAStorageService()

    var body: some View {
        TabView {
            EnrollmentView()
                .tabItem {
                    Label("Enrollment", systemImage: "person.badge.plus")
                }

            AuthenticationView()
                .tabItem {
                    Label("Sign In", systemImage: "key")
                }

            TestingDashboardView()
                .tabItem {
                    Label("Testing", systemImage: "checklist")
                }
        }
    }
}

#Preview {
    ContentView()
}
