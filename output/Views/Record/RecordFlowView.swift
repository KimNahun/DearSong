import SwiftUI
import PersonalColorDesignSystem

// MARK: - RecordFlowView

struct RecordFlowView: View {
    @State private var viewModel: RecordFlowViewModel
    @Environment(PToastManager.self) private var toastManager
    let onDismiss: () -> Void

    init(preselectedSong: SearchedSong? = nil, onDismiss: @escaping () -> Void) {
        _viewModel = State(initialValue: RecordFlowViewModel(preselectedSong: preselectedSong))
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                // 네비게이션 바
                flowNavigationBar

                // 단계별 콘텐츠
                stepContent
            }
        }
        .onChange(of: viewModel.savedSuccessfully) { _, saved in
            if saved {
                toastManager.show("기록이 저장되었어요 🎵", type: .success)
                HapticManager.notification(.success)
                onDismiss()
            }
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                toastManager.show(message, type: .error)
            }
        }
    }

    // MARK: - Subviews

    private var flowNavigationBar: some View {
        HStack {
            if viewModel.currentStep != .songSearch {
                Button(action: { viewModel.goToPreviousStep() }) {
                    Image(systemName: "chevron.left")
                        .font(.pTitle(17))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("이전 단계")
            } else {
                Spacer().frame(width: 44)
            }

            Spacer()

            VStack(spacing: PSpacing.xs) {
                Text(stepTitle)
                    .font(.pTitle(17))
                    .foregroundStyle(.primary)

                HStack(spacing: PSpacing.xs) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == viewModel.currentStep.rawValue ? Color.pAccentPrimary : Color(.systemGray5))
                            .frame(width: 6, height: 6)
                    }
                }
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.pTitle(17))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("기록 작성 취소")
        }
        .padding(.horizontal, PSpacing.lg)
        .padding(.vertical, PSpacing.sm)
    }

    private var stepTitle: String {
        switch viewModel.currentStep {
        case .songSearch: return "곡 선택"
        case .moodSelection: return "감정 선택"
        case .entryWrite: return "기록 작성"
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .songSearch:
            SongSearchView(viewModel: viewModel)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        case .moodSelection:
            MoodSelectionView(viewModel: viewModel)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        case .entryWrite:
            EntryWriteView(viewModel: viewModel)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
    }
}
