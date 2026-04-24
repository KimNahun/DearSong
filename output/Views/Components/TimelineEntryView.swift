import SwiftUI

// MARK: - TimelineEntryView

struct TimelineEntryView: View {
    let memory: SongMemory
    let onAddEntry: () -> Void

    private var yearString: String {
        DateFormatters.yearString(from: memory.listenedAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 년도 헤더
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(yearString)년")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    if let location = memory.location, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.accentSecondary)
                            Text(location)
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("장소: \(location)")
                    }
                }

                Spacer()

                Button(action: onAddEntry) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.accent)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("이 시기에 새 기록 추가")
            }

            // 구분선
            Rectangle()
                .fill(AppTheme.divider)
                .frame(height: 1)

            // 감정 태그
            if !memory.moodTags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(memory.moodTags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.accentSoft)
                            .clipShape(Capsule())
                            .accessibilityLabel("감정: \(tag)")
                    }
                }
            }

            // 텍스트 엔트리들
            if !memory.entries.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(memory.entries) { entry in
                        entryRow(entry)
                    }
                }
            }
        }
        .padding(18)
        .cardStyle()
    }

    @ViewBuilder
    private func entryRow(_ entry: Entry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.text)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(formattedDate(entry.writtenAt))
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.chipBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXs))
    }

    private func formattedDate(_ date: Date) -> String {
        DateFormatters.mediumDateString(from: date)
    }
}
