import SwiftUI
import TopDesignSystem

// MARK: - TimelineEntryView

struct TimelineEntryView: View {
    let memory: SongMemory
    let onAddEntry: () -> Void
    @Environment(\.designPalette) private var palette

    private var listenedYear: Int {
        DateFormatters.year(from: memory.listenedAt)
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                // 년도 헤더
                HStack {
                    VStack(alignment: .leading, spacing: DesignSpacing.xxs) {
                        Text(verbatim: DateFormatters.yearDisplayString(listenedYear))
                            .font(.ssTitle2)
                            .foregroundStyle(palette.textPrimary)

                        if let location = memory.location, !location.isEmpty {
                            HStack(spacing: DesignSpacing.xxs) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.ssCaption)
                                    .foregroundStyle(palette.primaryAction.opacity(0.7))
                                Text(location)
                                    .font(.ssCaption)
                                    .foregroundStyle(palette.textSecondary)
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
                            .font(.ssTitle2)
                            .foregroundStyle(palette.primaryAction)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel(Text("timeline.add_entry_aria"))
                }

                // 구분선 (PDivider 대체)
                Divider()
                    .overlay(palette.border)

                // 감정 태그 — 최대 3개 제한이라 단일 행 HStack으로 충분
                if !memory.moodTags.isEmpty {
                    HStack(spacing: DesignSpacing.xs) {
                        ForEach(memory.moodTags, id: \.self) { tag in
                            Text(tag)
                                .font(.ssCaption)
                                .foregroundStyle(palette.textSecondary)
                                .lineLimit(1)
                                .padding(.horizontal, DesignSpacing.sm)
                                .padding(.vertical, DesignSpacing.xxs)
                                .background(Capsule().fill(palette.surface))
                                .accessibilityLabel(tag)
                        }
                        Spacer(minLength: 0)
                    }
                }

                // 텍스트 엔트리들
                if !memory.entries.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSpacing.xs) {
                        ForEach(memory.entries) { entry in
                            entryRow(entry)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: Entry) -> some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xxs) {
            Text(entry.text)
                .font(.ssFootnote)
                .foregroundStyle(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(formattedDate(entry.writtenAt))
                .font(.ssCaption)
                .foregroundStyle(palette.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSpacing.xs)
        .background(palette.surface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: DesignCornerRadius.sm))
    }

    private func formattedDate(_ date: Date) -> String {
        DateFormatters.mediumDateString(from: date)
    }
}
