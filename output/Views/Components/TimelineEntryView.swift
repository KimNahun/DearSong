import SwiftUI
import PersonalColorDesignSystem

// MARK: - TimelineEntryView

struct TimelineEntryView: View {
    let memory: SongMemory
    let onAddEntry: () -> Void

    private var yearString: String {
        DateFormatters.yearString(from: memory.listenedAt)
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: PSpacing.md(12)) {
                // 년도 헤더
                HStack {
                    VStack(alignment: .leading, spacing: PSpacing.xs(4)) {
                        Text(yearString)
                            .font(.pTitle(17))
                            .foregroundStyle(Color.pTextPrimary)
                            .accessibilityLabel("\(yearString)년")

                        if let location = memory.location, !location.isEmpty {
                            HStack(spacing: PSpacing.xs(4)) {
                                Image(systemName: "mappin.circle")
                                    .font(.pCaption(12))
                                    .foregroundStyle(Color.pAccentSecondary)
                                Text(location)
                                    .font(.pCaption(12))
                                    .foregroundStyle(Color.pTextSecondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("장소: \(location)")
                        }
                    }

                    Spacer()

                    Button(action: onAddEntry) {
                        Image(systemName: "plus.circle")
                            .font(.pTitle(17))
                            .foregroundStyle(Color.pAccentPrimary)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("이 시기에 새 기록 추가")
                }

                PDivider()

                // 감정 태그
                if !memory.moodTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: PSpacing.xs(4)) {
                            ForEach(memory.moodTags, id: \.self) { tag in
                                PChip(title: tag, variant: .label, isSelected: .constant(false))
                                    .accessibilityLabel("감정: \(tag)")
                            }
                        }
                        .padding(.horizontal, PSpacing.xs(4))
                    }
                }

                // 텍스트 엔트리들
                if !memory.entries.isEmpty {
                    VStack(alignment: .leading, spacing: PSpacing.sm(8)) {
                        ForEach(memory.entries) { entry in
                            entryRow(entry)
                        }
                    }
                }
            }
            .padding(PSpacing.lg(16))
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: Entry) -> some View {
        VStack(alignment: .leading, spacing: PSpacing.xs(4)) {
            Text(entry.text)
                .font(.pBody(14))
                .foregroundStyle(Color.pTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("기록: \(entry.text)")

            Text(formattedDate(entry.writtenAt))
                .font(.pCaption(11))
                .foregroundStyle(Color.pTextTertiary)
                .accessibilityLabel("작성일: \(formattedDate(entry.writtenAt))")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PSpacing.sm(8))
        .background(Color.pGlassFill)
        .clipShape(RoundedRectangle(cornerRadius: PRadius.sm(8)))
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}
