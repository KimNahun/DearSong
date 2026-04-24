import SwiftUI
import PersonalColorDesignSystem

// MARK: - MoodChipGridView

struct MoodChipGridView: View {
    @Binding var selectedTags: Set<String>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(MoodCategory.allCases, id: \.rawValue) { category in
                    categorySection(category)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    @ViewBuilder
    private func categorySection(_ category: MoodCategory) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(category.displayName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)

            FlowLayout(spacing: 8) {
                ForEach(category.tags, id: \.self) { tag in
                    let isSelected = selectedTags.contains(tag)
                    MoodChipButton(title: tag, isSelected: isSelected) {
                        toggleTag(tag)
                    }
                    .accessibilityLabel("\(tag) 감정 태그")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
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
