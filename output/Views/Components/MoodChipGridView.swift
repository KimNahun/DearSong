import SwiftUI
import PersonalColorDesignSystem

// MARK: - MoodChipGridView

struct MoodChipGridView: View {
    @Binding var selectedTags: Set<String>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PSpacing.lg) {
                ForEach(MoodCategory.allCases, id: \.rawValue) { category in
                    categorySection(category)
                }
            }
            .padding(.horizontal, PSpacing.lg)
            .padding(.vertical, PSpacing.md)
        }
    }

    @ViewBuilder
    private func categorySection(_ category: MoodCategory) -> some View {
        VStack(alignment: .leading, spacing: PSpacing.xs) {
            PSectionHeader(category.displayName)

            FlowLayout(spacing: PSpacing.xs) {
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
                HapticManager.impact(.light)
            } else {
                toggleTag(tag)
            }
        } label: {
            Text(tag)
                .font(isSelected ? Font.pBodyMedium(14) : Font.pBody(14))
                .foregroundStyle(isSelected ? Color.pTextPrimary : Color.pTextSecondary)
                .padding(.horizontal, PSpacing.md)
                .padding(.vertical, PSpacing.xs)
                .frame(minHeight: 36)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.pAccentPrimary.opacity(0.25) : Color.pGlassFill)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.pAccentPrimary : Color.pGlassBorder, lineWidth: 1)
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
        HapticManager.selection()
    }
}
