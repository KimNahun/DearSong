import SwiftUI
import PersonalColorDesignSystem

// MARK: - ManualSongInputView

struct ManualSongInputView: View {
    @Bindable var viewModel: RecordFlowViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: PSpacing.lg) {
                // 안내 배너
                PBanner(type: .info, message: String(localized: "manualinput.banner"))
                    .padding(.horizontal, PSpacing.lg)
                    .padding(.top, PSpacing.md)

                VStack(spacing: PSpacing.lg) {
                    // 곡 제목
                    VStack(alignment: .leading, spacing: PSpacing.xs) {
                        Text("manualinput.song.label")
                            .font(Font.pBodyMedium(14))
                            .foregroundStyle(Color.pTextPrimary)

                        PTextField(
                            placeholder: String(localized: "placeholder.song.title"),
                            text: $viewModel.manualSongTitle,
                            leadingIcon: "music.note"
                        )
                        .accessibilityLabel(Text("manualinput.song.label"))
                    }

                    // 아티스트
                    VStack(alignment: .leading, spacing: PSpacing.xs) {
                        Text("manualinput.artist.label")
                            .font(Font.pBodyMedium(14))
                            .foregroundStyle(Color.pTextPrimary)

                        PTextField(
                            placeholder: String(localized: "placeholder.artist.name"),
                            text: $viewModel.manualArtistName,
                            leadingIcon: "person"
                        )
                        .accessibilityLabel(Text("manualinput.artist.label"))
                    }
                }
                .padding(.horizontal, PSpacing.lg)

                Spacer(minLength: PSpacing.xl)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            BottomPlacedButton(title: String(localized: "action.next")) {
                viewModel.goToNextStep()
                HapticManager.selection()
            }
            .disabled(!viewModel.canProceedFromSongSearch)
            .opacity(viewModel.canProceedFromSongSearch ? 1 : 0.5)
            .accessibilityLabel(Text("action.next"))
        }
    }
}
