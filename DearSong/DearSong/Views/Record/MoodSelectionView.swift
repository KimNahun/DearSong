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
                .font(.pBody(14))
                .foregroundStyle(.secondary)
                .padding(.vertical, PSpacing.sm)
                .padding(.horizontal, PSpacing.lg)

            // 선택된 태그 수 표시
            if !viewModel.selectedMoodTags.isEmpty {
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.pCaption(12))
                        .foregroundStyle(Color.pAccentPrimary)
                    Text("\(viewModel.selectedMoodTags.count)개 선택됨")
                        .font(.pCaption(12))
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
        HStack(spacing: PSpacing.sm) {
            AlbumArtworkView(urlString: song.artworkURL?.absoluteString, size: 40, cornerRadius: PRadius.xs)

            VStack(alignment: .leading, spacing: PSpacing.xxs) {
                Text(song.title)
                    .font(.pBodyMedium(14))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(song.artistName)
                    .font(.pCaption(12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, PSpacing.lg)
        .padding(.vertical, PSpacing.sm)
        .background(Color(.secondarySystemGroupedBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("선택된 곡: \(song.title), \(song.artistName)")
    }

    private var manualSongBanner: some View {
        HStack(spacing: PSpacing.sm) {
            Image(systemName: "music.note")
                .font(.pTitle(17))
                .foregroundStyle(Color.pAccentSecondary)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: PSpacing.xxs) {
                Text(viewModel.manualSongTitle)
                    .font(.pBodyMedium(14))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(viewModel.manualArtistName)
                    .font(.pCaption(12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, PSpacing.lg)
        .padding(.vertical, PSpacing.sm)
        .background(Color(.secondarySystemGroupedBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("선택된 곡: \(viewModel.manualSongTitle), \(viewModel.manualArtistName)")
    }
}
