import SwiftUI
import PersonalColorDesignSystem

// MARK: - MoodChipGridView

struct MoodChipGridView: View {
    @Binding var selectedTags: Set<String>

    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: PSpacing.sm(8))
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PSpacing.lg(16)) {
                ForEach(MoodCategory.allCases, id: \.rawValue) { category in
                    categorySection(category)
                }
            }
            .padding(.horizontal, PSpacing.lg(16))
            .padding(.vertical, PSpacing.md(12))
        }
    }

    @ViewBuilder
    private func categorySection(_ category: MoodCategory) -> some View {
        VStack(alignment: .leading, spacing: PSpacing.sm(8)) {
            PSectionHeader(title: category.displayName)

            LazyVGrid(columns: columns, spacing: PSpacing.sm(8)) {
                ForEach(category.tags, id: \.self) { tag in
                    let isSelected = selectedTags.contains(tag)
                    PChip(
                        title: tag,
                        variant: .toggle,
                        isSelected: Binding(
                            get: { isSelected },
                            set: { _ in toggleTag(tag) }
                        )
                    )
                    .accessibilityLabel("\(tag) 감정 태그")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .animation(PAnimation.springFast, value: isSelected)
                }
            }
        }
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        HapticManager.selection()
    }
}
