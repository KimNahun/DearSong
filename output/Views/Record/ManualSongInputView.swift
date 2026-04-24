import SwiftUI
import PersonalColorDesignSystem

// MARK: - ManualSongInputView

struct ManualSongInputView: View {
    var viewModel: RecordFlowViewModel

    var body: some View {
        VStack(spacing: PSpacing.xl(20)) {
            // 안내 배너
            PBanner(type: .info, message: "Apple Music 권한 없이 곡을 직접 입력합니다.")
                .padding(.horizontal, PSpacing.lg(16))
                .padding(.top, PSpacing.md(12))

            VStack(spacing: PSpacing.lg(16)) {
                PFormField(label: "곡 제목", state: titleFieldState) {
                    PTextField(placeholder: "예: 봄날", text: $viewModel.manualSongTitle)
                        .accessibilityLabel("곡 제목 입력")
                }

                PFormField(label: "아티스트", state: artistFieldState) {
                    PTextField(placeholder: "예: BTS", text: $viewModel.manualArtistName)
                        .accessibilityLabel("아티스트명 입력")
                }
            }
            .padding(.horizontal, PSpacing.lg(16))

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

    private var titleFieldState: PFormFieldState {
        if viewModel.manualSongTitle.isEmpty {
            return .normal
        }
        return viewModel.manualSongTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? .error("곡 제목을 입력해주세요")
            : .normal
    }

    private var artistFieldState: PFormFieldState {
        if viewModel.manualArtistName.isEmpty {
            return .normal
        }
        return viewModel.manualArtistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? .error("아티스트명을 입력해주세요")
            : .normal
    }
}
