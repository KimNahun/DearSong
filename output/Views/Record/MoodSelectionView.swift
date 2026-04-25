import SwiftUI
import PersonalColorDesignSystem

// MARK: - MoodSelectionView

struct MoodSelectionView: View {
    @Bindable var viewModel: RecordFlowViewModel

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
                .font(Font.pBody(14))
                .foregroundStyle(Color.pTextSecondary)
                .padding(.vertical, PSpacing.xs)
                .padding(.horizontal, PSpacing.lg)
                .fixedSize(horizontal: false, vertical: true)

            // 선택된 태그 수 표시
            if !viewModel.selectedMoodTags.isEmpty {
                HStack(spacing: PSpacing.xxs) {
                    Image(systemName: "tag.fill")
                        .font(Font.pCaption(12))
                        .foregroundStyle(Color.pAccentPrimary)
                    Text("mood.selected.count \(viewModel.selectedMoodTags.count)")
                        .font(Font.pCaption(12))
                        .foregroundStyle(Color.pAccentPrimary)
                    Spacer()
                }
                .padding(.horizontal, PSpacing.lg)
                .padding(.bottom, PSpacing.xs)
            }

            PDivider()
                .padding(.horizontal, PSpacing.lg)

            // 감정 태그 그리드
            MoodChipGridView(selectedTags: $viewModel.selectedMoodTags)
        }
        .safeAreaInset(edge: .bottom) {
            BottomPlacedButton(title: String(localized: "action.next")) {
                viewModel.goToNextStep()
                HapticManager.selection()
            }
            .disabled(!viewModel.canProceedFromMoodSelection)
            .opacity(viewModel.canProceedFromMoodSelection ? 1 : 0.5)
            .accessibilityLabel(Text("action.next"))
        }
    }

    private func selectedSongBanner(_ song: SearchedSong) -> some View {
        GlassCard {
            HStack(spacing: PSpacing.xs) {
                AlbumArtworkView(urlString: song.artworkURL?.absoluteString, size: 44, cornerRadius: AppTheme.cornerRadiusXs)

                VStack(alignment: .leading, spacing: PSpacing.xxs) {
                    Text(song.title)
                        .font(Font.pBodyMedium(15))
                        .foregroundStyle(Color.pTextPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(song.artistName)
                        .font(Font.pBody(13))
                        .foregroundStyle(Color.pTextSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()
            }
        }
        .padding(.horizontal, PSpacing.lg)
        .padding(.vertical, PSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(String(localized: "action.selected")): \(song.title), \(song.artistName)")
    }

    private var manualSongBanner: some View {
        GlassCard {
            HStack(spacing: PSpacing.xs) {
                Image(systemName: "music.note")
                    .font(Font.pTitle(20))
                    .foregroundStyle(Color.pAccentPrimary.opacity(0.7))
                    .frame(width: 44, height: 44)
                    .background(Color.pGlassFill)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXs))

                VStack(alignment: .leading, spacing: PSpacing.xxs) {
                    Text(viewModel.manualSongTitle)
                        .font(Font.pBodyMedium(15))
                        .foregroundStyle(Color.pTextPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(viewModel.manualArtistName)
                        .font(Font.pBody(13))
                        .foregroundStyle(Color.pTextSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()
            }
        }
        .padding(.horizontal, PSpacing.lg)
        .padding(.vertical, PSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(String(localized: "action.selected")): \(viewModel.manualSongTitle), \(viewModel.manualArtistName)")
    }
}
