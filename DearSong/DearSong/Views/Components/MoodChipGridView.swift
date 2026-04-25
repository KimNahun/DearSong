import SwiftUI
import TopDesignSystem

// MARK: - MoodChipGridView

struct MoodChipGridView: View {
    @Binding var selectedTags: Set<String>
    @Environment(\.designPalette) private var palette

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSpacing.lg) {
                ForEach(MoodCategory.allCases, id: \.rawValue) { category in
                    categorySection(category)
                }
            }
            .padding(.horizontal, DesignSpacing.lg)
            .padding(.vertical, DesignSpacing.md)
        }
    }

    @ViewBuilder
    private func categorySection(_ category: MoodCategory) -> some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xs) {
            // PSectionHeader 대체: 인라인 Text
            Text(category.displayName)
                .font(.ssTitle2)
                .foregroundStyle(palette.textPrimary)

            // FlowLayout 대체: LazyVGrid adaptive
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: DesignSpacing.xs)], spacing: DesignSpacing.xs) {
                ForEach(category.tags, id: \.self) { tag in
                    moodChip(tag: tag)
                }
            }
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
                .font(isSelected ? .ssFootnote.weight(.medium) : .ssFootnote)
                .foregroundStyle(isSelected ? palette.textPrimary : palette.textSecondary)
                .padding(.horizontal, DesignSpacing.md)
                .padding(.vertical, DesignSpacing.xs)
                .frame(minHeight: 36)
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
