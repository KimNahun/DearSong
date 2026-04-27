import SwiftUI
import TopDesignSystem

// MARK: - DearSongApp

@main
struct DearSongApp: App {
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            rootView
                .designTheme(.linear)
                .task {
                    await authViewModel.checkSession()
                }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if authViewModel.isLoading {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                ProgressView()
            }
            .ignoresSafeArea()
        } else if authViewModel.isAuthenticated {
            SongCollectionView(authViewModel: authViewModel)
                .dismissKeyboardOnTap()
        } else {
            SignInView()
                .environment(authViewModel)
                .dismissKeyboardOnTap()
        }
    }
}
