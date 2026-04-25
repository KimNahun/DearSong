import SwiftUI
import TopDesignSystem

// MARK: - MoodSelectionView

struct MoodSelectionView: View {
    @Bindable var viewModel: RecordFlowViewModel
    @Environment(\.designPalette) private var palette

    var body: some View {
        VStack(spacing: 0) {
            // 선택된 곡 정보
            if let song = viewModel.selectedSong {
                selectedSongBanner(song)
            } else if viewModel.isManualInput && !viewModel.manualSongTitle.isEmpty {
                manualSongBanner
            }

            // 안내 텍스트
            Text("screen.mood.guide")
                .font(.ssFootnote)
                .foregroundStyle(palette.textSecondary)
                .padding(.vertical, DesignSpacing.xs)
                .padding(.horizontal, DesignSpacing.lg)
                .fixedSize(horizontal: false, vertical: true)

            // 선택된 태그 수 표시
            if !viewModel.selectedMoodTags.isEmpty {
                HStack(spacing: DesignSpacing.xxs) {
                    Image(systemName: "tag.fill")
                        .font(.ssCaption)
                        .foregroundStyle(palette.primaryAction)
                    Text("mood.selected.count \(viewModel.selectedMoodTags.count)")
                        .font(.ssCaption)
                        .foregroundStyle(palette.primaryAction)
                    Spacer()
                }
                .padding(.horizontal, DesignSpacing.lg)
                .padding(.bottom, DesignSpacing.xs)
            }

            // 구분선 (PDivider 대체)
            Divider()
                .overlay(palette.border)
                .padding(.horizontal, DesignSpacing.lg)

            // 감정 태그 그리드
            MoodChipGridView(selectedTags: $viewModel.selectedMoodTags)
        }
        .safeAreaInset(edge: .bottom) {
            RoundedActionButton(String(localized: "action.next")) {
                viewModel.goToNextStep()
                UISelectionFeedbackGenerator().selectionChanged()
            }
            .disabled(!viewModel.canProceedFromMoodSelection)
            .opacity(viewModel.canProceedFromMoodSelection ? 1 : 0.5)
            .padding(.horizontal, DesignSpacing.lg)
            .padding(.vertical, DesignSpacing.sm)
            .background(palette.background)
            .accessibilityLabel(Text("action.next"))
        }
    }

    private func selectedSongBanner(_ song: SearchedSong) -> some View {
        GlassCard {
            HStack(spacing: DesignSpacing.xs) {
                AlbumArtworkView(urlString: song.artworkURL?.absoluteString, size: 44, cornerRadius: DesignCornerRadius.sm)

                VStack(alignment: .leading, spacing: DesignSpacing.xxs) {
                    Text(song.title)
                        .font(.ssFootnote.weight(.medium))
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(song.artistName)
                        .font(.ssFootnote)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()
            }
        }
        .padding(.horizontal, DesignSpacing.lg)
        .padding(.vertical, DesignSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(String(localized: "action.selected")): \(song.title), \(song.artistName)")
    }

    private var manualSongBanner: some View {
        GlassCard {
            HStack(spacing: DesignSpacing.xs) {
                Image(systemName: "music.note")
                    .font(.ssTitle2)
                    .foregroundStyle(palette.primaryAction.opacity(0.7))
                    .frame(width: 44, height: 44)
                    .background(palette.surface.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: DesignCornerRadius.sm))

                VStack(alignment: .leading, spacing: DesignSpacing.xxs) {
                    Text(viewModel.manualSongTitle)
                        .font(.ssFootnote.weight(.medium))
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(viewModel.manualArtistName)
                        .font(.ssFootnote)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()
            }
        }
        .padding(.horizontal, DesignSpacing.lg)
        .padding(.vertical, DesignSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(String(localized: "action.selected")): \(viewModel.manualSongTitle), \(viewModel.manualArtistName)")
    }
}
