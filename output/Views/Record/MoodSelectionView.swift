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
            Text("이 곡을 들었을 때의 감정을 선택하세요")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)

            // 선택된 태그 수 표시
            if !viewModel.selectedMoodTags.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.accent)
                    Text("\(viewModel.selectedMoodTags.count)개 선택됨")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            Divider()
                .foregroundStyle(AppTheme.divider)
                .padding(.horizontal, 20)

            // 감정 태그 그리드 (FlowLayout)
            MoodChipGridView(selectedTags: $viewModel.selectedMoodTags)
        }
        .bottomButtons {
            BottomPlacedButton(title: "다음") {
                viewModel.goToNextStep()
                HapticManager.selection()
            }
            .disabled(!viewModel.canProceedFromMoodSelection)
            .opacity(viewModel.canProceedFromMoodSelection ? 1 : 0.5)
            .accessibilityLabel("다음 단계로 이동")
        }
    }

    private func selectedSongBanner(_ song: SearchedSong) -> some View {
        HStack(spacing: 12) {
            AlbumArtworkView(urlString: song.artworkURL?.absoluteString, size: 44, cornerRadius: AppTheme.cornerRadiusXs)

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(song.artistName)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppTheme.cardBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("선택된 곡: \(song.title), \(song.artistName)")
    }

    private var manualSongBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.accentSecondary)
                .frame(width: 44, height: 44)
                .background(AppTheme.chipBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXs))

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.manualSongTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(viewModel.manualArtistName)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppTheme.cardBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("선택된 곡: \(viewModel.manualSongTitle), \(viewModel.manualArtistName)")
    }
}
