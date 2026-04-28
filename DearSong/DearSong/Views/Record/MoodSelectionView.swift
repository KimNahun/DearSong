import SwiftUI
import TopDesignSystem

// MARK: - MoodSelectionView

struct MoodSelectionView: View {
    @Bindable var viewModel: RecordFlowViewModel
    @Environment(\.designPalette) private var palette

    var body: some View {
        MoodChipGridView(selectedTags: $viewModel.selectedMoodTags)
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
}
