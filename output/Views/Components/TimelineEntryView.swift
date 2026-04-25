import SwiftUI
import PersonalColorDesignSystem

// MARK: - TimelineEntryView

struct TimelineEntryView: View {
    let memory: SongMemory
    let onAddEntry: () -> Void

    private var listenedYear: Int {
        DateFormatters.year(from: memory.listenedAt)
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: PSpacing.sm) {
                // 년도 헤더
                HStack {
                    VStack(alignment: .leading, spacing: PSpacing.xxs) {
                        Text("timeline.year \(listenedYear)")
                            .font(Font.pTitle(18))
                            .foregroundStyle(Color.pTextPrimary)

                        if let location = memory.location, !location.isEmpty {
                            HStack(spacing: PSpacing.xxs) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(Font.pCaption(12))
                                    .foregroundStyle(Color.pAccentPrimary.opacity(0.7))
                                Text(location)
                                    .font(Font.pCaption(12))
                                    .foregroundStyle(Color.pTextSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(String(localized: "timeline.location_prefix"))\(location)")
                        }
                    }

                    Spacer()

                    Button(action: onAddEntry) {
                        Image(systemName: "plus.circle.fill")
                            .font(Font.pTitle(22))
                            .foregroundStyle(Color.pAccentPrimary)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel(Text("timeline.add_entry_aria"))
                }

                // 구분선
                PDivider()

                // 감정 태그
                if !memory.moodTags.isEmpty {
                    FlowLayout(spacing: PSpacing.xxs) {
                        ForEach(memory.moodTags, id: \.self) { tag in
                            PChip(tag)
                                .accessibilityLabel(tag)
                        }
                    }
                }

                // 텍스트 엔트리들
                if !memory.entries.isEmpty {
                    VStack(alignment: .leading, spacing: PSpacing.xs) {
                        ForEach(memory.entries) { entry in
                            entryRow(entry)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: Entry) -> some View {
        VStack(alignment: .leading, spacing: PSpacing.xxs) {
            Text(entry.text)
                .font(Font.pBody(14))
                .foregroundStyle(Color.pTextPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(formattedDate(entry.writtenAt))
                .font(Font.pCaption(11))
                .foregroundStyle(Color.pTextSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PSpacing.xs)
        .background(Color.pGlassFill)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXs))
    }

    private func formattedDate(_ date: Date) -> String {
        DateFormatters.mediumDateString(from: date)
    }
}
