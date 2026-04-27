import SwiftUI
import TopDesignSystem

// MARK: - MoodChipGridView

struct MoodChipGridView: View {
    @Binding var selectedTags: Set<String>
    @Environment(\.designPalette) private var palette

    /// 모든 카테고리의 태그를 평탄화한 전체 목록
    private var allTags: [String] {
        MoodCategory.allCases.flatMap { $0.tags }
    }

    var body: some View {
        ScrollView {
            FlowLayout(horizontalSpacing: DesignSpacing.xs, verticalSpacing: DesignSpacing.xs) {
                ForEach(allTags, id: \.self) { tag in
                    moodChip(tag: tag)
                }
            }
            .padding(.horizontal, DesignSpacing.lg)
            .padding(.vertical, DesignSpacing.md)
        }
    }

    @ViewBuilder
    private func moodChip(tag: String) -> some View {
        let isSelected = selectedTags.contains(tag)
        let isDisabled = !isSelected && selectedTags.count >= 3

        Button {
            if isDisabled {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else {
                toggleTag(tag)
            }
        } label: {
            Text(tag)
                .font(isSelected ? .ssCaption.weight(.medium) : .ssCaption)
                .foregroundStyle(isSelected ? palette.textPrimary : palette.textSecondary)
                .padding(.horizontal, DesignSpacing.sm)
                .padding(.vertical, DesignSpacing.xxs)
                .background(
                    Capsule()
                        .fill(isSelected ? palette.primaryAction.opacity(0.25) : palette.surface)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? palette.primaryAction : palette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.4 : 1.0)
        .contentShape(Capsule())
        .accessibilityLabel(tag)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isDisabled ? String(localized: "mood.max_selected_hint") : "")
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else if selectedTags.count < 3 {
            selectedTags.insert(tag)
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
