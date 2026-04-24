import SwiftUI
import PersonalColorDesignSystem

// MARK: - ManualSongInputView

struct ManualSongInputView: View {
    @Bindable var viewModel: RecordFlowViewModel

    var body: some View {
        VStack(spacing: 24) {
            // 안내 배너
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(AppTheme.accentSecondary)
                Text("Apple Music 권한 없이 곡을 직접 입력합니다.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.accentSecondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXs))
            .padding(.horizontal, 20)
            .padding(.top, 16)

            VStack(spacing: 20) {
                // 곡 제목
                VStack(alignment: .leading, spacing: 8) {
                    Text("곡 제목")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    HStack(spacing: 10) {
                        Image(systemName: "music.note")
                            .foregroundStyle(AppTheme.textTertiary)
                        TextField("예: 봄날", text: $viewModel.manualSongTitle)
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .padding(14)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm)
                            .stroke(titleBorderColor, lineWidth: 1)
                    )
                    .accessibilityLabel("곡 제목 입력")
                }

                // 아티스트
                VStack(alignment: .leading, spacing: 8) {
                    Text("아티스트")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    HStack(spacing: 10) {
                        Image(systemName: "person")
                            .foregroundStyle(AppTheme.textTertiary)
                        TextField("예: BTS", text: $viewModel.manualArtistName)
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .padding(14)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm)
                            .stroke(artistBorderColor, lineWidth: 1)
                    )
                    .accessibilityLabel("아티스트명 입력")
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .bottomButtons {
            BottomPlacedButton(title: "다음") {
                viewModel.goToNextStep()
                HapticManager.selection()
            }
            .disabled(!viewModel.canProceedFromSongSearch)
            .opacity(viewModel.canProceedFromSongSearch ? 1 : 0.5)
            .accessibilityLabel("다음 단계로 이동")
        }
    }

    private var titleBorderColor: Color {
        if viewModel.manualSongTitle.isEmpty { return AppTheme.border }
        return viewModel.manualSongTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? Color.red.opacity(0.5) : AppTheme.border
    }

    private var artistBorderColor: Color {
        if viewModel.manualArtistName.isEmpty { return AppTheme.border }
        return viewModel.manualArtistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? Color.red.opacity(0.5) : AppTheme.border
    }
}
