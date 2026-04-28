import SwiftUI
import TopDesignSystem

// MARK: - SettingsView

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.designPalette) private var palette
    @Environment(\.dismiss) private var dismiss

    private let authViewModel: AuthViewModel
    @State private var showSignOutConfirm: Bool = false
    @State private var showErrorToast: Bool = false
    @State private var errorToastMessage: String = ""

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSpacing.lg) {
                    accountSection
                    appSection
                    signOutSection
                }
                .padding(.horizontal, DesignSpacing.lg)
                .padding(.vertical, DesignSpacing.md)
                .padding(.bottom, DesignSpacing.xxl)
            }

            if authViewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView()
                        .tint(palette.primaryAction)
                        .scaleEffect(1.5)
                }
                .accessibilityHidden(true)
            }
        }
        .navigationTitle(Text("screen.settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadAccountInfo()
        }
        .confirmationDialog(
            Text("settings.signout.confirm_title"),
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                Task {
                    await authViewModel.signOut()
                    if authViewModel.errorMessage == nil {
                        dismiss()
                    }
                }
            } label: {
                Text("action.signout")
            }
            Button(role: .cancel) { } label: {
                Text("action.cancel")
            }
        } message: {
            Text("settings.signout.confirm_message")
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                errorToastMessage = message
                showErrorToast = true
            }
        }
        .onChange(of: authViewModel.errorMessage) { _, message in
            if let message {
                errorToastMessage = message
                showErrorToast = true
            }
        }
        .bottomToast(isPresented: $showErrorToast, message: errorToastMessage, style: .error)
    }

    // MARK: - Sections

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xs) {
            sectionHeader(Text("settings.section.account"))

            GlassCard {
                VStack(spacing: 0) {
                    settingsRow(
                        icon: "envelope",
                        labelKey: "settings.account.email",
                        value: viewModel.userEmail ?? String(localized: "settings.value.unknown")
                    )

                    Divider()
                        .background(palette.textSecondary.opacity(0.15))
                        .padding(.horizontal, DesignSpacing.md)

                    settingsRow(
                        icon: "person.crop.circle",
                        labelKey: "settings.account.user_id",
                        value: shortenedUserId(viewModel.userId)
                    )
                }
                .padding(.vertical, DesignSpacing.xs)
            }
        }
    }

    private var appSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xs) {
            sectionHeader(Text("settings.section.app"))

            GlassCard {
                VStack(spacing: 0) {
                    settingsRow(
                        icon: "info.circle",
                        labelKey: "settings.app.version",
                        value: viewModel.appVersion
                    )

                    Divider()
                        .background(palette.textSecondary.opacity(0.15))
                        .padding(.horizontal, DesignSpacing.md)

                    settingsRow(
                        icon: "hammer",
                        labelKey: "settings.app.build",
                        value: viewModel.buildNumber
                    )
                }
                .padding(.vertical, DesignSpacing.xs)
            }
        }
    }

    private var signOutSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xs) {
            sectionHeader(Text("settings.section.account_actions"))

            Button {
                showSignOutConfirm = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: DesignSpacing.sm) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.ssBody)
                        .foregroundStyle(.red)
                        .frame(width: 24, alignment: .center)

                    Text("action.signout")
                        .font(.ssBody.weight(.medium))
                        .foregroundStyle(.red)

                    Spacer(minLength: 0)
                }
                .padding(.vertical, DesignSpacing.md)
                .padding(.horizontal, DesignSpacing.md)
                .frame(minHeight: 44)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: DesignCornerRadius.md)
                        .fill(Color.red.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignCornerRadius.md)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.pressScale)
            .accessibilityLabel(Text("action.signout"))
            .accessibilityHint(Text("settings.signout.confirm_message"))
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: Text) -> some View {
        text
            .font(.ssCaption.weight(.semibold))
            .foregroundStyle(palette.textSecondary)
            .textCase(.uppercase)
            .padding(.leading, DesignSpacing.xs)
    }

    private func settingsRow(icon: String, labelKey: String.LocalizationValue, value: String) -> some View {
        HStack(spacing: DesignSpacing.sm) {
            Image(systemName: icon)
                .font(.ssFootnote)
                .foregroundStyle(palette.primaryAction.opacity(0.8))
                .frame(width: 24, alignment: .center)
                .accessibilityHidden(true)

            Text(String(localized: labelKey))
                .font(.ssFootnote)
                .foregroundStyle(palette.textPrimary)

            Spacer(minLength: DesignSpacing.sm)

            Text(value)
                .font(.ssFootnote)
                .foregroundStyle(palette.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, DesignSpacing.md)
        .padding(.vertical, DesignSpacing.sm)
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }

    private func shortenedUserId(_ id: String?) -> String {
        guard let id, !id.isEmpty else {
            return String(localized: "settings.value.unknown")
        }
        return String(id.prefix(8)) + "…"
    }
}
