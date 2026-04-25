import SwiftUI
import TopDesignSystem

// MARK: - ManualSongInputView

struct ManualSongInputView: View {
    @Bindable var viewModel: RecordFlowViewModel
    @Environment(\.designPalette) private var palette

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSpacing.lg) {
                // 안내 배너 — PBanner(type: .info) 대체: 인라인 HStack 배너
                HStack(spacing: DesignSpacing.xs) {
                    Image(systemName: "info.circle.fill")
                        .font(.ssBody)
                        .foregroundStyle(palette.primaryAction)
                    Text(String(localized: "manualinput.banner"))
                        .font(.ssFootnote)
                        .foregroundStyle(palette.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(DesignSpacing.sm)
                .background(palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignCornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignCornerRadius.md)
                        .strokeBorder(palette.border, lineWidth: 1)
                )
                .padding(.horizontal, DesignSpacing.lg)
                .padding(.top, DesignSpacing.md)

                VStack(spacing: DesignSpacing.lg) {
                    // 곡 제목
                    VStack(alignment: .leading, spacing: DesignSpacing.xs) {
                        Text("manualinput.song.label")
                            .font(.ssFootnote.weight(.medium))
                            .foregroundStyle(palette.textPrimary)

                        // PTextField 대체: HStack + TextField + borderedContainer
                        HStack(spacing: DesignSpacing.xs) {
                            Image(systemName: "music.note")
                                .font(.ssBody)
                                .foregroundStyle(palette.textSecondary)
                            TextField(String(localized: "placeholder.song.title"), text: $viewModel.manualSongTitle)
                                .font(.ssBody)
                                .foregroundStyle(palette.textPrimary)
                                .autocorrectionDisabled()
                        }
                        .borderedContainer(padding: DesignSpacing.sm)
                        .accessibilityLabel(Text("manualinput.song.label"))
                    }

                    // 아티스트
                    VStack(alignment: .leading, spacing: DesignSpacing.xs) {
                        Text("manualinput.artist.label")
                            .font(.ssFootnote.weight(.medium))
                            .foregroundStyle(palette.textPrimary)

                        // PTextField 대체: HStack + TextField + borderedContainer
                        HStack(spacing: DesignSpacing.xs) {
                            Image(systemName: "person")
                                .font(.ssBody)
                                .foregroundStyle(palette.textSecondary)
                            TextField(String(localized: "placeholder.artist.name"), text: $viewModel.manualArtistName)
                                .font(.ssBody)
                                .foregroundStyle(palette.textPrimary)
                                .autocorrectionDisabled()
                        }
                        .borderedContainer(padding: DesignSpacing.sm)
                        .accessibilityLabel(Text("manualinput.artist.label"))
                    }
                }
                .padding(.horizontal, DesignSpacing.lg)

                Spacer(minLength: DesignSpacing.xl)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            RoundedActionButton(String(localized: "action.next")) {
                viewModel.goToNextStep()
                UISelectionFeedbackGenerator().selectionChanged()
            }
            .disabled(!viewModel.canProceedFromSongSearch)
            .opacity(viewModel.canProceedFromSongSearch ? 1 : 0.5)
            .padding(.horizontal, DesignSpacing.lg)
            .padding(.vertical, DesignSpacing.sm)
            .background(palette.background)
            .accessibilityLabel(Text("action.next"))
        }
    }
}
