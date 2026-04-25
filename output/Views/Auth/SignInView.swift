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
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    // 앱 로고 영역
                    VStack(spacing: PSpacing.lg) {
                        Image(systemName: "music.note.list")
                            .font(Font.pDisplay(56))
                            .foregroundStyle(Color.pAccentPrimary)
                            .accessibilityLabel(Text("screen.signin.app_icon_label"))

                        VStack(spacing: PSpacing.xs) {
                            Text("screen.home.title")
                                .font(Font.pDisplay(36))
                                .foregroundStyle(Color.pTextPrimary)

                            Text("screen.signin.tagline")
                                .font(Font.pBody(14))
                                .foregroundStyle(Color.pTextSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: 60)

                    // Sign In 영역
                    VStack(spacing: PSpacing.md) {
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
                        .frame(minHeight: 50, maxHeight: 56)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm))
                        .accessibilityLabel(Text("action.signin_apple"))

                        Text("screen.signin.subtitle")
                            .font(Font.pCaption(12))
                            .foregroundStyle(Color.pTextSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, PSpacing.xl)
                    .padding(.bottom, PSpacing.huge)
                }
                .frame(minHeight: UIScreen.main.bounds.height - 32)
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
