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

            VStack(spacing: 0) {
                Spacer()

                // 앱 로고 영역
                VStack(spacing: 20) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 64))
                        .foregroundStyle(AppTheme.accent)
                        .accessibilityLabel("DearSong 앱 아이콘")

                    VStack(spacing: 8) {
                        Text("DearSong")
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("노래에 감정을 기록하는 음악 다이어리")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                // Sign In 영역
                VStack(spacing: 16) {
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
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm))
                    .accessibilityLabel("Apple로 로그인")

                    Text("Apple ID로 안전하게 로그인하세요")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
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
