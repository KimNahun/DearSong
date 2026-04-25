import SwiftUI
import AuthenticationServices
import TopDesignSystem

// MARK: - SignInView

struct SignInView: View {
    @Environment(AuthViewModel.self) private var viewModel
    @Environment(\.designPalette) private var palette

    @State private var showErrorToast = false
    @State private var errorToastMessage = ""

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    // 앱 로고 영역
                    VStack(spacing: DesignSpacing.lg) {
                        Image(systemName: "music.note.list")
                            .font(.ssLargeTitle)
                            .foregroundStyle(palette.primaryAction)
                            .accessibilityLabel(Text("screen.signin.app_icon_label"))

                        VStack(spacing: DesignSpacing.xs) {
                            Text("screen.home.title")
                                .font(.ssTitle1)
                                .foregroundStyle(palette.textPrimary)

                            Text("screen.signin.tagline")
                                .font(.ssFootnote)
                                .foregroundStyle(palette.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: 60)

                    // Sign In 영역
                    VStack(spacing: DesignSpacing.md) {
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
                                    errorToastMessage = error.localizedDescription
                                    showErrorToast = true
                                }
                            }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(minHeight: 50, maxHeight: 56)
                        .clipShape(RoundedRectangle(cornerRadius: DesignCornerRadius.sm))
                        .accessibilityLabel(Text("action.signin_apple"))

                        Text("screen.signin.subtitle")
                            .font(.ssCaption)
                            .foregroundStyle(palette.textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, DesignSpacing.xl)
                    .padding(.bottom, DesignSpacing.xxxl)
                }
                .frame(minHeight: UIScreen.main.bounds.height - 32)
            }

            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView()
                        .tint(palette.primaryAction)
                        .scaleEffect(1.5)
                }
            }
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                errorToastMessage = message
                showErrorToast = true
            }
        }
        .bottomToast(isPresented: $showErrorToast, message: errorToastMessage, style: .error)
    }
}
