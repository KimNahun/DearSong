import SwiftUI
import TopDesignSystem

// MARK: - RecordFlowView

struct RecordFlowView: View {
    @State private var viewModel: RecordFlowViewModel
    @Environment(\.designPalette) private var palette
    @Environment(ToastManager.self) private var toastManager
    let onDismiss: () -> Void

    init(preselectedSong: SearchedSong? = nil, onDismiss: @escaping () -> Void) {
        _viewModel = State(initialValue: RecordFlowViewModel(preselectedSong: preselectedSong))
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 네비게이션 바
                flowNavigationBar

                // 단계별 콘텐츠
                stepContent
            }
        }
        .onChange(of: viewModel.savedSuccessfully) { _, saved in
            if saved {
                toastManager.show(String(localized: "toast.save.success"), style: .success)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onDismiss()
            }
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                toastManager.show(message, style: .error)
            }
        }
    }

    // MARK: - Subviews

    private var flowNavigationBar: some View {
        HStack {
            if viewModel.currentStep != .songSearch {
                Button(action: { viewModel.goToPreviousStep() }) {
                    Image(systemName: "chevron.left")
                        .font(.ssTitle2)
                        .foregroundStyle(palette.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("action.previous"))
            } else {
                Spacer().frame(width: 44)
            }

            Spacer()

            VStack(spacing: DesignSpacing.xxs) {
                Text(stepTitleKey)
                    .font(.ssBody.weight(.medium))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                // 단계 인디케이터
                HStack(spacing: DesignSpacing.xxs) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == viewModel.currentStep.rawValue
                                  ? palette.primaryAction
                                  : palette.border)
                            .frame(width: index == viewModel.currentStep.rawValue ? 20 : 6, height: 6)
                            .animation(SpringAnimation.gentle, value: viewModel.currentStep)
                    }
                }
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.ssBody)
                    .foregroundStyle(palette.textSecondary.opacity(0.7))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("action.cancel"))
        }
        .padding(.horizontal, DesignSpacing.md)
        .padding(.vertical, DesignSpacing.xs)
    }

    private var stepTitleKey: LocalizedStringKey {
        switch viewModel.currentStep {
        case .songSearch: return "screen.record.step.song"
        case .moodSelection: return "screen.record.step.mood"
        case .entryWrite: return "screen.record.step.write"
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
