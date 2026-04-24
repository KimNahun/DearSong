import SwiftUI
import PersonalColorDesignSystem

// MARK: - DearSongApp

@main
struct DearSongApp: App {
    @State private var authViewModel = AuthViewModel()
    @State private var toastManager = PToastManager()

    var body: some Scene {
        WindowGroup {
            rootView
                .pTheme(.autumn)
                .environment(toastManager)
                .pGlobalToast(toastManager)
                .task {
                    await authViewModel.checkSession()
                }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if authViewModel.isLoading {
            ZStack {
                PGradientBackground()
                PLoadingOverlay(isLoading: true)
            }
            .ignoresSafeArea()
        } else if authViewModel.isAuthenticated {
            SongCollectionView(authViewModel: authViewModel)
        } else {
            SignInView()
                .environment(authViewModel)
                .environment(toastManager)
        }
    }
}
