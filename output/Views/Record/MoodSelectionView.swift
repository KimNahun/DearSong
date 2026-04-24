import SwiftUI
import PersonalColorDesignSystem

// MARK: - MoodSelectionView

struct MoodSelectionView: View {
    var viewModel: RecordFlowViewModel

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
                .foregroundStyle(Color.pTextSecondary)
                .padding(.vertical, PSpacing.sm(8))
                .padding(.horizontal, PSpacing.lg(16))

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
                .padding(.horizontal, PSpacing.lg(16))
                .padding(.bottom, PSpacing.xs(4))
            }

            PDivider()
                .padding(.horizontal, PSpacing.lg(16))

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
        HStack(spacing: PSpacing.sm(8)) {
            AlbumArtworkView(urlString: song.artworkURL?.absoluteString, size: 40, cornerRadius: PRadius.xs(4))

            VStack(alignment: .leading, spacing: PSpacing.xs(2)) {
                Text(song.title)
                    .font(.pBodyMedium(14))
                    .foregroundStyle(Color.pTextPrimary)
                    .lineLimit(1)
                Text(song.artistName)
                    .font(.pCaption(12))
                    .foregroundStyle(Color.pTextSecondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, PSpacing.lg(16))
        .padding(.vertical, PSpacing.sm(8))
        .background(Color.pGlassFill)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("선택된 곡: \(song.title), \(song.artistName)")
    }

    private var manualSongBanner: some View {
        HStack(spacing: PSpacing.sm(8)) {
            Image(systemName: "music.note")
                .font(.pTitle(17))
                .foregroundStyle(Color.pAccentSecondary)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: PSpacing.xs(2)) {
                Text(viewModel.manualSongTitle)
                    .font(.pBodyMedium(14))
                    .foregroundStyle(Color.pTextPrimary)
                    .lineLimit(1)
                Text(viewModel.manualArtistName)
                    .font(.pCaption(12))
                    .foregroundStyle(Color.pTextSecondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, PSpacing.lg(16))
        .padding(.vertical, PSpacing.sm(8))
        .background(Color.pGlassFill)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("선택된 곡: \(viewModel.manualSongTitle), \(viewModel.manualArtistName)")
    }
}
