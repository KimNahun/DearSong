import SwiftUI
import AuthenticationServices
import PersonalColorDesignSystem

// MARK: - SignInView

struct SignInView: View {
    @Environment(AuthViewModel.self) private var viewModel
    @Environment(PToastManager.self) private var toastManager

    var body: some View {
        ZStack {
            PGradientBackground()

            VStack(spacing: PSpacing.xxxl(32)) {
                Spacer()

                // 앱 로고 영역
                VStack(spacing: PSpacing.lg(16)) {
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

                    VStack(spacing: PSpacing.xs(4)) {
                        Text("DearSong")
                            .font(.pDisplay(40))
                            .foregroundStyle(Color.pTextPrimary)

                        Text("노래에 감정을 기록하는 음악 다이어리")
                            .font(.pBody(14))
                            .foregroundStyle(Color.pTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                // Sign In 영역
                VStack(spacing: PSpacing.lg(16)) {
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
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(PRadius.md(12))
                    .accessibilityLabel("Apple로 로그인")

                    Text("Apple ID로 안전하게 로그인하세요")
                        .font(.pCaption(12))
                        .foregroundStyle(Color.pTextTertiary)
                }
                .padding(.horizontal, PSpacing.xl(20))
                .padding(.bottom, PSpacing.huge(48))
            }

            if viewModel.isLoading {
                PLoadingOverlay(isLoading: true)
            }
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                toastManager.show(message, type: .error)
            }
        }
    }
}
