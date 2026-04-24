import SwiftUI
import AuthenticationServices
import PersonalColorDesignSystem

// MARK: - SignInView

struct SignInView: View {
    @Environment(AuthViewModel.self) private var viewModel
    @Environment(PToastManager.self) private var toastManager

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: PSpacing.xxxl) {
                Spacer()

                // 앱 로고 영역
                VStack(spacing: PSpacing.lg) {
                    Image(systemName: "music.note.list")
                        .font(.pDisplay(64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.pAccentPrimary, Color.pAccentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .accessibilityLabel("DearSong 앱 아이콘")

                    VStack(spacing: PSpacing.xs) {
                        Text("DearSong")
                            .font(.pDisplay(40))
                            .foregroundStyle(.primary)

                        Text("노래에 감정을 기록하는 음악 다이어리")
                            .font(.pBody(14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                // Sign In 영역
                VStack(spacing: PSpacing.lg) {
                    SignInWithAppleButton { request in
                        let preparedRequest = viewModel.prepareSignInRequest()
                        request.requestedScopes = preparedRequest.requestedScopes
                        request.nonce = preparedRequest.nonce
                    } onCompletion: { result in
                        Task {
                            switch result {
                            case .success(let authorization):
                                await viewModel.signInWithApple(authorization: authorization)
                            case .failure(let error):
                                toastManager.show(error.localizedDescription, type: .error)
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(PRadius.md)
                    .accessibilityLabel("Apple로 로그인")

                    Text("Apple ID로 안전하게 로그인하세요")
                        .font(.pCaption(12))
                        .foregroundStyle(Color(.tertiaryLabel))
                }
                .padding(.horizontal, PSpacing.xl)
                .padding(.bottom, PSpacing.huge)
            }

            if viewModel.isLoading {
                PLoadingOverlay()
            }
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                toastManager.show(message, type: .error)
            }
        }
    }
}
